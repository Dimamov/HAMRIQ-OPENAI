# HAMRIQ-OPENAI

HAMRIQ mobile-first roofing app — build in progress.

## Connected Supabase backend

Project: `baxgnpnfpzashcgiibwg`, in the HamrIQ organization.

The backend foundation is connected and active. The company defaults to owner-only access. When team access is enabled later, managers can access company data and reps can access only their assigned records and files. Public tables use row-level security. The job-files bucket is private.

Supabase dashboard membership is not an app login. A confirmed Supabase Auth user must be provisioned into the company's users table. The owner provisioning trigger binds only the company's configured owner email; it never trusts client-supplied role metadata.

`src/lib/config.json` contains the **public publishable API key**, not an administrative credential. Never add service-role keys or AI keys to frontend code.

## Current execution layer

Approved HAMRIQ feature groups are now tracked in Supabase using `public.approved_feature_registry` and documented in:

- `docs/approved-features-execution-status.md`
- `docs/saved-for-later-feature-queue.md`

The registry records implementation status, whether AI training/data is required, whether an external subscription is required, and whether manager control is required.

## Rules

- Measurement API awaits full integration. No browser client can write or edit final measurements.
- Pricing comes from manager/owner-controlled price lists. No default or AI-generated prices should silently become master pricing.
- Message drafts and approvals are separated from delivery; no delivery provider should send without configured manager approval rules.
- AI requires training/data notices where applicable. More company data should improve results.
- Outside data/providers must show: **Additional subscription required. Contact HAMRIQ for information.**
- No adjuster audio or transcription unless specifically approved later.
- Touch points require an attributed user and timestamp.
- Consequential actions — pricing changes, supplement sending, contracts, payments, approvals, external orders, and legal/compliance actions — require human approval.

## Verification

`tests/access.sql` passed against the connected project earlier. It verifies owner-only restrictions, rep job/contact/file isolation, cross-company isolation, and manager dashboard totals. Test fixtures are rolled back.

The approved feature registry migration was applied and verified with grouped counts across the registered feature categories.

The full app interface and remaining workflows are still being implemented; this is not a finished deployment.
