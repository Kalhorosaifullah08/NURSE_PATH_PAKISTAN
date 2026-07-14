import { canPublish, requiresOwnerApproval, validateItem } from './policy.mjs';
import { recordUsage } from './semester-job.mjs';

const nextStage = Object.freeze({
  source_validation: 'outline_generation',
  outline_generation: 'content_generation',
  content_generation: 'independent_verification',
  independent_verification: 'deterministic_qa',
  deterministic_qa: 'risk_classification',
  risk_classification: 'owner_review',
  owner_review: 'package_build',
  package_build: null,
});

export function activeStage(job) {
  return job.stages.find((stage) => stage.status === 'running')
    ?? job.stages.find((stage) => stage.status === 'pending')
    ?? null;
}

export function markStage(job, stageId, status, extra = {}) {
  return {
    ...job,
    stages: job.stages.map((stage) => stage.id === stageId
      ? { ...stage, status, updatedAt: new Date().toISOString(), ...extra }
      : stage),
  };
}

export function beginNextStage(job) {
  const stage = activeStage(job);
  if (!stage) return { ...job, status: 'awaiting_owner_or_complete' };
  if (stage.id === 'package_build' && job.stages.some((item) => item.status !== 'completed' && item.id !== 'package_build')) {
    return { ...job, status: 'awaiting_owner_review' };
  }
  return markStage({ ...job, status: 'running' }, stage.id, 'running');
}

export function completeStage(job, stageId, extra = {}) {
  const completed = markStage(job, stageId, 'completed', extra);
  const following = nextStage[stageId];
  if (!following) return { ...completed, status: 'completed' };
  if (following === 'owner_review' && extra.awaitingOwnerApproval === true) {
    return { ...completed, status: 'awaiting_owner_review' };
  }
  return completed;
}

export function reviewGeneratedItem(item) {
  const deterministic = validateItem(item);
  const safetySensitive = requiresOwnerApproval(item);
  const packageEligible = deterministic.valid && canPublish(item);
  return {
    item: {
      ...item,
      automatedReview: { ...(item.automatedReview ?? {}), deterministicValid: deterministic.valid, errors: deterministic.errors },
      reviewState: safetySensitive ? 'awaiting_owner_review' : packageEligible ? 'approved' : 'rejected',
      packageEligible,
    },
    awaitingOwnerApproval: safetySensitive,
  };
}

export function recordWorkerUsage(job, usage, model) {
  const result = recordUsage(job, { ...usage, model });
  if (result.allowed) return result;
  return {
    allowed: false,
    reason: result.reason,
    job: { ...job, status: 'stopped', stoppedReason: result.reason, stoppedAt: new Date().toISOString() },
  };
}
