import test from 'node:test';
import assert from 'node:assert/strict';
import { advanceCursor, batchCount, contentId, initialCursor, riskFor, targetsForCourse } from '../src/pipeline.mjs';

const courses = [{ id: 'a', credits: 2 }, { id: 'b', credits: 3 }];

test('inventory targets scale with course credits', () => {
  assert.deepEqual(targetsForCourse(courses[0]), { lessons: 8, mcqs: 100, flashcards: 30, written: 20, course_tests: 2 });
  assert.equal(targetsForCourse(courses[1]).mcqs, 150);
});

test('outline cursor moves into lessons without a review pause', () => {
  let cursor = initialCursor();
  cursor = advanceCursor(cursor, 1, courses);
  assert.deepEqual(cursor, { stage: 'outlines', courseIndex: 1, offset: 1 });
  cursor = advanceCursor(cursor, 1, courses);
  assert.deepEqual(cursor, { stage: 'lessons', courseIndex: 0, offset: 0 });
});

test('outline migration resumes after completed courses', () => {
  assert.deepEqual(initialCursor(3), { stage: 'outlines', courseIndex: 3, offset: 3 });
});

test('batches stop exactly at inventory target', () => {
  assert.equal(batchCount({ stage: 'mcqs', courseIndex: 0, offset: 95 }, courses), 5);
});

test('clinical foundations are visibly risk tagged', () => {
  assert.equal(riskFor('s1-fundamentals-1', 'lesson'), 'patient_safety');
  assert.equal(riskFor('s1-ict', 'lesson'), 'academic');
});

test('content IDs are deterministic', () => {
  assert.equal(contentId({ stage: 'mcqs', courseId: 'a', index: 8 }), 'semester-1-a-mcq-009');
});
