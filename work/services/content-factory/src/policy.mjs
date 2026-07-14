export const safetySensitiveRisks = new Set([
  'clinical',
  'pharmacology',
  'calculation',
  'emergency',
  'patient_safety',
]);

export function requiresOwnerApproval(item) {
  return safetySensitiveRisks.has(item.risk);
}

export function canPublish(item) {
  if (item.reviewState !== 'approved') return false;
  if (!Array.isArray(item.sourceIds) || item.sourceIds.length === 0) return false;
  const review = item.automatedReview ?? {};
  if (review.generatorVerifierAgreement !== true) return false;
  if (review.citationsValid !== true) return false;
  if (review.duplicateScore != null && review.duplicateScore >= 0.9) return false;
  if (requiresOwnerApproval(item) && item.ownerApproval?.approved !== true) return false;
  return true;
}

export function validateItem(item) {
  const errors = [];
  const required = ['id', 'curriculumVersion', 'semester', 'courseId', 'learningOutcomeIds', 'contentType', 'body', 'difficulty', 'sourceIds', 'model', 'promptVersion', 'risk', 'reviewState', 'revision', 'createdAt'];
  for (const key of required) if (item[key] == null) errors.push(`missing:${key}`);
  if (!Number.isInteger(item.semester) || item.semester < 1 || item.semester > 8) errors.push('invalid:semester');
  if (!Array.isArray(item.learningOutcomeIds) || item.learningOutcomeIds.length === 0) errors.push('invalid:learningOutcomeIds');
  if (!Array.isArray(item.sourceIds) || item.sourceIds.length === 0) errors.push('invalid:sourceIds');
  if (item.contentType === 'mcq') {
    const { options, correctIndex, rationales } = item.body ?? {};
    if (!Array.isArray(options) || options.length !== 4) errors.push('invalid:mcq.options');
    if (!Number.isInteger(correctIndex) || correctIndex < 0 || correctIndex > 3) errors.push('invalid:mcq.correctIndex');
    if (!Array.isArray(rationales) || rationales.length !== 4) errors.push('invalid:mcq.rationales');
  }
  return { valid: errors.length === 0, errors };
}
