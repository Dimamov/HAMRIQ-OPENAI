-- HAMRIQ migration reference: canvasser performance / credit tracking layer
-- Applied live to Supabase project baxgnpnfpzashcgiibwg on 2026-10-01.
-- Live database is the source of truth for this module.

-- Added tables:
-- public.canvasser_performance_snapshots_deep
-- public.canvasser_lead_credit_records_deep
-- public.canvasser_appointment_quality_checks_deep
-- public.canvasser_hot_lead_outcome_records_deep
-- public.canvasser_pairing_performance_deep
-- public.canvasser_manager_scorecards_deep
-- public.canvasser_payout_review_queue_deep
-- public.canvasser_performance_activity_events_deep

-- Purpose:
-- Tracks canvasser production, lead quality, hot lead outcomes, appointment outcomes,
-- canvasser-to-sales-rep pairing results, manager scorecards, and payout-review support.

-- Security:
-- RLS enabled on all tables.
-- Managers control scorecards, payout review, approval, and performance review.
-- Canvassers can create/view their own permitted performance and credit records.
-- Sales reps can update assigned appointment/hot-lead outcome records.
