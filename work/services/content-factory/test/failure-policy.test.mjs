import test from 'node:test';
import assert from 'node:assert/strict';
import { failureStateFor } from '../src/failure-policy.mjs';

test('invalid Vertex structured output stops immediately', () => {
  const error = Object.assign(new Error('Vertex returned invalid structured JSON'), { code: 'VERTEX_INVALID_STRUCTURED_JSON' });
  const state = failureStateFor(error);
  assert.equal(state.status, 'stopped');
  assert.equal(state.stoppedReason, 'vertex_structured_output_invalid');
  assert.equal(state.consecutiveFailures, 1);
});

test('a generic first failure can retry once', () => {
  const state = failureStateFor(new Error('temporary failure'));
  assert.equal(state.status, 'queued');
  assert.equal(state.consecutiveFailures, 1);
});

test('a repeated identical failure stops instead of spending again', () => {
  const state = failureStateFor(new Error('temporary failure'), { lastError: 'temporary failure', consecutiveFailures: 1 });
  assert.equal(state.status, 'stopped');
  assert.equal(state.stoppedReason, 'repeated_identical_failure');
  assert.equal(state.consecutiveFailures, 2);
});
