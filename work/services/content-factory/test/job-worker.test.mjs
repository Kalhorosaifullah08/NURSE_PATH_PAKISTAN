import test from 'node:test';
import assert from 'node:assert/strict';
import { beginNextStage, recordWorkerUsage, reviewGeneratedItem } from '../src/job-worker.mjs';
import { createSemesterJob } from '../src/semester-job.mjs';

function createJob() {
  return createSemesterJob({
    semester: 1,
    curriculumVersion: 'HEC-2024',
    sourceLibraryVersion: '2026-07-14',
    requestedBy: 'owner',
    courses: [{ id: 'foundations', title: 'Foundations', learningOutcomes: [{ id: 'lo-1' }], sourceIds: ['hec-2024'] }],
  });
}

test('worker starts the next resumable stage', () => {
  const active = beginNextStage(createJob());
  assert.equal(active.status, 'running');
  assert.equal(active.stages[0].status, 'running');
});

test('unsafe material is routed to owner review', () => {
  const result = reviewGeneratedItem({
    id: 'item-1', curriculumVersion: 'HEC-2024', semester: 1, courseId: 'foundations',
    learningOutcomeIds: ['lo-1'], contentType: 'lesson', body: { text: 'draft' }, difficulty: 'basic',
    sourceIds: ['hec-2024'], model: 'gemini-flash', promptVersion: 'v1', risk: 'clinical',
    reviewState: 'draft', revision: 1, createdAt: '2026-07-14T00:00:00.000Z',
    automatedReview: { generatorVerifierAgreement: true, citationsValid: true, duplicateScore: 0 },
    ownerApproval: { approved: false },
  });
  assert.equal(result.awaitingOwnerApproval, true);
  assert.equal(result.item.reviewState, 'awaiting_owner_review');
});

test('worker stops rather than crossing the credit limit', () => {
  const job = createJob();
  job.creditGuard.semesterCapUsd = 1;
  const result = recordWorkerUsage(job, { estimatedUsd: 2 }, 'gemini-flash');
  assert.equal(result.allowed, false);
  assert.equal(result.job.status, 'stopped');
});
