import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { createHash } from 'node:crypto';

const semester = Number(process.argv[2] ?? 1);
const assetDestination = resolve(process.argv[3] ?? `../../student_app/assets/content/semester-${semester}.json`);
const hostingDestination = resolve(`../../student_app/web/content/semester-${semester}.json`);
const assetManifestPath = resolve('../../student_app/assets/content/manifest.json');
const hostingManifestPath = resolve('../../student_app/web/content/manifest.json');

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

const serialized = `${JSON.stringify(packageFile, null, 2)}\n`;
for (const destination of [assetDestination, hostingDestination]) {
  await mkdir(dirname(destination), { recursive: true });
  await writeFile(destination, serialized, 'utf8');
}

const manifest = JSON.parse(await readFile(assetManifestPath, 'utf8'));
const status = manifest.semesters.find(item => item.semester === semester);
if (!status) throw new Error(`Semester ${semester} is missing from the manifest.`);
status.status = 'published';
status.packageVersion = packageFile.sha256.slice(0, 12);
status.packageUrl = `content/semester-${semester}.json?v=${status.packageVersion}`;
status.itemCount = items.length;
status.updatedAt = packageFile.exportedAt;
const serializedManifest = `${JSON.stringify(manifest, null, 2)}\n`;
await writeFile(assetManifestPath, serializedManifest, 'utf8');
await writeFile(hostingManifestPath, serializedManifest, 'utf8');

console.log(JSON.stringify({ destinations: [assetDestination, hostingDestination], itemCount: items.length, counts, packageVersion: status.packageVersion }, null, 2));
