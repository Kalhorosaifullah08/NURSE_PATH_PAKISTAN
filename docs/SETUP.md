# Setup and safeguards

## Credit confirmation

The billing export inspected on 14 July 2026 showed:

- Trial credit for GenAI App Builder: USD 1,000 remaining; expires 16 June 2027.
- General Google Cloud trial: USD 285.63 remaining; expires 1 September 2026.

Before connecting this repository, confirm eligible SKUs with a low-cost test request. Create billing alerts at 25%, 50%, 75%, 90%, and 95%. The service must stop generation at 90%; billing alerts alone do not cap spending.

## Secrets

- Never store service-account JSON, API keys, billing identifiers, or Firebase admin credentials in the client or repository.
- Use workload identity or environment-provided credentials for server workloads.
- Use separate Firebase/Google Cloud projects for development and production.
- Production publishing and production billing remain disabled during the internal beta.

## Required cloud configuration

1. Create development and production projects.
2. Enable Firebase Authentication, Firestore, Cloud Storage, Cloud Run/Functions, and Vertex AI only after credit eligibility is tested.
3. Register Android application ID `pk.bsnpath.bsn_path_student`.
4. Configure App Check and least-privilege service accounts.
5. Store configurable model names in server environment variables.
6. Configure Play Billing license testers; do not create production offers yet.

## Content release invariant

Items classified clinical, pharmacology, calculation, emergency, or patient safety require an owner approval record. The package builder must refuse any release that violates this invariant.
