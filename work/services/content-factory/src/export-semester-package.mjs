import { mkdir, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { createHash } from 'node:crypto';

const semester = Number(process.argv[2] ?? 1);
const destination = resolve(process.argv[3] ?? `../../student_app/assets/content/semester-${semester}.json`);

if (!Number.isInteger(semester) || semester < 1 || semester > 8) {
  throw new Error('Semester must be an integer between 1 and 8.');
}

initializeApp({ credential: applicationDefault() });
const db = getFirestore();
const snapshot = await db.collection('contentDrafts').where('semester', '==', semester).get();

const items = snapshot.docs
  .map(document => document.data())
  .filter(item =>
    item.automatedReview?.generatorVerifierAgreement === true &&
    item.automatedReview?.citationsValid === true &&
    Array.isArray(item.automatedReview?.unsupportedClaims) &&
    item.automatedReview.unsupportedClaims.length === 0
  )
  .map(item => ({
    id: item.id,
    semester: item.semester,
    courseId: item.courseId,
    contentType: item.contentType,
    body: item.body,
    sourceIds: item.sourceIds,
    risk: item.risk,
    reviewState: item.reviewState,
  }))
  .sort((a, b) => a.id.localeCompare(b.id));

if (items.length === 0) throw new Error(`No verified Semester ${semester} drafts were found.`);

const counts = items.reduce((result, item) => {
  const key = item.contentType ?? 'unknown';
  result[key] = (result[key] ?? 0) + 1;
  return result;
}, {});

const content = {
  formatVersion: 1,
  semester,
  curriculumVersion: 'hec-bsn-2024',
  exportedAt: new Date().toISOString(),
  itemCount: items.length,
  counts,
  items,
};
const canonical = JSON.stringify(content);
const packageFile = {
  ...content,
  sha256: createHash('sha256').update(canonical).digest('hex'),
};

await mkdir(dirname(destination), { recursive: true });
await writeFile(destination, `${JSON.stringify(packageFile, null, 2)}\n`, 'utf8');
console.log(JSON.stringify({ destination, itemCount: items.length, counts }, null, 2));
