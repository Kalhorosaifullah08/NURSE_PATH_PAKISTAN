import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { generateWithVertex } from './vertex-client.mjs';
import { advanceCursor, batchCount, contentId, fingerprint, initialCursor, riskFor, targetsForCourse } from './pipeline.mjs';
import { readFile } from 'node:fs/promises';

process.env.GOOGLE_CLOUD_PROJECT = 'deft-reporter-485519-i1';
process.env.ACTIVE_SEMESTER = '3';
process.env.SEMESTER_CAP_USD = '50';

const credential = applicationDefault();
initializeApp({ credential });
const db = getFirestore();

const projectId = 'deft-reporter-485519-i1';
const model = 'gemini-2.5-flash';
const reviewModel = model;
const activeSemester = 3;
const semesterData = JSON.parse(await readFile(new URL(`../data/semester-${activeSemester}.json`, import.meta.url), 'utf8'));
const sourceLibrary = JSON.parse(await readFile(new URL(`../data/semester-${activeSemester}-sources.json`, import.meta.url), 'utf8'));
const jobId = `semester-${activeSemester}-hec-2024`;
const semesterCapUsd = 50;

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

function sourcesFor(courseId) {
  const ids = sourceLibrary.courseSources[courseId] ?? [semesterData.courses[0].id];
  return ids.map(id => sourceLibrary.sources.find(source => source.id === id)).filter(Boolean);
}

function courseContext(course) {
  const outcomes = course.outcomes.length
    ? course.outcomes.map((value, index) => `${index + 1}. ${value}`).join('\n')
    : 'No course-specific outcomes appear in the HEC BSN document.';
  return `Course ID: ${course.id}\nCourse: ${course.title}\nCredits: ${course.credits}; theory ${course.theory}; lab/skills ${course.lab}.\nHEC outcomes:\n${outcomes}`;
}

function sourceContext(courseId) {
  return sourcesFor(courseId).map(source =>
    `[${source.id}] ${source.title}; ${source.publisher}; ${source.license}; ${source.url}\nPermitted scope: ${source.scope}`
  ).join('\n\n');
}

function generationPrompt(cursor, course, count, outline) {
  const start = cursor.offset + 1;
  const common = `Create INTERNAL DRAFT study content for Pakistani Generic BSN Semester 3 students.\n${courseContext(course)}\n` +
    `Approved source register:\n${sourceContext(course.id)}\n` +
    `Use only concepts inside the stated source scopes. Paraphrase; do not reproduce textbook passages. Record only source IDs from this register. ` +
    `Never fabricate citations, laws, statistics, doses, reference ranges, diagnostic thresholds or clinical recommendations. ` +
    `Patient-safety and Pakistan-specific scope claims must be explicitly cautious and will receive owner review. Return exactly ${count} item(s) in JSON.`;
  if (cursor.stage === 'outlines') return `${common}\nCreate one coherent unit map aligned to the supplied HEC outcomes. Unit scope statements only. Mark institutional syllabus review true when HEC outcomes are absent.`;
  if (cursor.stage === 'lessons') return `${common}\nCourse outline: ${JSON.stringify(outline?.units ?? [])}\nCreate lessons ${start}-${start + count - 1} of ${targetsForCourse(course).lessons}. Each lesson must be self-contained, concise but substantive, with 3-6 sections, objectives, key terms, summary points and safety cautions where relevant. Distribute lessons across the outline without repeating earlier sequence positions.`;
  if (cursor.stage === 'mcqs') return `${common}\nCourse outline: ${JSON.stringify(outline?.units ?? [])}\nCreate MCQs ${start}-${start + count - 1} of ${targetsForCourse(course).mcqs}. Every item must have exactly four plausible options, correctIndex 0-3, a positive rationale, and exactly four option-specific rationales. Avoid trick wording, negatives and duplicates. Mix recall, understanding and application.`;
  if (cursor.stage === 'flashcards') return `${common}\nCourse outline: ${JSON.stringify(outline?.units ?? [])}\nCreate flashcards ${start}-${start + count - 1} of ${targetsForCourse(course).flashcards}. One testable fact per card; concise front and unambiguous back; no duplicate concepts.`;
  if (cursor.stage === 'written') return `${common}\nCreate written questions ${start}-${start + count - 1} of ${targetsForCourse(course).written}. Include an objective answer-point rubric and realistic marks. Mix short and structured questions.`;
  if (cursor.stage === 'course_tests') return `${common}\nCreate two distinct course-test blueprints. Each uses the generated MCQ bank, totals 50 questions, balances course units and difficulty, and includes clear instructions.`;
  throw new Error(`Unsupported course stage ${cursor.stage}`);
}

function mockPrompt(count) {
  const courses = semesterData.courses.map(course => `${course.id}: ${course.title}, ${course.credits} credits`).join('\n');
  return `Create exactly ${count} INTERNAL DRAFT Semester 3 mock-examination blueprints for NursePath Pakistan.\nCourses:\n${courses}\n` +
    `Each mock selects from the already generated MCQ banks, contains 100 questions, allocates questions broadly by credits, covers every course, and has a 120-minute duration. Return JSON only.`;
}

function verificationPrompt(cursor, course, items) {
  return `Act as an independent academic verifier. Check every generated ${cursor.stage} item for factual support within the registered source scopes, internal consistency, answer correctness, ambiguity, duplicated options, unsafe clinical advice, and invented claims.\n` +
    `Do not rewrite items. Return one result for every zero-based index.\nCourse:\n${course ? courseContext(course) : 'All Semester 3 courses'}\n` +
    `Sources:\n${course ? sourceContext(course.id) : sourceLibrary.sources.map(s => `[${s.id}] ${s.scope}`).join('\n')}\nCandidates:\n${JSON.stringify(items)}`;
}

function estimateUsd(usage = {}) {
  const input = usage.promptTokenCount ?? 0;
  const output = usage.candidatesTokenCount ?? 0;
  return Number(((input * 0.30 + output * 2.50) / 1_000_000).toFixed(6));
}

async function loadOutline(courseId) {
  const newDoc = await db.collection('contentDrafts').doc(contentId({ stage: 'outlines', courseId, index: 0 })).get();
  if (newDoc.exists) return newDoc.data().body;
  const oldDoc = await db.collection('contentDrafts').doc(`semester-3-outline-${courseId}`).get();
  return oldDoc.exists ? oldDoc.data().originalGeneratedText : null;
}

async function saveItems({ cursor, course, items, verification, generationUsage, reviewUsage }) {
  const writer = db.bulkWriter();
  for (let index = 0; index < items.length; index += 1) {
    const absoluteIndex = cursor.offset + index;
    const id = contentId({ stage: cursor.stage, courseId: course?.id, index: absoluteIndex });
    const check = verification[index] ?? { index, pass: false, answerCorrect: false, issues: ['Verifier did not return a result.'], unsupportedClaims: [] };
    const item = items[index];
    const duplicateSeed = item.stem ?? item.front ?? item.question ?? item.title ?? JSON.stringify(item);
    writer.set(db.collection('contentDrafts').doc(id), {
      id, semester: 3, courseId: course?.id ?? null, curriculumVersion: semesterData.curriculumVersion,
      contentType: cursor.stage, body: item, originalGeneratedText: item, sourceIds: course ? sourcesFor(course.id).map(s => s.id) : [],
      sourceLibraryVersion: sourceLibrary.version, model, reviewModel, promptVersion: 'semester-full-draft-v3', difficulty: item.difficulty ?? 'mixed',
      risk: riskFor(course?.id, cursor.stage),
      automatedReview: { generatorVerifierAgreement: Boolean(check.pass && check.answerCorrect), citationsValid: check.unsupportedClaims.length === 0, issues: check.issues, unsupportedClaims: check.unsupportedClaims },
      reviewState: check.pass && check.answerCorrect ? 'draft_verified' : 'draft_flagged', ownerApproval: { approved: false },
      packageEligible: false, publicationEnabled: false, fingerprint: fingerprint(duplicateSeed), revision: 1,
      usage: { generation: generationUsage, verification: reviewUsage }, updatedAt: FieldValue.serverTimestamp(), createdAt: FieldValue.serverTimestamp(),
    });
  }
  await writer.close();
}

export async function processOneBatch() {
  const ref = db.collection('contentJobs').doc(jobId);
  const snapshot = await ref.get();
  if (!snapshot.exists) throw new Error(`Job ${jobId} not found`);
  const job = snapshot.data();

  // Reset error / lease
  await ref.set({ status: 'running', leaseExpiresAt: new Date(Date.now() + 9 * 60 * 1000), lastError: null, updatedAt: FieldValue.serverTimestamp() }, { merge: true });

  const cursor = job.cursor;
  if (!cursor) {
    await ref.set({ status: 'semester_review', leaseExpiresAt: null, completedAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp() }, { merge: true });
    return { jobId, status: 'semester_review' };
  }

  const course = cursor.stage === 'semester_mocks' ? null : semesterData.courses[cursor.courseIndex];
  const count = batchCount(cursor, semesterData.courses);
  const outline = course && cursor.stage !== 'outlines' ? await loadOutline(course.id) : null;
  const token = await credential.getAccessToken();

  console.log(`Processing batch: stage=${cursor.stage}, course=${course?.id ?? 'all'}, offset=${cursor.offset}, count=${count}...`);

  const prompt = cursor.stage === 'semester_mocks' ? mockPrompt(count) : generationPrompt(cursor, course, count, outline);
  const generated = await generateWithVertex({ projectId, accessToken: token.access_token, model, prompt, responseSchema: schemas[cursor.stage] });
  const returnedItems = Array.isArray(generated.item?.items) ? generated.item.items : [];
  if (returnedItems.length < count) throw new Error(`Vertex returned ${returnedItems.length} items; expected ${count}`);
  const generatedItems = returnedItems.slice(0, count);

  const review = await generateWithVertex({ projectId, accessToken: token.access_token, model: reviewModel, prompt: verificationPrompt(cursor, course, generatedItems), responseSchema: verificationSchema });
  const verificationItems = Array.isArray(review.item?.items) ? review.item.items.slice(0, count) : [];

  await saveItems({ cursor, course, items: generatedItems, verification: verificationItems, generationUsage: generated.usage, reviewUsage: review.usage });

  const cost = estimateUsd(generated.usage) + estimateUsd(review.usage);
  const consumedUsd = Number(((job.creditGuard?.consumedUsd ?? 0) + cost).toFixed(6));
  const nextCursor = advanceCursor(cursor, count, semesterData.courses);
  const status = nextCursor ? (consumedUsd >= semesterCapUsd ? 'stopped' : 'queued') : 'semester_review';

  await ref.set({
    cursor: nextCursor, status, leaseExpiresAt: null,
    consecutiveFailures: 0, lastError: null,
    creditGuard: { ...job.creditGuard, semesterCapUsd, consumedUsd },
    lastBatch: { stage: cursor.stage, courseId: course?.id ?? null, offset: cursor.offset, count, verified: verificationItems.filter(i => i.pass && i.answerCorrect).length, estimatedUsd: Number(cost.toFixed(6)) },
    ...(status === 'semester_review' ? { completedAt: FieldValue.serverTimestamp() } : {}),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });

  console.log(`✓ Batch completed: stage=${cursor.stage}, course=${course?.id ?? 'all'}, offset=${cursor.offset}, cost=$${cost.toFixed(4)}, totalSpent=$${consumedUsd.toFixed(4)}`);
  return { jobId, status, nextCursor, consumedUsd };
}

// Run loop
async function runLoop(maxBatches = 100) {
  console.log(`Starting Semester 3 content generation pipeline (up to ${maxBatches} batches)...`);
  for (let i = 0; i < maxBatches; i++) {
    try {
      const res = await processOneBatch();
      if (res.status === 'semester_review') {
        console.log(`🎉 Semester 3 generation complete! All courses generated and verified.`);
        break;
      }
      if (res.status === 'stopped') {
        console.log(`⏹️ Paused due to budget cap.`);
        break;
      }
    } catch (err) {
      console.error(`❌ Batch error:`, err.message);
      // Brief pause before retry
      await new Promise(r => setTimeout(r, 2000));
    }
  }
}

if (process.argv[1].endsWith('batch_runner.mjs')) {
  runLoop(500);
}
