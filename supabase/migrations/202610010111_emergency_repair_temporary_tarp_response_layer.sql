-- HAMRIQ emergency repair / temporary tarp response layer
-- Applied live to Supabase project baxgnpnfpzashcgiibwg.
-- Adds emergency storm damage records, tarp/temporary repair requests,
-- dispatch cards, photo proof, homeowner approval, material usage,
-- manager review, and activity audit events.
-- Security: RLS enabled on all tables. Managers control approvals/review/dispatch.
-- Reps can create/update assigned emergency repair work, photos, materials, and events.

-- Live database is source of truth for full DDL and policies.
select '202610010111_emergency_repair_temporary_tarp_response_layer applied' as migration_note;
