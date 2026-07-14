import { createHash, randomUUID } from 'node:crypto';

const supportedContentTypes = [
  'lesson',
  'mcq',
  'flashcard',
  'written_prompt',
  'course_test',
  'semester_mock',
];

export const defaultCreditGuard = Object.freeze({
  totalCreditUsd: 1000,
  stopAtPercent: 90,
  semesterCapUsd: 110,
});

function stableFingerprint(value) {
  return createHash('sha256').update(JSON.stringify(value)).digest('hex');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

export function createSemesterJob({
  semester,
  curriculumVersion,
  courses,
  sourceLibraryVersion,
  requestedBy,
  creditGuard = defaultCreditGuard,
}) {
  assert(Number.isInteger(semester) && semester >= 1 && semester <= 8, 'semester must be between 1 and 8');
  assert(typeof curriculumVersion === 'string' && curriculumVersion.length > 0, 'curriculumVersion is required');
  assert(Array.isArray(courses) && courses.length > 0, 'at least one course is required');
  assert(typeof sourceLibraryVersion === 'string' && sourceLibraryVersion.length > 0, 'sourceLibraryVersion is required');

  const coursePlans = courses.map((course) => {
    assert(course.id && course.title, 'each course needs id and title');
    assert(Array.isArray(course.learningOutcomes) && course.learningOutcomes.length > 0, `course ${course.id} needs learning outcomes`);
    assert(Array.isArray(course.sourceIds) && course.sourceIds.length > 0, `course ${course.id} needs approved sources`);
    return {
      courseId: course.id,
      title: course.title,
      learningOutcomeIds: course.learningOutcomes.map((outcome) => outcome.id),
      sourceIds: course.sourceIds,
      contentTypes: supportedContentTypes,
      status: 'pending',
    };
  });

  const job = {
    id: `semester-${semester}-${randomUUID()}`,
    type: 'semester_generation',
    semester,
    curriculumVersion,
    sourceLibraryVersion,
    requestedBy,
    status: 'queued',
    createdAt: new Date().toISOString(),
    stages: [
      { id: 'source_validation', status: 'pending' },
      { id: 'outline_generation', status: 'pending' },
      { id: 'content_generation', status: 'pending' },
      { id: 'independent_verification', status: 'pending' },
      { id: 'deterministic_qa', status: 'pending' },
      { id: 'risk_classification', status: 'pending' },
      { id: 'owner_review', status: 'pending' },
      { id: 'package_build', status: 'blocked' },
    ],
    coursePlans,
    creditGuard: {
      ...creditGuard,
      stopAtUsd: Number((creditGuard.totalCreditUsd * creditGuard.stopAtPercent / 100).toFixed(2)),
      consumedUsd: 0,
    },
  };
  return { ...job, fingerprint: stableFingerprint(job) };
}

export function recordUsage(job, { estimatedUsd = 0, inputTokens = 0, outputTokens = 0, model }) {
  assert(job.status === 'queued' || job.status === 'running', 'job is not active');
  assert(Number.isFinite(estimatedUsd) && estimatedUsd >= 0, 'estimatedUsd must be non-negative');
  const nextConsumed = Number((job.creditGuard.consumedUsd + estimatedUsd).toFixed(6));
  if (nextConsumed > job.creditGuard.semesterCapUsd) {
    return { allowed: false, reason: 'semester_budget_cap', nextConsumed };
  }
  if (nextConsumed > job.creditGuard.stopAtUsd) {
    return { allowed: false, reason: 'global_credit_guard', nextConsumed };
  }
  return {
    allowed: true,
    job: {
      ...job,
      status: 'running',
      creditGuard: { ...job.creditGuard, consumedUsd: nextConsumed },
      usage: [...(job.usage ?? []), { estimatedUsd, inputTokens, outputTokens, model, recordedAt: new Date().toISOString() }],
    },
  };
}

export function canBuildPackage(job, items) {
  if (job.status === 'stopped' || job.status === 'failed') return false;
  if (!Array.isArray(items) || items.length === 0) return false;
  return items.every((item) => item.reviewState === 'approved' && item.packageEligible === true);
}
