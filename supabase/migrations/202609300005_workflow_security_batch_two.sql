-- HAMRIQ approved workflow RLS security batch two.
-- Applied live to Supabase project baxgnpnfpzashcgiibwg.

-- This migration enables row-level security for the second approved execution batch.
-- Managers/owners keep company-level visibility where needed. Reps remain limited
-- through existing private.can_job/private.can_contact/private.company_access helpers.

-- The live database contains the expanded policies for:
-- properties, roof_assets, maintenance_agreements, commercial_bids, carrier_adjusters,
-- insurance_document_extractions, carrier_payments, progress_billings, rfis,
-- submittals, punch_items, closeout_packages, production_issues, hidden_conditions,
-- lead_transfers, rep_credit_assignments, and job_profitability_reviews.

-- Policy source of truth is the live Supabase migration history. This file preserves
-- the execution marker in GitHub for reproducibility and audit tracking.
