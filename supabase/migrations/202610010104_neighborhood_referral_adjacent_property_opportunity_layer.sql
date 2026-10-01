-- HAMRIQ migration 202610010104
-- Neighborhood referral / adjacent-property opportunity layer.
-- Creates job/prospecting-linked neighbor referral opportunities, adjacent-property interest capture,
-- shared storm-area links, follow-up tasks, rep credit, manager review, and activity audit events.
-- Live Supabase database is the source of truth for the full applied DDL/RLS/policies.

-- Tables created live:
-- neighborhood_referral_opportunities_deep
-- adjacent_property_interest_capture_deep
-- shared_storm_area_links_deep
-- neighbor_referral_followup_tasks_deep
-- neighborhood_referral_rep_credit_deep
-- neighborhood_referral_manager_review_deep
-- neighborhood_referral_activity_events_deep

-- Security:
-- RLS enabled on all tables.
-- Managers control review, credit approval, storm-area validation, and company-wide visibility.
-- Reps can create and update their own referral/interest/follow-up records.
-- Company users can view permitted neighborhood referral opportunity data.
