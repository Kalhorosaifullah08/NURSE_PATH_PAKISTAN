import http from 'node:http';
import { readFile } from 'node:fs/promises';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { generateWithVertex } from './vertex-client.mjs';
import { advanceCursor, batchCount, contentId, fingerprint, initialCursor, riskFor, targetsForCourse } from './pipeline.mjs';

const credential = applicationDefault();
initializeApp({ credential });
const db = getFirestore();
const port = Number(process.env.PORT ?? 8080);
const projectId = process.env.GOOGLE_CLOUD_PROJECT ?? process.env.GCLOUD_PROJECT;
const model = process.env.VERTEX_MODEL ?? 'gemini-2.5-flash';
const reviewModel = process.env.VERTEX_REVIEW_MODEL ?? model;
const activeSemester = Number(process.env.ACTIVE_SEMESTER ?? 3);
if (activeSemester !== 3) throw new Error('This revision is safety-locked to Semester 3.');
const semesterData = JSON.parse(await readFile(new URL(`../data/semester-${activeSemester}.json`, import.meta.url), 'utf8'));
const sourceLibrary = JSON.parse(await readFile(new URL(`../data/semester-${activeSemester}-sources.json`, import.meta.url), 'utf8'));
const jobId = `semester-${activeSemester}-hec-2024`;
const semesterCapUsd = Number(process.env.SEMESTER_CAP_USD ?? 103.50);
const maxBatchUsd = Number(process.env.MAX_BATCH_USD ?? 1.50);

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

function sourcesFor(courseId) {
  const ids = sourceLibrary.courseSources[courseId] ?? [semesterData.source.id];
  return ids.map(id => sourceLibrary.sources.find(source => source.id === id)).filter(Boolean);
}

function courseContext(course) {
  const outcomes = course.outcomes.length
    ? course.outcomes.map((value, index) => `${index + 1}. ${value}`).join('\n')
    : 'No course-specific outcomes appear in the HEC BSN document; content is provisional and requires comparison with the student university syllabus.';
  return `Course ID: ${course.id}\nCourse: ${course.title}\nCredits: ${course.credits}; theory ${course.theory}; lab/skills ${course.lab}.\nHEC outcomes:\n${outcomes}`;
}

function sourceContext(courseId) {
  return sourcesFor(courseId).map(source =>
    `[${source.id}] ${source.title}; ${source.publisher}; ${source.license}; ${source.url}\nPermitted scope: ${source.scope}`
  ).join('\n\n');
}

function generationPrompt(cursor, course, count, outline) {
  const start = cursor.offset + 1;
  const common = `Create INTERNAL DRAFT study content for Pakistani Generic BSN Semester ${activeSemester} students.\n${courseContext(course)}\n` +
    `Approved source register:\n${sourceContext(course.id)}\n` +
    `Use only concepts inside the stated source scopes. Paraphrase; do not reproduce textbook passages or existing questions. Record only source IDs from this register. ` +
    `Never fabricate citations, laws, statistics, doses, reference ranges, diagnostic thresholds or clinical recommendations. ` +
    `Patient-safety and Pakistan-specific scope claims must be explicitly cautious and will receive owner review. Return exactly ${count} item(s) in JSON.`;
  if (cursor.stage === 'outlines') return `${common}\nCreate one coherent unit map aligned to the supplied HEC outcomes. Unit scope statements only. Mark institutional syllabus review true when HEC outcomes are absent.`;
  if (cursor.stage === 'lessons') return `${common}\nCourse outline: ${JSON.stringify(outline?.units ?? [])}\nCreate lessons ${start}-${start + count - 1} of ${targetsForCourse(course).lessons}. Each lesson must be self-contained and substantive, with 3-6 sections, objectives, key terms, summary points and safety cautions where relevant. Every lesson MUST include 2-4 useful visuals chosen from diagram, flowchart, comparison_table, timeline, concept_map or data_chart. Visual content must be structured as short labels/steps/data that the app can render; include an accurate caption and descriptive alt text. Never request a decorative stock image or fabricate patient imagery, anatomy, clinical values or statistics. Set clinicalReviewRequired=true for any clinical process, anatomy, nutrition or patient-safety visual. Distribute lessons across the outline without repetition.`;
  if (cursor.stage === 'mcqs') return `${common}\nCourse outline: ${JSON.stringify(outline?.units ?? [])}\nCreate MCQs ${start}-${start + count - 1} of ${targetsForCourse(course).mcqs}. Every item must have exactly four plausible options, correctIndex 0-3, a positive rationale, and exactly four option-specific rationales. Avoid trick wording, negatives and duplicates. Mix recall, understanding and application.`;
  if (cursor.stage === 'flashcards') return `${common}\nCourse outline: ${JSON.stringify(outline?.units ?? [])}\nCreate flashcards ${start}-${start + count - 1} of ${targetsForCourse(course).flashcards}. One testable fact per card; concise front and unambiguous back; no duplicate concepts.`;
  if (cursor.stage === 'written') return `${common}\nCourse outline: ${JSON.stringify(outline?.units ?? [])}\nCreate written questions ${start}-${start + count - 1} of ${targetsForCourse(course).written}. Include an objective answer-point rubric and realistic marks. Mix short and structured questions.`;
  if (cursor.stage === 'course_tests') return `${common}\nCourse outline: ${JSON.stringify(outline?.units ?? [])}\nCreate two distinct course-test blueprints. Each uses the generated MCQ bank, totals 50 questions, balances course units and difficulty, and includes clear instructions. Do not invent new questions here.`;
  throw new Error(`Unsupported course stage ${cursor.stage}`);
}

function mockPrompt(count) {
  const courses = semesterData.courses.map(course => `${course.id}: ${course.title}, ${course.credits} credits`).join('\n');
  return `Create exactly ${count} INTERNAL DRAFT Semester ${activeSemester} mock-examination blueprints for NursePath Pakistan.\nCourses:\n${courses}\n` +
    `Each mock selects from the already generated MCQ banks, contains 100 questions, allocates questions broadly by credits, covers every course, and has a 120-minute duration. ` +
    `courseId values must exactly match the list. The courseBlueprint question counts must total 100. Return JSON only.`;
}

function verificationPrompt(cursor, course, items) {
  return `Act as an independent academic verifier. Check every generated ${cursor.stage} item for factual support within the registered source scopes, internal consistency, answer correctness, ambiguity, duplicated options, unsafe clinical advice, and invented Pakistan-specific claims. ` +
    `Do not rewrite items. Return one result for every zero-based index. For blueprints, answerCorrect means internal totals and constraints are correct. ` +
    `For lessons, also reject missing, decorative, inaccessible, misleading or clinically unsafe visual specifications. Set pass=false for any unsupported or doubtful claim.\nCourse:\n${course ? courseContext(course) : `All Semester ${activeSemester} courses`}\n` +
    `Sources:\n${course ? sourceContext(course.id) : sourceLibrary.sources.map(s => `[${s.id}] ${s.scope}`).join('\n')}\nCandidates:\n${JSON.stringify(items)}`;
}

function estimateUsd(usage = {}) {
  const input = usage.promptTokenCount ?? 0;
  const output = usage.candidatesTokenCount ?? 0;
  return Number(((input * 0.30 + output * 2.50) / 1_000_000).toFixed(6));
}

async function seedSemester() {
  const ref = db.collection('contentJobs').doc(jobId);
  const existing = await ref.get();
  if (existing.exists) return { jobId, status: existing.data().status, existing: true };
  await ref.set({
    id: jobId, type: 'semester_full_draft_generation', pipelineVersion: 3, semester: activeSemester,
    curriculumVersion: semesterData.curriculumVersion, sourceLibraryVersion: sourceLibrary.version,
    courses: semesterData.courses, cursor: initialCursor(), status: 'queued', publicationEnabled: false,
    ownerReviewGate: 'semester_complete', inventory: semesterData.courses.map(course => ({ courseId: course.id, ...targetsForCourse(course) })),
    richMediaPolicy: { requiredPerLesson: { min: 2, max: 4 }, allowed: ['diagram','flowchart','comparison_table','timeline','concept_map','data_chart'], altTextRequired: true, clinicalReviewRequired: true },
    creditGuard: { semesterCapUsd, maxBatchUsd, stopAtGlobalPercent: 90, consumedUsd: 0 },
    createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(),
  });
  return { jobId, status: 'queued', existing: false };
}

async function loadOutline(courseId) {
  const newDoc = await db.collection('contentDrafts').doc(contentId({ semester: activeSemester, stage: 'outlines', courseId, index: 0 })).get();
  if (newDoc.exists) return newDoc.data().body;
  return newDoc.exists ? newDoc.data().body : null;
}

async function saveItems({ cursor, course, items, verification, generationUsage, reviewUsage }) {
  const writer = db.bulkWriter();
  const sourceIds = course ? sourcesFor(course.id).map(source => source.id) : sourceLibrary.sources.map(source => source.id);
  for (let index = 0; index < items.length; index += 1) {
    const absoluteIndex = cursor.offset + index;
    const id = contentId({ semester: activeSemester, stage: cursor.stage, courseId: course?.id, index: absoluteIndex });
    const check = verification[index] ?? { index, pass: false, answerCorrect: false, issues: ['Verifier did not return a result.'], unsupportedClaims: [] };
    const item = items[index];
    const duplicateSeed = item.stem ?? item.front ?? item.question ?? item.title ?? JSON.stringify(item);
    writer.set(db.collection('contentDrafts').doc(id), {
      id, semester: activeSemester, courseId: course?.id ?? null, curriculumVersion: semesterData.curriculumVersion,
      contentType: { outlines: 'course_outline', lessons: 'lesson', mcqs: 'mcq', flashcards: 'flashcard', written: 'written_question', course_tests: 'course_test', semester_mocks: 'semester_mock' }[cursor.stage],
      body: item, originalGeneratedText: item, sourceIds, sourceLibraryVersion: sourceLibrary.version,
      model, reviewModel, promptVersion: 'semester-full-draft-v2', difficulty: item.difficulty ?? 'mixed',
      risk: riskFor(course?.id, cursor.stage === 'semester_mocks' ? 'semester_mock' : cursor.stage),
      automatedReview: { generatorVerifierAgreement: Boolean(check.pass && check.answerCorrect), citationsValid: check.unsupportedClaims.length === 0, issues: check.issues, unsupportedClaims: check.unsupportedClaims },
      reviewState: check.pass && check.answerCorrect ? 'draft_verified' : 'draft_flagged', ownerApproval: { approved: false },
      packageEligible: false, publicationEnabled: false, fingerprint: fingerprint(duplicateSeed), revision: 1,
      usage: { generation: generationUsage, verification: reviewUsage }, updatedAt: FieldValue.serverTimestamp(), createdAt: FieldValue.serverTimestamp(),
    });
  }
  await writer.close();
}

async function processBatch() {
  const ref = db.collection('contentJobs').doc(jobId);
  const current = await ref.get();
  if (!current.exists) {
    await seedSemester();
    return { jobId, status: 'seeded', nextAction: 'next_scheduler_call_starts_generation' };
  }
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
    return { jobId, status: 'semester_review' };
  }
  const course = cursor.stage === 'semester_mocks' ? null : semesterData.courses[cursor.courseIndex];
  const count = batchCount(cursor, semesterData.courses);
  const outline = course && cursor.stage !== 'outlines' ? await loadOutline(course.id) : null;
  const token = await credential.getAccessToken();
  const prompt = cursor.stage === 'semester_mocks' ? mockPrompt(count) : generationPrompt(cursor, course, count, outline);
  const generated = await generateWithVertex({ projectId, accessToken: token.access_token, model, prompt, responseSchema: schemas[cursor.stage] });
  const returnedItems = Array.isArray(generated.item?.items) ? generated.item.items : [];
  if (returnedItems.length < count) throw new Error(`Vertex returned ${returnedItems.length} items; expected at least ${count}`);
  const generatedItems = returnedItems.slice(0, count);
  if (returnedItems.length > count) console.warn(`Vertex returned ${returnedItems.length} items; safely trimming to ${count}`);
  const review = await generateWithVertex({ projectId, accessToken: token.access_token, model: reviewModel, prompt: verificationPrompt(cursor, course, generatedItems), responseSchema: verificationSchema });
  const verificationItems = Array.isArray(review.item?.items) ? review.item.items.slice(0, count) : [];
  await saveItems({ cursor, course, items: generatedItems, verification: verificationItems, generationUsage: generated.usage, reviewUsage: review.usage });
  const cost = estimateUsd(generated.usage) + estimateUsd(review.usage);
  const consumedUsd = Number(((claimed.creditGuard?.consumedUsd ?? 0) + cost).toFixed(6));
  const nextCursor = advanceCursor(cursor, count, semesterData.courses);
  const status = nextCursor ? (consumedUsd >= semesterCapUsd ? 'stopped' : 'queued') : 'semester_review';
  await ref.set({
    cursor: nextCursor, status, leaseExpiresAt: null,
    creditGuard: { ...claimed.creditGuard, semesterCapUsd, consumedUsd },
    lastBatch: { stage: cursor.stage, courseId: course?.id ?? null, offset: cursor.offset, count, verified: review.item.items.filter(item => item.pass && item.answerCorrect).length, estimatedUsd: Number(cost.toFixed(6)) },
    ...(status === 'semester_review' ? { completedAt: FieldValue.serverTimestamp() } : {}),
    ...(status === 'stopped' ? { stoppedReason: 'semester_budget_cap' } : {}),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  return { jobId, status, generated: { stage: cursor.stage, courseId: course?.id ?? null, offset: cursor.offset, count }, nextCursor, estimatedUsd: Number(cost.toFixed(6)), consumedUsd };
}

http.createServer(async (req, res) => {
  try {
    if (req.method === 'GET' && req.url === '/healthz') return reply(res, 200, { service: 'nursepath-content-worker', status: 'healthy', pipelineVersion: 3, activeSemester, model, reviewModel, semesterCapUsd, maxBatchUsd });
    if (req.method === 'POST' && req.url === '/seed/semester-3') return reply(res, 200, await seedSemester());
    if (req.method === 'POST' && req.url === '/run') return reply(res, 200, await processBatch());
    return reply(res, 404, { error: 'not_found' });
  } catch (error) {
    console.error(error);
    try {
      await db.collection('contentJobs').doc(jobId).set({ status: 'queued', leaseExpiresAt: null, lastError: error.message, lastErrorAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp() }, { merge: true });
    } catch (writeError) { console.error(writeError); }
    return reply(res, 500, { error: 'worker_failure', message: error.message });
  }
}).listen(port, () => console.log(`NursePath worker listening on ${port}`));
