# HAMRIQ final approved feature readiness

Status: functional completion batch in progress for one-deploy testing.

## Included feature layers

- Core CRM, lead source capture, customer/job context, property memory, next actions.
- Hammy action capture: match/create customer, save note, create follow-up, duplicate prevention.
- Prospecting: door hanger outcomes, rep routes, storm campaigns, neighbor opportunities, yard signs.
- Inspection and photo workflow: full-elevation proof checklist, collateral/splatter/soft metals, scope drafts, measurement fallback path.
- Sales: Good/Better/Best estimate, presentation notes, contract-review handoff, product-selection handoff.
- Claims: carrier timeline, adjuster prep, gap finder, supplement builder, packet manifest, depreciation recovery.
- Homeowner experience: messages, referrals, reviews, portal, visible status path.
- Production: material orders, delivery check, permits, crew schedule, weather holds, readiness, warranty.
- Manager controls: approvals, price book, job costing, invoices/A/R, commissions, campaign ROI, reports.
- Systems: integrations setup, provider account references, AI setup, route optimization placeholder, import/export/backup anchors, offline warning, smoke-test checklist.
- Remaining approved anchors: commercial workflow, people/payroll, collaboration/calendar, migration, payments/financing, suppliers, reviews/marketing, system health.

## Deliberate boundaries

- Provider-backed features do not pretend to be live until provider credentials/subscriptions are connected.
- AI photo analysis does not fabricate hail damage; it stays setup-gated until server key/model and analysis provider are live.
- Payments, financing, SMS/email, QuickBooks, supplier ordering, HailTrace/Hail Recon, EagleView/Hover require provider setup.
- Consequential sends, pricing, supplements, contracts, payments, and approvals stay human-reviewed.

## One deploy rule

Deploy only after the completion batch is declared ready. Then run the in-app one-deploy QA checklist from Today or Reports.