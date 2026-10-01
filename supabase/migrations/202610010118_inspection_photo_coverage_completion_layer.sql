-- HAMRIQ inspection photo coverage / completion layer
-- Live Supabase migration source of truth: inspection_photo_coverage_completion_layer
-- Adds required photo rules, per-section completion checks, skipped-section reasons,
-- completion scorecards, missing-photo alerts, manager review, and activity events.

-- Tables created live:
-- public.inspection_photo_requirement_rules_deep
-- public.inspection_section_completion_checks_deep
-- public.inspection_skipped_section_reasons_deep
-- public.inspection_completion_scorecards_deep
-- public.inspection_missing_photo_alerts_deep
-- public.inspection_completion_manager_review_deep
-- public.inspection_completion_activity_events_deep

-- RLS enabled on all tables.
-- Managers control rules and review.
-- Reps can update assigned/permitted completion, skip, alert, and activity records.