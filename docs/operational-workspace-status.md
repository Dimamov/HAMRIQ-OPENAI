# Operational workspace — October 1, 2026

The app now shares a persistent workflow engine between the fictional-data demo and the authenticated development workspace. Live records use Supabase with company/job isolation, manager financial controls, owner branding controls, immutable actor attribution, version checking, and server-authoritative estimate prices. Existing company access mode and login provisioning remain in force.

## Working app workflows

- Lead creation with required source and manager assignment; rep-created prospects are assigned to that rep.
- Customer cards, job stage changes, Property Memory notes, communication records and timestamped workflow histories.
- Guided inspection checklist by structure and elevation, private photo uploads with damage/location captions, checklist-based completeness coach, scope drafts, and measurement requests.
- Good/Better/Best packages priced against Company Price Book entries on the server; manager review invalidated after any edit; approved package presentation and printable export.
- Claim milestones, deadline follow-ups, carrier line-item gap calculations, adjuster preparation, supplement drafts and claim packet manifests.
- Digital business/contact cards, yard-sign records, neighbor opportunities, storm campaigns, ordered rep route stops, door-hanger outcomes, competitor notes, Deal at Risk and Manager Save Desk.
- Homeowner message history, referral/reward records, review requests and internal ratings, plus configured public-review links.
- Dedicated production workspace: material order requests, delivery comparison and mismatch warnings, permit status, crew-overlap warnings, weather holds, readiness checks, warranty records.
- Manager financials: job costing/profit, invoice balances/A/R aging, commission calculations, campaign spend and lead-source ROI, rep scorecards, conversion and forecast reports, CSV export.
- Revocable customer bearer links with a 30-day expiry; curated status and approved proposal data only. No internal notes, contacts, costs, claim numbers or private photos.
- Hourly server automation prepares idempotent claim/depreciation/warranty follow-up drafts. Completing a job prepares referral/review drafts. These do not send messages.
- Hammy captures browser speech into a reviewed note, summarizes saved job records, suggests next steps, and offers an authenticated server AI endpoint with private evidence access and request limits.

## Connections still required before provider-backed features operate

- Actual AI photo inference requires secure server `OPENAI_API_KEY` and an explicitly configured `OPENAI_MODEL`. No key is embedded in frontend files. Until configured, the app reports that AI is unavailable; it never fabricates analysis.
- Native automated roof measurements and EagleView/Hover ordering need actual measurement services/accounts. The app records requests and manager approvals; it does not claim a validated measurement or provider order.
- HailTrace/Hail Recon need subscriptions/API connections. Storm Mode currently records campaigns and area instructions; it does not import live hail data.
- QuickBooks synchronization, supplier ordering, SMS/email delivery, financing and electronic payments need provider credentials and provider-specific adapters. Financing/payment portal links work when a manager configures HTTPS URLs; tracking a request does not dispatch it or record a real payment.
- Neighbor opportunities are saved/manual records, not a completed geospatial radar service. Routes retain entered stop order; automatic route optimization remains pending.
- Packet export includes reviewed content and evidence references. Uploaded documents must be attached separately; carrier PDF extraction is not implemented.
- Full offline synchronization, automatic photo quality scoring, and custom granular team-role provisioning remain pending. Current authorization uses the existing owner/manager/rep model; manager views include production, billing and marketing.

## Verification

- 14 Node tests passed: gaps, readiness, delivery mismatch, crew overlap, Detroit due dates, alternative-package forecast deduplication, validation, persistence and approval lifecycle.
- Transactional database tests passed: rep job isolation, manager-only financials, no direct mutation bypass, server price calculation, no rep self-approval, stale-version protection, approval invalidation, curated portal data and idempotent automation. Fixtures rolled back.
- Anonymous execution was revoked for two pre-existing inspection RPCs. Existing authenticated definer notices and the existing leaked-password-protection warning remain outside this change.
