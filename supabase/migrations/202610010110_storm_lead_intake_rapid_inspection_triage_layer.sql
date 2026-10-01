-- HAMRIQ migration reference: storm lead intake / rapid inspection triage layer
-- Applied live in Supabase project baxgnpnfpzashcgiibwg on 2026-10-01.
-- Live database is source of truth.

-- Added and secured:
-- 1. storm_hot_lead_queue_deep
-- 2. storm_damage_triage_runs_deep
-- 3. storm_inspection_urgency_scores_deep
-- 4. storm_inspection_assignment_routes_deep
-- 5. same_day_storm_inspection_slots_deep
-- 6. storm_triage_manager_review_deep
-- 7. storm_lead_triage_activity_events_deep

-- Purpose:
-- Captures hot storm leads, triages reported damage, scores inspection urgency,
-- routes leads to reps/managers, tracks same-day inspection slots, and records
-- manager review / audit events.
