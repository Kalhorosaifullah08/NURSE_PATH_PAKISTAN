import http from 'node:http';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { beginNextStage } from './job-worker.mjs';

initializeApp({ credential: applicationDefault() });
const db = getFirestore();
const port = Number(process.env.PORT ?? 8080);

function reply(res, status, body) {
  res.writeHead(status, { 'content-type': 'application/json' });
  res.end(JSON.stringify(body));
}

async function claimOneJob() {
  const candidates = await db.collection('contentJobs').where('status', 'in', ['queued', 'running']).limit(10).get();
  for (const document of candidates.docs) {
    const claimed = await db.runTransaction(async (transaction) => {
      const latest = await transaction.get(document.ref);
      if (!latest.exists) return null;
      const job = latest.data();
      if (!['queued', 'running'].includes(job.status)) return null;
      const leasedUntil = job.leaseExpiresAt?.toDate?.();
      if (leasedUntil && leasedUntil > new Date()) return null;
      const next = beginNextStage(job);
      transaction.set(document.ref, {
        ...next,
        leaseExpiresAt: new Date(Date.now() + 4 * 60 * 1000),
        updatedAt: new Date(),
      }, { merge: true });
      return { id: latest.id, ...next };
    });
    if (claimed) return claimed;
  }
  return null;
}

async function processJob() {
  const job = await claimOneJob();
  if (!job) return { status: 'idle' };
  const hasApprovedSources = job.coursePlans?.every((course) => Array.isArray(course.sourceIds) && course.sourceIds.length > 0);
  if (!hasApprovedSources) {
    await db.collection('contentJobs').doc(job.id).set({
      status: 'blocked_source_import',
      blockedReason: 'Every Semester 1 course needs approved tracked sources before Vertex generation.',
      leaseExpiresAt: null,
      updatedAt: new Date(),
    }, { merge: true });
    return { jobId: job.id, status: 'blocked_source_import' };
  }
  await db.collection('contentJobs').doc(job.id).set({
    status: 'awaiting_generator_implementation',
    blockedReason: 'Vertex draft generation is deliberately disabled until the source corpus is approved.',
    leaseExpiresAt: null,
    updatedAt: new Date(),
  }, { merge: true });
  return { jobId: job.id, status: 'awaiting_generator_implementation' };
}

http.createServer(async (req, res) => {
  if (req.method === 'GET' && req.url === '/healthz') return reply(res, 200, { service: 'nursepath-content-worker', status: 'healthy' });
  if (req.method === 'POST' && req.url === '/run') {
    try { return reply(res, 200, await processJob()); }
    catch (error) { console.error(error); return reply(res, 500, { error: 'worker_failure' }); }
  }
  return reply(res, 404, { error: 'not_found' });
}).listen(port, () => console.log(`NursePath worker listening on ${port}`));
