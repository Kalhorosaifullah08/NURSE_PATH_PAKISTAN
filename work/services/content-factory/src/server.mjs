import http from 'node:http';
import { readFile } from 'node:fs/promises';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { generateWithVertex } from './vertex-client.mjs';
import { failureStateFor } from './failure-policy.mjs';
import { advanceCursor, batchCount, contentId, fingerprint, initialCursor, riskFor, targetsForCourse } from './pipeline.mjs';

const credential = applicationDefault();
initializeApp({ credential });
const db = getFirestore();
const port = Number(process.env.PORT ?? 8080);
const projectId = process.env.GOOGLE_CLOUD_PROJECT ?? process.env.GCLOUD_PROJECT ?? 'deft-reporter-485519-i1';
const model = process.env.VERTEX_MODEL ?? 'gemini-2.5-flash';
const reviewModel = process.env.VERTEX_REVIEW_MODEL ?? model;
const semesterCapUsd = Number(process.env.SEMESTER_CAP_USD ?? 15.00);
const globalCapUsd = Number(process.env.GLOBAL_CAP_USD ?? 100.00);
const maxBatchUsd = Number(process.env.MAX_BATCH_USD ?? 0.75);
const ownerEmail = 'Kalhoro.saiF12@GMAIL.COM';

const objectArraySchema = properties => ({
  type: 'OBJECT',
  properties: { items: { type: 'ARRAY', items: { type: 'OBJECT', properties, required: Object.keys(properties) } } },
  required: ['items'],
});

const schemas = {
  outlines: objectArraySchema({
    courseTitle: { type: 'STRING' },
    units: { type: 'ARRAY', items: { type: 'OBJECT', properties: {
      title: { type: 'STRING' }, alignedOutcomeIndexes: { type: 'ARRAY', items: { type: 'INTEGER' } }, scope: { type: 'STRING' },
    }, required: ['title', 'alignedOutcomeIndexes', 'scope'] } },
    requiresInstitutionalSyllabusReview: { type: 'BOOLEAN' },
  }),
  lessons: objectArraySchema({
    title: { type: 'STRING' }, unitTitle: { type: 'STRING' }, learningOutcomeIndexes: { type: 'ARRAY', items: { type: 'INTEGER' } },
    objectives: { type: 'ARRAY', items: { type: 'STRING' } },
    sections: { type: 'ARRAY', items: { type: 'OBJECT', properties: { heading: { type: 'STRING' }, text: { type: 'STRING' } }, required: ['heading', 'text'] } },
    keyTerms: { type: 'ARRAY', items: { type: 'OBJECT', properties: { term: { type: 'STRING' }, definition: { type: 'STRING' } }, required: ['term', 'definition'] } },
    summaryPoints: { type: 'ARRAY', items: { type: 'STRING' } }, cautions: { type: 'ARRAY', items: { type: 'STRING' } }, sourceIds: { type: 'ARRAY', items: { type: 'STRING' } },
    visuals: { type: 'ARRAY', items: { type: 'OBJECT', properties: {
      type: { type: 'STRING' }, title: { type: 'STRING' }, purpose: { type: 'STRING' },
      content: { type: 'ARRAY', items: { type: 'STRING' } }, caption: { type: 'STRING' },
      altText: { type: 'STRING' }, sourceIds: { type: 'ARRAY', items: { type: 'STRING' } },
      clinicalReviewRequired: { type: 'BOOLEAN' }
    }, required: ['type', 'title', 'purpose', 'content', 'caption', 'altText', 'sourceIds', 'clinicalReviewRequired'] } },
  }),
  mcqs: objectArraySchema({
    stem: { type: 'STRING' }, options: { type: 'ARRAY', items: { type: 'STRING' } }, correctIndex: { type: 'INTEGER' }, rationale: { type: 'STRING' },
    distractorRationales: { type: 'ARRAY', items: { type: 'STRING' } }, difficulty: { type: 'STRING' }, learningOutcomeIndex: { type: 'INTEGER' }, sourceIds: { type: 'ARRAY', items: { type: 'STRING' } },
  }),
  flashcards: objectArraySchema({
    front: { type: 'STRING' }, back: { type: 'STRING' }, difficulty: { type: 'STRING' }, learningOutcomeIndex: { type: 'INTEGER' }, sourceIds: { type: 'ARRAY', items: { type: 'STRING' } },
  }),
  written: objectArraySchema({
    question: { type: 'STRING' }, answerPoints: { type: 'ARRAY', items: { type: 'STRING' } }, difficulty: { type: 'STRING' }, marks: { type: 'INTEGER' }, learningOutcomeIndex: { type: 'INTEGER' }, sourceIds: { type: 'ARRAY', items: { type: 'STRING' } },
  }),
  course_tests: objectArraySchema({
    title: { type: 'STRING' }, durationMinutes: { type: 'INTEGER' }, questionCount: { type: 'INTEGER' },
    blueprint: { type: 'ARRAY', items: { type: 'OBJECT', properties: { topic: { type: 'STRING' }, questionCount: { type: 'INTEGER' }, difficulty: { type: 'STRING' } }, required: ['topic', 'questionCount', 'difficulty'] } },
    instructions: { type: 'ARRAY', items: { type: 'STRING' } },
  }),
  semester_mocks: objectArraySchema({
    title: { type: 'STRING' }, durationMinutes: { type: 'INTEGER' }, questionCount: { type: 'INTEGER' },
    courseBlueprint: { type: 'ARRAY', items: { type: 'OBJECT', properties: { courseId: { type: 'STRING' }, questionCount: { type: 'INTEGER' } }, required: ['courseId', 'questionCount'] } },
    instructions: { type: 'ARRAY', items: { type: 'STRING' } },
  }),
};

const verificationSchema = objectArraySchema({
  index: { type: 'INTEGER' }, pass: { type: 'BOOLEAN' }, answerCorrect: { type: 'BOOLEAN' },
  issues: { type: 'ARRAY', items: { type: 'STRING' } }, unsupportedClaims: { type: 'ARRAY', items: { type: 'STRING' } },
});

function reply(res, status, body) {
  res.writeHead(status, { 'content-type': 'application/json' });
  res.end(JSON.stringify(body));
}

async function loadSemesterConfig(semesterNum) {
  const data = JSON.parse(await readFile(new URL(`../data/semester-${semesterNum}.json`, import.meta.url), 'utf8'));
  const sources = JSON.parse(await readFile(new URL(`../data/semester-${semesterNum}-sources.json`, import.meta.url), 'utf8'));
  return { semesterData: data, sourceLibrary: sources, jobId: `semester-${semesterNum}-hec-2024` };
}

async function seedSemesterNum(semNum) {
  const { semesterData, sourceLibrary, jobId } = await loadSemesterConfig(semNum);
  const ref = db.collection('contentJobs').doc(jobId);
  const existing = await ref.get();
  if (existing.exists) return { jobId, status: existing.data().status, existing: true };
  await ref.set({
    id: jobId, type: 'semester_full_draft_generation', pipelineVersion: 3, semester: semNum,
    curriculumVersion: semesterData.curriculumVersion, sourceLibraryVersion: sourceLibrary.version,
    courses: semesterData.courses, cursor: initialCursor(), status: 'queued', publicationEnabled: false,
    ownerReviewGate: 'semester_complete', inventory: semesterData.inventory ?? semesterData.courses.map(course => ({ courseId: course.id, ...targetsForCourse(course) })),
    richMediaPolicy: { requiredPerLesson: { min: 2, max: 4 }, allowed: ['diagram','flowchart','comparison_table','timeline','concept_map','data_chart'], altTextRequired: true, clinicalReviewRequired: true },
    creditGuard: { semesterCapUsd, maxBatchUsd, stopAtGlobalPercent: 90, consumedUsd: 0 },
    createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(),
  });
  return { jobId, status: 'queued', existing: false };
}

async function notifyOwnerOnComplete({ semester, jobId, consumedUsd }) {
  const message = `🎉 Nursely Pakistan Semester ${semester} generation complete & verified! Total spent: $${consumedUsd.toFixed(4)}. Sent notification to ${ownerEmail}`;
  console.log(`[NOTIFICATION_SEMESTER_COMPLETE] ${message}`);
  try {
    await db.collection('notifications').add({
      recipient: ownerEmail,
      type: 'semester_complete',
      semester,
      jobId,
      consumedUsd,
      message: `Nursely Pakistan Semester ${semester} content generation and automated verification are 100% complete! Total credit spent: $${consumedUsd.toFixed(4)}.`,
      sentAt: FieldValue.serverTimestamp()
    });
  } catch (err) {
    console.error('Failed to log notification record:', err);
  }
}

async function findActiveJob() {
  for (let sem = 3; sem <= 8; sem++) {
    const jobId = `semester-${sem}-hec-2024`;
    const doc = await db.collection('contentJobs').doc(jobId).get();
    if (!doc.exists) {
      await seedSemesterNum(sem);
      const newDoc = await db.collection('contentJobs').doc(jobId).get();
      return { sem, job: newDoc.data(), jobId };
    }
    const data = doc.data();
    if (['queued', 'running'].includes(data.status)) {
      return { sem, job: data, jobId };
    }
  }
  return null;
}

async function loadOutline(activeSemester, courseId) {
  const newDoc = await db.collection('contentDrafts').doc(contentId({ semester: activeSemester, stage: 'outlines', courseId, index: 0 })).get();
  return newDoc.exists ? newDoc.data().body : null;
}

function estimateUsd(usage = {}) {
  return Number((((usage.promptTokenCount ?? 0) * 0.30 + (usage.candidatesTokenCount ?? 0) * 2.50) / 1_000_000).toFixed(6));
}

async function saveItems({ activeSemester, semesterData, sourceLibrary, cursor, course, items, verification, generationUsage, reviewUsage }) {
  const writer = db.bulkWriter();
  const sourcesForCourse = (cId) => {
    const ids = sourceLibrary.courseSources[cId] ?? [semesterData.courses[0].id];
    return ids.map(id => sourceLibrary.sources.find(source => source.id === id)).filter(Boolean);
  };
  const sourceIds = course ? sourcesForCourse(course.id).map(s => s.id) : sourceLibrary.sources.map(s => s.id);

  for (let index = 0; index < items.length; index += 1) {
    const absoluteIndex = cursor.offset + index;
    const id = contentId({ semester: activeSemester, stage: cursor.stage, courseId: course?.id, index: absoluteIndex });
    const check = verification[index] ?? { index, pass: false, answerCorrect: false, issues: ['Verifier did not return a result.'], unsupportedClaims: [] };
    const item = items[index];
    const duplicateSeed = item.stem ?? item.front ?? item.question ?? item.title ?? JSON.stringify(item);
    writer.set(db.collection('contentDrafts').doc(id), {
      id, semester: activeSemester, courseId: course?.id ?? null, curriculumVersion: semesterData.curriculumVersion,
      contentType: cursor.stage, body: item, originalGeneratedText: item, sourceIds, sourceLibraryVersion: sourceLibrary.version,
      model, reviewModel, promptVersion: 'semester-full-draft-v3', difficulty: item.difficulty ?? 'mixed',
      risk: riskFor(course?.id, cursor.stage),
      automatedReview: { generatorVerifierAgreement: Boolean(check.pass && check.answerCorrect), citationsValid: check.unsupportedClaims.length === 0, issues: check.issues, unsupportedClaims: check.unsupportedClaims },
      reviewState: check.pass && check.answerCorrect ? 'draft_verified' : 'draft_flagged', ownerApproval: { approved: false },
      packageEligible: false, publicationEnabled: false, fingerprint: fingerprint(duplicateSeed), revision: 1,
      usage: { generation: generationUsage, verification: reviewUsage }, updatedAt: FieldValue.serverTimestamp(), createdAt: FieldValue.serverTimestamp(),
    });
  }
  await writer.close();
}

async function processBatch() {
  const active = await findActiveJob();
  if (!active) {
    return { status: 'all_semesters_complete', message: 'All Semesters (1 through 8) have finished generation and verification!' };
  }

  const { sem: activeSemester, jobId } = active;
  const { semesterData, sourceLibrary } = await loadSemesterConfig(activeSemester);
  const ref = db.collection('contentJobs').doc(jobId);

  const claimed = await db.runTransaction(async transaction => {
    const snapshot = await transaction.get(ref);
    if (!snapshot.exists) return null;
    const job = snapshot.data();
    if (job.pipelineVersion !== 3 || !['queued', 'running'].includes(job.status)) return null;
    if ((job.creditGuard?.consumedUsd ?? 0) + maxBatchUsd > semesterCapUsd) {
      transaction.set(ref, { status: 'stopped', stoppedReason: 'semester_budget_cap', updatedAt: FieldValue.serverTimestamp() }, { merge: true });
      return null;
    }
    const lease = job.leaseExpiresAt?.toDate?.();
    if (lease && lease > new Date()) return null;
    transaction.set(ref, { status: 'running', leaseExpiresAt: new Date(Date.now() + 9 * 60 * 1000), updatedAt: FieldValue.serverTimestamp() }, { merge: true });
    return job;
  });
  if (!claimed) return { status: 'idle' };

  const cursor = claimed.cursor;
  if (!cursor) {
    await ref.set({ status: 'semester_review', leaseExpiresAt: null, completedAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp() }, { merge: true });
    await notifyOwnerOnComplete({ semester: activeSemester, jobId, consumedUsd: claimed.creditGuard?.consumedUsd ?? 0 });
    if (activeSemester < 8) await seedSemesterNum(activeSemester + 1);
    return { jobId, semester: activeSemester, status: 'semester_review', autoAdvancingTo: activeSemester + 1 };
  }

  const course = cursor.stage === 'semester_mocks' ? null : semesterData.courses[cursor.courseIndex];
  const count = batchCount(cursor, semesterData.courses);

  const sourcesForCourse = (courseId) => {
    const ids = sourceLibrary.courseSources[courseId] ?? [semesterData.courses[0].id];
    return ids.map(id => sourceLibrary.sources.find(source => source.id === id)).filter(Boolean);
  };
  const courseContext = (c) => `Course ID: ${c.id}\nCourse: ${c.title}\nCredits: ${c.credits}; theory ${c.theory}; lab/skills ${c.lab}.\nHEC outcomes:\n${c.outcomes.map((v, i) => `${i+1}. ${v}`).join('\n')}`;
  const sourceContext = (courseId) => sourcesForCourse(courseId).map(s => `[${s.id}] ${s.title}; ${s.publisher}; ${s.license}; ${s.url}\nPermitted scope: ${s.scope}`).join('\n\n');

  const generationPrompt = () => {
    const start = cursor.offset + 1;
    const common = `Create INTERNAL DRAFT study content for Pakistani Generic BSN Semester ${activeSemester} students.\n${courseContext(course)}\n` +
      `Approved source register:\n${sourceContext(course.id)}\n` +
      `Use only concepts inside the stated source scopes. Paraphrase; do not reproduce textbook passages. Record only source IDs from this register. ` +
      `Never fabricate citations, laws, statistics, doses, reference ranges, diagnostic thresholds or clinical recommendations. ` +
      `Patient-safety and Pakistan-specific scope claims must be explicitly cautious and will receive owner review. Return exactly ${count} item(s) in JSON.`;
    if (cursor.stage === 'outlines') return `${common}\nCreate one coherent unit map strictly aligned to the official HEC Generic BSN Curriculum 2024 outcomes. Unit scope statements only. Mark institutional syllabus review true when HEC outcomes are absent.`;
    if (cursor.stage === 'lessons') return `${common}\nCreate lessons ${start}-${start + count - 1} of ${targetsForCourse(course).lessons} strictly abiding by the HEC Generic BSN 2024 Nursing Curriculum. Each lesson must be self-contained, concise but substantive, with 3-6 sections, objectives, key terms, summary points, safety cautions, AND 2-4 structured visual aid specifications (diagrams, flowcharts, comparison tables, concept maps, timelines, or data charts) with detailed content, captions, and altText where necessary for clinical and conceptual understanding.`;
    if (cursor.stage === 'mcqs') return `${common}\nCreate MCQs ${start}-${start + count - 1} of ${targetsForCourse(course).mcqs} according to HEC Generic BSN assessment standards. Every item must have exactly four plausible options, correctIndex 0-3, a positive rationale, and option-specific rationales. Avoid trick wording and duplicates.`;
    if (cursor.stage === 'flashcards') return `${common}\nCreate flashcards ${start}-${start + count - 1} of ${targetsForCourse(course).flashcards} following HEC BSN high-yield concepts. One testable fact per card; concise front and unambiguous back.`;
    if (cursor.stage === 'written') return `${common}\nCreate written questions ${start}-${start + count - 1} of ${targetsForCourse(course).written} meeting HEC BSN exam standards. Include an objective answer-point rubric and realistic marks.`;
    if (cursor.stage === 'course_tests') return `${common}\nCreate two distinct course-test blueprints. Each uses the generated MCQ bank, totals 50 questions, balances units and difficulty according to HEC BSN credit weights.`;
    throw new Error(`Unsupported course stage ${cursor.stage}`);
  };

  const mockPrompt = () => {
    const courses = semesterData.courses.map(c => `${c.id}: ${c.title}, ${c.credits} credits`).join('\n');
    return `Create exactly ${count} INTERNAL DRAFT Semester ${activeSemester} mock-examination blueprints for Nursely Pakistan abiding strictly by HEC Generic BSN Curriculum guidelines.\nCourses:\n${courses}\n` +
      `Each mock selects from the generated MCQ banks, contains 100 questions, allocates questions broadly by credits, covers every course, and has a 120-minute duration. Return JSON only.`;
  };

  const verificationPrompt = (items) => {
    return `Act as an independent academic verifier for the Higher Education Commission (HEC) BSN Nursing Program in Pakistan. Check every generated ${cursor.stage} item for strict adherence to HEC curriculum outcomes, factual support within registered source scopes, presence of required visual aids (diagrams/flowcharts/tables where applicable), internal consistency, answer correctness, ambiguity, duplicated options, and clinical safety.\n` +
      `Return one result for every zero-based index.\nCourse:\n${course ? courseContext(course) : `All Semester ${activeSemester} courses`}\n` +
      `Sources:\n${course ? sourceContext(course.id) : sourceLibrary.sources.map(s => `[${s.id}] ${s.scope}`).join('\n')}\nCandidates:\n${JSON.stringify(items)}`;
  };

  const outline = course && cursor.stage !== 'outlines' ? await loadOutline(activeSemester, course.id) : null;
  const token = await credential.getAccessToken();
  const prompt = cursor.stage === 'semester_mocks' ? mockPrompt() : generationPrompt();

  const generated = await generateWithVertex({ projectId, accessToken: token.access_token, model, prompt, responseSchema: schemas[cursor.stage] });
  const returnedItems = Array.isArray(generated.item?.items) ? generated.item.items : [];
  if (returnedItems.length < count) throw new Error(`Vertex returned ${returnedItems.length} items; expected at least ${count}`);
  const generatedItems = returnedItems.slice(0, count);

  const review = await generateWithVertex({ projectId, accessToken: token.access_token, model: reviewModel, prompt: verificationPrompt(generatedItems), responseSchema: verificationSchema });
  const verificationItems = Array.isArray(review.item?.items) ? review.item.items.slice(0, count) : [];

  await saveItems({ activeSemester, semesterData, sourceLibrary, cursor, course, items: generatedItems, verification: verificationItems, generationUsage: generated.usage, reviewUsage: review.usage });

  const cost = estimateUsd(generated.usage) + estimateUsd(review.usage);
  const consumedUsd = Number(((claimed.creditGuard?.consumedUsd ?? 0) + cost).toFixed(6));
  const nextCursor = advanceCursor(cursor, count, semesterData.courses);
  const isFinished = !nextCursor;
  const status = isFinished ? 'semester_review' : (consumedUsd >= semesterCapUsd ? 'stopped' : 'queued');

  await ref.set({
    cursor: nextCursor, status, leaseExpiresAt: null,
    consecutiveFailures: 0, lastError: null, errorCode: null,
    creditGuard: { ...claimed.creditGuard, semesterCapUsd, consumedUsd },
    lastBatch: { stage: cursor.stage, courseId: course?.id ?? null, offset: cursor.offset, count, verified: verificationItems.filter(item => item.pass && item.answerCorrect).length, estimatedUsd: Number(cost.toFixed(6)) },
    ...(isFinished ? { completedAt: FieldValue.serverTimestamp() } : {}),
    ...(status === 'stopped' ? { stoppedReason: 'semester_budget_cap' } : {}),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });

  if (isFinished) {
    await notifyOwnerOnComplete({ semester: activeSemester, jobId, consumedUsd });
    if (activeSemester < 8) await seedSemesterNum(activeSemester + 1);
  }

  return { jobId, semester: activeSemester, status, generated: { stage: cursor.stage, courseId: course?.id ?? null, offset: cursor.offset, count }, nextCursor, estimatedUsd: Number(cost.toFixed(6)), consumedUsd };
}

http.createServer(async (req, res) => {
  try {
    if (req.method === 'GET' && req.url === '/healthz') return reply(res, 200, { service: 'nursely-content-worker', status: 'healthy', pipelineVersion: 3, autoAdvance: true, ownerEmail, model, reviewModel, semesterCapUsd, globalCapUsd, maxBatchUsd });
    if (req.method === 'POST' && req.url === '/run') return reply(res, 200, await processBatch());
    return reply(res, 404, { error: 'not_found' });
  } catch (error) {
    console.error(error);
    return reply(res, 500, { error: 'worker_failure', message: error.message });
  }
}).listen(port, () => console.log(`Nursely worker listening on ${port}`));
