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

function decodeValue(value) {
  if ('nullValue' in value) return null;
  if ('stringValue' in value) return value.stringValue;
  if ('booleanValue' in value) return value.booleanValue;
  if ('integerValue' in value) return Number(value.integerValue);
  if ('doubleValue' in value) return value.doubleValue;
  if ('timestampValue' in value) return value.timestampValue;
  if ('arrayValue' in value) return (value.arrayValue.values ?? []).map(decodeValue);
  if ('mapValue' in value) return decodeFields(value.mapValue.fields ?? {});
  return null;
}

function decodeFields(fields) {
  return Object.fromEntries(Object.entries(fields).map(([key, value]) => [key, decodeValue(value)]));
}

async function loadDrafts() {
  const accessToken = process.env.GOOGLE_OAUTH_ACCESS_TOKEN;
  if (accessToken) {
    const projectId = process.env.GOOGLE_CLOUD_PROJECT;
    if (!projectId) throw new Error('GOOGLE_CLOUD_PROJECT is required with GOOGLE_OAUTH_ACCESS_TOKEN.');
    const response = await fetch(
      `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents:runQuery`,
      {
        method: 'POST',
        headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          structuredQuery: {
            from: [{ collectionId: 'contentDrafts' }],
            where: {
              fieldFilter: {
                field: { fieldPath: 'semester' },
                op: 'EQUAL',
                value: { integerValue: String(semester) },
              },
            },
          },
        }),
      },
    );
    if (!response.ok) throw new Error(`Firestore export failed (${response.status}): ${await response.text()}`);
    return (await response.json()).flatMap(row => row.document ? [decodeFields(row.document.fields ?? {})] : []);
  }

  initializeApp({ credential: applicationDefault() });
  const db = getFirestore();
  const snapshot = await db.collection('contentDrafts').where('semester', '==', semester).get();
  return snapshot.docs.map(document => document.data());
}

const drafts = await loadDrafts();

const items = drafts
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
