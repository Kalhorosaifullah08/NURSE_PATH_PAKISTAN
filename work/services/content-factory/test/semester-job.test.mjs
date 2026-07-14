import test from 'node:test';
import assert from 'node:assert/strict';
import { canBuildPackage, createSemesterJob, recordUsage } from '../src/semester-job.mjs';

const course = {
  id: 'sem1-foundations',
  title: 'Foundations of Nursing',
  learningOutcomes: [{ id: 'lo-hand-hygiene' }],
  sourceIds: ['hec-2024', 'who-hand-hygiene'],
};

test('a semester job requires source-backed courses', () => {
  assert.throws(() => createSemesterJob({
    semester: 1,
    curriculumVersion: 'HEC-2024',
    courses: [{ ...course, sourceIds: [] }],
    sourceLibraryVersion: '2026-07-14',
    requestedBy: 'owner',
  }), /approved sources/);
});

test('credit guards stop a semester before it can exceed its cap', () => {
  const job = createSemesterJob({
    semester: 1,
    curriculumVersion: 'HEC-2024',
    courses: [course],
    sourceLibraryVersion: '2026-07-14',
    requestedBy: 'owner',
    creditGuard: { totalCreditUsd: 1000, stopAtPercent: 90, semesterCapUsd: 1 },
  });
  const result = recordUsage(job, { estimatedUsd: 1.01, model: 'gemini-flash' });
  assert.equal(result.allowed, false);
  assert.equal(result.reason, 'semester_budget_cap');
});

test('a package waits for every item to be approved and eligible', () => {
  const job = createSemesterJob({
    semester: 1,
    curriculumVersion: 'HEC-2024',
    courses: [course],
    sourceLibraryVersion: '2026-07-14',
    requestedBy: 'owner',
  });
  assert.equal(canBuildPackage(job, [{ reviewState: 'approved', packageEligible: true }]), true);
  assert.equal(canBuildPackage(job, [{ reviewState: 'draft', packageEligible: true }]), false);
});
