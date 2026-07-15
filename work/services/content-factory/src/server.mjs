import http from 'node:http';
import { readFile } from 'node:fs/promises';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { generateWithVertex } from './vertex-client.mjs';

const credential = applicationDefault();
initializeApp({ credential });
const db = getFirestore();
const port = Number(process.env.PORT ?? 8080);
const projectId = process.env.GOOGLE_CLOUD_PROJECT ?? process.env.GCLOUD_PROJECT;
const model = process.env.VERTEX_MODEL ?? 'gemini-2.5-flash';
const semesterOne = JSON.parse(await readFile(new URL('../data/semester-1.json', import.meta.url), 'utf8'));
const jobId = 'semester-1-outline-hec-2024';

const outlineSchema = {
  type: 'OBJECT',
  properties: {
    courseId: { type: 'STRING' },
    courseTitle: { type: 'STRING' },
    units: { type: 'ARRAY', items: { type: 'OBJECT', properties: {
      title: { type: 'STRING' },
      alignedOutcomeIndexes: { type: 'ARRAY', items: { type: 'INTEGER' } },
      scope: { type: 'STRING' },
    }, required: ['title', 'alignedOutcomeIndexes', 'scope'] } },
    requiresInstitutionalSyllabusReview: { type: 'BOOLEAN' },
  },
  required: ['courseId', 'courseTitle', 'units', 'requiresInstitutionalSyllabusReview'],
};

function reply(res, status, body) {
  res.writeHead(status, { 'content-type': 'application/json' });
  res.end(JSON.stringify(body));
}

async function seedSemesterOne() {
  const ref = db.collection('contentJobs').doc(jobId);
  const existing = await ref.get();
  if (existing.exists) return { jobId, status: existing.data().status, existing: true };
  await ref.set({
    id: jobId,
    type: 'semester_outline_generation',
    semester: 1,
    curriculumVersion: semesterOne.curriculumVersion,
    source: semesterOne.source,
    courses: semesterOne.courses,
    nextCourseIndex: 0,
    status: 'queued',
    ownerReviewRequired: true,
    creditGuard: { semesterCapUsd: 110, stopAtGlobalPercent: 90, consumedUsd: 0 },
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  return { jobId, status: 'queued', existing: false };
}

function outlinePrompt(course) {
  const outcomes = course.outcomes.length
    ? course.outcomes.map((value, index) => `${index + 1}. ${value}`).join('\n')
    : 'No course-specific outcomes are supplied in the HEC document. Create only a provisional unit map and set requiresInstitutionalSyllabusReview to true.';
  return `Create an INTERNAL DRAFT course outline for NursePath Pakistan.\n` +
    `Course ID: ${course.id}\nCourse: ${course.title}\nCredits: ${course.credits}; theory ${course.theory}; clinical ${course.clinical}; lab ${course.lab}.\n` +
    `Authoritative source: HEC Curriculum of Nursing Education BSN/MSN 2024, pages ${semesterOne.source.pages.join(', ')}.\n` +
    `HEC learning outcomes:\n${outcomes}\n` +
    `Return JSON matching the schema. Create unit titles and scope statements only. Do not write lessons, clinical instructions, diagnoses, treatments, doses, calculations, or patient-care recommendations. ` +
    `Do not add outcomes. alignedOutcomeIndexes are 1-based. Set requiresInstitutionalSyllabusReview true when outcomes are absent.`;
}

function estimateUsd(usage = {}) {
  const input = usage.promptTokenCount ?? 0;
  const output = usage.candidatesTokenCount ?? 0;
  return Number(((input * 0.30 + output * 2.50) / 1_000_000).toFixed(6));
}

async function processOneCourse() {
  const ref = db.collection('contentJobs').doc(jobId);
  const claimed = await db.runTransaction(async transaction => {
    const snapshot = await transaction.get(ref);
    if (!snapshot.exists) return null;
    const job = snapshot.data();
    if (!['queued', 'running'].includes(job.status)) return null;
    const lease = job.leaseExpiresAt?.toDate?.();
    if (lease && lease > new Date()) return null;
    transaction.set(ref, { status: 'running', leaseExpiresAt: new Date(Date.now() + 4 * 60 * 1000), updatedAt: FieldValue.serverTimestamp() }, { merge: true });
    return job;
  });
  if (!claimed) return { status: 'idle' };
  const index = claimed.nextCourseIndex ?? 0;
  if (index >= semesterOne.courses.length) {
    await ref.set({ status: 'awaiting_owner_review', leaseExpiresAt: null, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
    return { jobId, status: 'awaiting_owner_review' };
  }
  const course = semesterOne.courses[index];
  const token = await credential.getAccessToken();
  const generated = await generateWithVertex({ projectId, accessToken: token.access_token, model, prompt: outlinePrompt(course), responseSchema: outlineSchema });
  const cost = estimateUsd(generated.usage);
  const consumed = Number(((claimed.creditGuard?.consumedUsd ?? 0) + cost).toFixed(6));
  if (consumed > 110) {
    await ref.set({ status: 'stopped', stoppedReason: 'semester_budget_cap', leaseExpiresAt: null }, { merge: true });
    return { jobId, status: 'stopped', reason: 'semester_budget_cap' };
  }
  await db.collection('contentDrafts').doc(`semester-1-outline-${course.id}`).set({
    semester: 1, courseId: course.id, contentType: 'course_outline', originalGeneratedText: generated.item,
    sourceIds: [semesterOne.source.id], model, promptVersion: 'semester-outline-v1', risk: course.id === 's1-fundamentals-1' ? 'patient_safety' : 'academic',
    reviewState: 'owner_review', revision: 1, usage: generated.usage, estimatedUsd: cost, createdAt: FieldValue.serverTimestamp(),
  });
  const nextIndex = index + 1;
  await ref.set({ nextCourseIndex: nextIndex, status: nextIndex >= semesterOne.courses.length ? 'awaiting_owner_review' : 'queued', creditGuard: { ...claimed.creditGuard, consumedUsd: consumed }, leaseExpiresAt: null, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
  return { jobId, status: nextIndex >= semesterOne.courses.length ? 'awaiting_owner_review' : 'queued', generatedCourse: course.id, nextCourseIndex: nextIndex, estimatedUsd: cost };
}

http.createServer(async (req, res) => {
  try {
    if (req.method === 'GET' && req.url === '/healthz') return reply(res, 200, { service: 'nursepath-content-worker', status: 'healthy', model });
    if (req.method === 'POST' && req.url === '/seed/semester-1') return reply(res, 200, await seedSemesterOne());
    if (req.method === 'POST' && req.url === '/run') return reply(res, 200, await processOneCourse());
    return reply(res, 404, { error: 'not_found' });
  } catch (error) {
    console.error(error);
    return reply(res, 500, { error: 'worker_failure', message: error.message });
  }
}).listen(port, () => console.log(`NursePath worker listening on ${port}`));
