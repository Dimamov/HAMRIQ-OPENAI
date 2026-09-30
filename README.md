# HAMRIQ-OPENAI

HAMRIQ mobile-first roofing app — build in progress.

## Connected Supabase backend

Project: `baxgnpnfpzashcgiibwg`, in the HamrIQ organization.

The foundation migration is applied. The company defaults to owner-only access. When team access is enabled later, managers can access company data and reps can access only their assigned records and files. All 18 public tables have row-level security. The job-files bucket is private.

Supabase dashboard membership is not an app login. A confirmed Supabase Auth user must be provisioned into the company's users table. The owner provisioning trigger binds only the company's configured owner email; it never trusts client-supplied role metadata.

`src/lib/config.json` contains the **public publishable API key**, not an administrative credential. Never add service-role keys or AI keys to frontend code.

## Rules

- Measurement API awaits integration. No browser client can write or edit measurements.
- Pricing comes from the owner's uploaded price list. No default or AI-generated prices.
- Message drafts and approvals are separated from delivery; no delivery provider is enabled.
- No adjuster audio or transcription.
- Touch points require an attributed user and timestamp.

## Verification

`tests/access.sql` passed against the connected project. It verifies owner-only restrictions, rep job/contact/file isolation, cross-company isolation, and manager dashboard totals. Test fixtures are rolled back. The Supabase security advisor reported no findings.

The full app interface and remaining workflows are still being implemented; this is not a finished deployment.
