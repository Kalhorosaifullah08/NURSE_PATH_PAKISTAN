import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';

const configPath = resolve(process.argv[2] ?? 'data/semester-3.json');
const config = JSON.parse(await readFile(configPath, 'utf8'));
const token = process.env.GOOGLE_OAUTH_ACCESS_TOKEN;
const projectId = process.env.GOOGLE_CLOUD_PROJECT;
if (!token || !projectId) throw new Error('GOOGLE_OAUTH_ACCESS_TOKEN and GOOGLE_CLOUD_PROJECT are required.');

const encode = value => {
  if (value === null) return { nullValue: null };
  if (Array.isArray(value)) return { arrayValue: { values: value.map(encode) } };
  if (typeof value === 'object') return { mapValue: { fields: encodeFields(value) } };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number') return Number.isInteger(value) ? { integerValue: String(value) } : { doubleValue: value };
  return { stringValue: String(value) };
};
const encodeFields = object => Object.fromEntries(Object.entries(object).map(([key, value]) => [key, encode(value)]));

const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/contentJobs?documentId=${encodeURIComponent(config.id)}`;
const existing = await fetch(url.replace(/\?documentId=.*/, `/${encodeURIComponent(config.id)}`), { headers: { Authorization: `Bearer ${token}` } });
if (existing.ok) throw new Error(`Job ${config.id} already exists; refusing to overwrite it.`);
if (existing.status !== 404) throw new Error(`Could not check existing job (${existing.status}): ${await existing.text()}`);

const now = new Date().toISOString();
const job = {
  ...config,
  type: 'semester_full_draft_generation',
  pipelineVersion: 3,
  status: 'queued',
  cursor: { stage: 'outlines', courseIndex: 0, offset: 0 },
  publicationEnabled: false,
  ownerReviewGate: 'semester_complete',
  creditGuard: { consumedUsd: 0, semesterCapUsd: 5, maxBatchUsd: 1.5, stopAtGlobalPercent: 90 },
  richMediaPolicy: {
    requiredPerLesson: { min: 2, max: 4 },
    allowed: ['diagram', 'flowchart', 'comparison_table', 'timeline', 'concept_map', 'data_chart'],
    altTextRequired: true,
    clinicalReviewRequired: true
  },
  leaseExpiresAt: null,
  createdAt: now,
  updatedAt: now
};

const response = await fetch(url, {
  method: 'POST',
  headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
  body: JSON.stringify({ fields: encodeFields(job) })
});
if (!response.ok) throw new Error(`Firestore job creation failed (${response.status}): ${await response.text()}`);
console.log(JSON.stringify({ jobId: config.id, status: job.status, semester: job.semester, courses: job.courses.length, itemTarget: job.inventory.reduce((sum, item) => sum + item.lessons + item.mcqs + item.flashcards + item.written + item.course_tests, 2), semesterCapUsd: job.creditGuard.semesterCapUsd }, null, 2));
