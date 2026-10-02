# Estimate and supplement execution — October 2, 2026

Implemented:
- Selected-job estimate persistence replacing disconnected calculator.
- Company price-book codes; no fabricated default measurements/prices.
- Measurement-derived quantities, waste, manual quantities, and package/scope metadata.
- Carrier comparison against saved estimate using codes, quantities and unit prices.
- Malformed/duplicate carrier rows blocked; unmatched codes require mapping.
- Supplement draft retains estimate ID/version, comparison, evidence and justification.
- Both drafts require existing manager review; no outbound sending.
- Unsaved inputs isolated by job within the page session.

Validation:
- Five model regression tests pass.
- Rolled-back database test confirms server recalculation (33.6 x 125 = 4200), saved metadata and pending_approval for both records.
- Authenticated live screen verified responsive.

Remaining:
- Verified measurement/provider ingestion and automated scope selection.
- Carrier PDF OCR, code/unit mapping, citations and attachment validation.
- Server enforcement of supplemental source-version relationships; sent/response/revision lifecycle.
- Unified claim PDF, approved delivery and contract/e-sign.
- Company price book currently has no items; owner/manager must supply real company pricing.
