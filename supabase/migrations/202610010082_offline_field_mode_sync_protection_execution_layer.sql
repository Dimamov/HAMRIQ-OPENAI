-- HAMRIQ offline field mode / sync protection execution layer
-- Live database migration applied in Supabase project baxgnpnfpzashcgiibwg.

-- Adds offline sessions, local drafts, sync queues, conflict resolution,
-- upload retry records, device cache state, sync-health manager cards,
-- and offline sync activity events.

-- Security model:
-- - Users manage their own offline sessions, drafts, queue items, upload retries, and cache state.
-- - Managers can review conflicts, sync health, and repair/release blocked sync items.
-- - Company-scoped RLS is enabled on every table.
-- - Manager-visible sync health is separated from user-owned local queue state.

-- Tables created live:
-- public.offline_field_sessions_deep
-- public.offline_local_drafts_deep
-- public.offline_sync_queue_deep
-- public.offline_sync_conflict_resolution_deep
-- public.offline_upload_retry_records_deep
-- public.device_cache_state_records_deep
-- public.sync_health_manager_cards_deep
-- public.offline_sync_activity_events_deep
