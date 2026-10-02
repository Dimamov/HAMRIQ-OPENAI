# HAMRIQ final one-deploy test plan

Use this after the final GitHub batch is deployed to Cloudflare. Do not redeploy between individual checks unless the app fails to load.

## 1. Startup
- Open `dev.hamriq.app`.
- Confirm the workspace loads.
- Confirm the bottom mobile controls, Workflow button, Hammy button, and Field Command Center appear.

## 2. Hammy action test
Use a fresh name so the result is obvious:

`Jeff Akins asked me to call back tomorrow.`

Expected:
- Existing customer is selected if present; otherwise a lead is created.
- Exactly one Property Memory note is saved.
- Exactly one Next Action is saved.
- No duplicate notes or tasks.

## 3. Sales workflow
From the final operating layer or Workflow launcher:
- New lead
- Follow-up
- Guided inspection
- Scope draft
- Measurement request
- Good / Better / Best estimate
- Presentation notes

Expected:
- Forms open from the shortcut buttons.
- Saved records appear in the active job timeline or saved-record list.
- Manager-review items show as review-needed/pending where applicable.

## 4. Claims workflow
Create/check:
- Claim timeline
- Adjuster prep
- Carrier gap finder
- Supplement draft
- Claim packet

Expected:
- Each item saves to the claim/customer workflow.
- Supplement and packet stay human-reviewed before send/export.

## 5. Homeowner workflow
Create/check:
- Homeowner message draft
- Referral ask
- Review request
- Customer portal link

Expected:
- Internal notes and costs are not exposed through the customer portal.
- Review link only appears when configured and rating threshold allows it.

## 6. Production workflow
Create/check:
- Material order
- Delivery confirmation
- Permit status
- Crew schedule
- Readiness checklist
- Warranty record

Expected:
- Production items save to the job.
- Readiness/checklist records show blockers or completion clearly.

## 7. Manager workflow
Create/check:
- Approval Center
- Measurement request approval path
- Estimate review
- Supplement review
- Material order approval
- Job costing
- Invoice / A/R
- Commission
- Campaign ROI
- Reports
- Provider setup

Expected:
- Manager tools are visible to owner/manager views.
- Financial tools remain manager-only.
- Provider setup uses setup state and account references only; no secrets in the browser.

## 8. Health endpoint
Open `/api/health`.

Expected public response:
- No API key preview.
- No model name disclosure.
- Provider test requires `HAMRIQ_HEALTH_TOKEN`.

Provider test format when the token is configured:

`/api/health?openai=1&token=<HAMRIQ_HEALTH_TOKEN>`

## 9. Export / smoke-test panel
On Today or Reports:
- Use the one-deploy QA checklist.
- Use Export visible page.

Expected:
- A JSON file downloads with visible page text for debugging.

## Final pass/fail rule
Pass only when:
- The app loads.
- Hammy creates one note and one follow-up.
- Core workflow shortcuts open the correct forms.
- Records save and appear in the customer/job context.
- Manager/financial/provider areas are present and restricted by role expectations.
- No redeploy was needed during the test run.
