-- Progressive Inspection Damage Gate Flow Layer
-- Live Supabase source of truth migration: progressive_inspection_damage_gate_flow_layer
-- Purpose: ground-level photos first, then yes/no damage gates that only open matching inspection photo sections when damage exists.

-- Tables created live:
-- progressive_inspection_sessions_deep
-- progressive_inspection_damage_gates_deep
-- progressive_inspection_photo_sections_deep
-- progressive_inspection_photo_records_deep
-- progressive_inspection_gate_templates_deep
-- progressive_inspection_manager_review_deep
-- progressive_inspection_activity_events_deep

-- Supports gates such as:
-- roof_damage, gutter_damage, downspout_damage, window_wrap_damage, siding_damage, soft_metal_damage, other_damage

-- Security:
-- RLS enabled on all tables.
-- Managers control templates/review.
-- Reps can create/update assigned inspection sessions, gates, sections, and photos.
-- Company users can view permitted inspection data.
