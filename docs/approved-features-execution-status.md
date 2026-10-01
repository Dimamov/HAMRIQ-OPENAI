# HAMRIQ approved feature execution status

Last updated: 2026-09-30, America/Detroit.

This document tracks the approved HAMRIQ feature groups that have been converted into backend/database foundation work. It does not mean every UI screen is finished. It means the product decision has been accepted and the implementation path is now anchored in the repo and Supabase.

## Execution status summary

The connected Supabase project now includes an `approved_feature_registry` table. Each company can track approved feature groups with:

- implementation status
- implementation layer: database, API, UI, external integration, documentation, or mixed
- whether AI training/data is required
- whether an outside subscription is required
- whether manager control is required
- notes explaining the operational constraint

## Registered approved feature groups

| Key | Category | Title | Current status | Notes |
|---|---:|---|---|---|
| `lead_source_creation` | CRM | Lead source at lead creation | Foundation created | Reps can mark lead source when creating a lead. |
| `door_hanger_outcome` | Prospecting | Door Hanger Placed outcome | Foundation created | Prospecting visits support door hanger tracking. |
| `rep_routes` | Routing | Rep-created routes and route stops | Foundation created | Routes and route stops exist; optimization logic can build on these records. |
| `storm_data_integrations` | Storm Data | HailTrace / Hail Recon integration slot | External integration pending | Additional subscription required. Contact HAMRIQ for information. |
| `ai_performance_insights` | AI | AI performance insights notice | UI pending | AI requires training/data; better and more data improves results. |
| `measurement_provider_fallback` | Measurements | EagleView / Hover measurement fallback | Manager setup required | Internal measurement first. External provider fallback requires manager setup/approval. |
| `manager_pricing` | Pricing | Manager-controlled pricing | Foundation created | Reps cannot change master pricing. |
| `review_funnel` | Reviews | Internal rating then public review links | Foundation created | 4-5 star internal ratings can trigger public review links. |
| `approval_center` | Approvals | Manager approval center | Foundation created | Central queue for pricing, measurements, supplements, material orders, AI changes, etc. |
| `production_control` | Production | Production scheduling and live controls | Foundation created | Production plans, stages, issues, material delivery verification, and controls exist. |
| `billing_finance` | Billing | Manager-only billing and finance layer | Foundation created | Invoices, payments, commissions, job costing, and compliance foundations exist. |
| `photo_ai_workflow` | Inspection | AI photo quality/damage workflow | Foundation created | Photo analysis, inspection reviews, completeness checks, and additional structures exist. |
| `hammy_voice_capture` | Hammy | Hammy voice/capture workflow | Foundation created | Hammy capture, frequent questions, and lead-detail foundations exist. |
| `commercial_workflow` | Commercial | Commercial roofing workflow | Foundation created | Commercial bid, RFI/submittal, progress billing, retainage, and closeout foundations exist. |
| `people_payroll` | People | People, performance, payroll and recruiting layer | Foundation created | Training, reviews, payroll exports, reimbursements, time, mileage, and applicants exist. |
| `collaboration_calendar` | Operations | Collaboration, scheduling, announcements and tasks | Foundation created | Tasks, calendar, availability, team chat, announcements, and notifications exist. |
| `marketing_growth` | Marketing | Campaign, referral, QR, reputation and ROI layer | Foundation created | Campaign, QR, lead capture, referrals, reputation, and ROI foundations exist. |
| `backup_system_health` | System | Backup, recovery and system health layer | Foundation created | Backup/recovery and system health event foundations exist. |

## Important implementation rules preserved

- Manager/admin access controls company-wide settings, pricing, approvals, exports, financials, and external integrations.
- Reps see their own assigned work unless manager permissions say otherwise.
- External-data features must show: **Additional subscription required. Contact HAMRIQ for information.**
- AI training/data features must clearly state that AI requires training and improves with more company data.
- AI can suggest/draft/summarize, but consequential sends, approvals, pricing changes, supplements, payments, and legal/contract changes require human approval.
- Measurement starts internal. EagleView/Hover are manager-connected fallbacks if HAMRIQ internal measurement is not accurate enough.
- Reps can request measurement orders; manager approval is default, with manager option to approve all.
- Pricing is manager-controlled. Reps cannot change master pricing.
- Billing is manager-only unless an explicit permission says otherwise.

## Next build pass

The next execution pass should focus on app/UI surfaces that use these tables:

1. Manager Approval Center
2. Rep Pipeline / Personal Command Center
3. Prospecting + Door Hanger workflow
4. Inspection structures + collateral/splatter capture
5. Production Control dashboard
6. Billing manager dashboard
7. Hammy command/capture experience
8. Integrations setup screens with subscription notices
