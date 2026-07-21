export function failureStateFor(error, previous = {}) {
  const message = error?.message ?? String(error);
  const structuredOutputFailure = error?.code === 'VERTEX_INVALID_STRUCTURED_JSON';
  const repeated = previous.lastError === message;
  const consecutiveFailures = repeated ? Number(previous.consecutiveFailures ?? 1) + 1 : 1;
  const mustStop = structuredOutputFailure || consecutiveFailures >= 2;
  return {
    status: mustStop ? 'stopped' : 'queued',
    leaseExpiresAt: null,
    lastError: message,
    errorCode: error?.code ?? 'WORKER_FAILURE',
    consecutiveFailures,
    ...(mustStop ? { stoppedReason: structuredOutputFailure ? 'vertex_structured_output_invalid' : 'repeated_identical_failure' } : {}),
  };
}
