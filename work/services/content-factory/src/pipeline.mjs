export const stages = ['outlines', 'lessons', 'mcqs', 'flashcards', 'written', 'course_tests', 'semester_mocks'];

export const batchSizes = Object.freeze({ outlines: 1, lessons: 1, mcqs: 10, flashcards: 15, written: 10, course_tests: 1, semester_mocks: 1 });

export function targetsForCourse(course) {
  const high = course.credits >= 3;
  return { lessons: high ? 12 : 8, mcqs: high ? 150 : 100, flashcards: high ? 45 : 30, written: high ? 30 : 20, course_tests: 2 };
}

export function initialCursor(courseIndex = 0) {
  return { stage: 'outlines', courseIndex, offset: courseIndex };
}

export function targetFor(cursor, courses) {
  if (cursor.stage === 'outlines') return courses.length;
  if (cursor.stage === 'semester_mocks') return 2;
  return targetsForCourse(courses[cursor.courseIndex])[cursor.stage];
}

export function advanceCursor(cursor, generatedCount, courses) {
  const currentTarget = targetFor(cursor, courses);
  const nextOffset = cursor.offset + generatedCount;
  if (cursor.stage === 'semester_mocks') {
    return nextOffset >= currentTarget ? null : { ...cursor, offset: nextOffset };
  }
  if (cursor.stage === 'outlines') {
    if (nextOffset < courses.length) return { ...cursor, courseIndex: nextOffset, offset: nextOffset };
    return { stage: 'lessons', courseIndex: 0, offset: 0 };
  }
  if (nextOffset < currentTarget) return { ...cursor, offset: nextOffset };
  if (cursor.courseIndex + 1 < courses.length) return { ...cursor, courseIndex: cursor.courseIndex + 1, offset: 0 };
  const nextStage = stages[stages.indexOf(cursor.stage) + 1];
  return nextStage ? { stage: nextStage, courseIndex: 0, offset: 0 } : null;
}

export function batchCount(cursor, courses) {
  return Math.min(batchSizes[cursor.stage], targetFor(cursor, courses) - cursor.offset);
}

export function riskFor(courseId, contentType) {
  if (['s1-fundamentals-1', 's2-fundamentals-2', 's2-applied-nutrition', 's3-clinical-pharmacology-drug-administration-1', 's3-medical-surgical-nursing-1', 's3-health-assessment-1'].includes(courseId)) return 'patient_safety';
  if (['s1-microbiology', 's1-biochemistry', 's1-anatomy-physiology-1', 's2-anatomy-physiology-2', 's3-pathophysiology-1'].includes(courseId)) return 'clinical_foundation';
  if (contentType === 'semester_mock') return 'mixed';
  return 'academic';
}

export function contentId({ semester = 1, stage, courseId, index }) {
  const singular = { outlines: 'outline', lessons: 'lesson', mcqs: 'mcq', flashcards: 'flashcard', written: 'written', course_tests: 'test', semester_mocks: 'mock' }[stage];
  return `semester-${semester}-${courseId ?? 'all'}-${singular}-${String(index + 1).padStart(3, '0')}`;
}

export function fingerprint(value) {
  return value.toLowerCase().replace(/[^a-z0-9\s]/g, '').replace(/\s+/g, ' ').trim();
}
