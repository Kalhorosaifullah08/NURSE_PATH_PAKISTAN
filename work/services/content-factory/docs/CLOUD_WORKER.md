# NursePath Pakistan — persistent Semester worker

The owner creates one `semester_generation` job. The cloud worker, not the owner's laptop, advances it through these stages:

1. Source validation
2. Outline generation
3. Lessons, MCQs, flashcards, written prompts, course tests, and semester mock generation
4. Independent answer verification
5. Deterministic schema, citation, and duplicate checks
6. Risk classification
7. Owner review for clinical, pharmacology, calculation, emergency, and patient-safety content
8. Versioned package build

## Deployment contract

- Firestore collection: `contentJobs/{jobId}` stores the job, its stage history, cost estimates, retry count, and idempotency key.
- Cloud Scheduler invokes a protected Cloud Run endpoint every five minutes. The endpoint claims one eligible job at a time, writes a lease expiry, and records every transition.
- A failed call leaves the source job intact. When its lease expires, the next scheduled invocation retries it. A job stops after three failed attempts and appears in the owner dashboard.
- Cloud Run uses its service account to call Vertex AI; no Vertex token or Gemini key is put in the Flutter app.
- The worker writes generated drafts to Cloud Storage and metadata to Firestore.
- It must stop when the semester cap or 90% global promotional-credit guard is reached. It must never change to a paid model automatically.

## Required cloud actions before the first job

1. Link the NursePath Pakistan project to the intended billing account (Blaze).
2. Verify the US$1,000 GenAI promotional credit applies to this project/billing account.
3. Enable Vertex AI, Firestore, Cloud Run, Cloud Scheduler, Cloud Storage, and Secret Manager APIs.
4. Deploy Firestore rules and create the worker service account with minimum permissions.
5. Enter the verified HEC Semester 1 structure and approved source records.

No job is permitted to use open-web material as an untracked source.
