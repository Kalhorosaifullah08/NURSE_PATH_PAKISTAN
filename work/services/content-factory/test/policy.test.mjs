import test from 'node:test';
import assert from 'node:assert/strict';
import { buildSemesterPackage } from '../src/package-builder.mjs';
import { canPublish, requiresOwnerApproval, validateItem } from '../src/policy.mjs';

function approvedItem(overrides = {}) {
  return {
    id: 'lesson-1', curriculumVersion: 'hec-bsn-2024', semester: 1, courseId: 's1-fon',
    learningOutcomeIds: ['lo-1'], contentType: 'lesson', body: { title: 'Sample' }, difficulty: 'foundation',
    sourceIds: ['who-1'], model: 'configurable-flash', promptVersion: 'v1', risk: 'general',
    reviewState: 'approved', revision: 1, createdAt: '2026-07-14T00:00:00Z',
    automatedReview: { generatorVerifierAgreement: true, citationsValid: true, duplicateScore: 0.1 },
    ...overrides,
  };
}

test('clinical material requires owner approval', () => {
  const item = approvedItem({ risk: 'clinical' });
  assert.equal(requiresOwnerApproval(item), true);
  assert.equal(canPublish(item), false);
  assert.equal(canPublish({ ...item, ownerApproval: { approved: true, approvedBy: 'owner' } }), true);
});

test('automated disagreement prevents publication', () => {
  const item = approvedItem({ automatedReview: { generatorVerifierAgreement: false, citationsValid: true, duplicateScore: 0 } });
  assert.equal(canPublish(item), false);
});

test('package builder returns deterministic item ordering and checksum', () => {
  const first = approvedItem({ id: 'b' });
  const second = approvedItem({ id: 'a' });
  const built = buildSemesterPackage({ semester: 1, curriculumVersion: 'hec-bsn-2024', packageVersion: '0.1.0', items: [first, second] });
  assert.deepEqual(built.payload.items.map((item) => item.id), ['a', 'b']);
  assert.match(built.manifest.sha256, /^[a-f0-9]{64}$/);
});

test('malformed MCQ is rejected', () => {
  const item = approvedItem({ contentType: 'mcq', body: { options: ['A'], correctIndex: 5, rationales: [] } });
  assert.equal(validateItem(item).valid, false);
});
