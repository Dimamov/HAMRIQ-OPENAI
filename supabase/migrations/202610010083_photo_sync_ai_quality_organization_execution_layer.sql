-- HAMRIQ photo sync / AI photo quality / automatic photo organization execution layer
-- Live database migration applied via Supabase.
-- Covers protected upload batches, AI quality scoring, AI tagging, damage/feature findings,
-- required-shot coverage, upload retry/protection, manager review, and audit events.

create table if not exists public.photo_upload_batches_exec_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  contact_id uuid references public.contacts(id) on delete set null,
  uploaded_by uuid not null default auth.uid(),
  batch_label text not null default 'Field photo upload',
  capture_area text not null default 'general',
  upload_status text not null default 'draft',
  total_photos integer not null default 0,
  uploaded_photos integer not null default 0,
  failed_photos integer not null default 0,
  storage_manifest jsonb not null default '[]'::jsonb,
  device_context jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.photo_quality_score_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  upload_batch_id uuid references public.photo_upload_batches_exec_deep(id) on delete cascade,
  photo_reference text not null,
  quality_status text not null default 'pending',
  blur_score numeric(6,3),
  exposure_score numeric(6,3),
  angle_score numeric(6,3),
  distance_score numeric(6,3),
  ai_summary text not null default '',
  retake_reason text not null default '',
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.photo_ai_tagging_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  upload_batch_id uuid references public.photo_upload_batches_exec_deep(id) on delete cascade,
  photo_reference text not null,
  tagging_status text not null default 'pending',
  detected_side text not null default 'unknown',
  detected_categories jsonb not null default '[]'::jsonb,
  suggested_tags jsonb not null default '[]'::jsonb,
  confidence numeric(6,3),
  manager_notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.photo_damage_feature_findings_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  upload_batch_id uuid references public.photo_upload_batches_exec_deep(id) on delete cascade,
  photo_reference text not null,
  finding_type text not null default 'hail_damage',
  side_of_house text not null default 'unknown',
  severity text not null default 'unknown',
  confidence numeric(6,3),
  bounding_data jsonb not null default '{}'::jsonb,
  ai_notes text not null default '',
  manager_review_status text not null default 'pending',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.required_photo_coverage_checks_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  inspection_structure_id uuid,
  check_status text not null default 'pending',
  required_shots jsonb not null default '[]'::jsonb,
  captured_shots jsonb not null default '[]'::jsonb,
  missing_shots jsonb not null default '[]'::jsonb,
  waiver_reason text not null default '',
  completed_by uuid,
  completed_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.photo_upload_protection_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  upload_batch_id uuid references public.photo_upload_batches_exec_deep(id) on delete cascade,
  event_type text not null default 'queued',
  photo_reference text,
  event_status text not null default 'open',
  checksum text,
  retry_count integer not null default 0,
  event_payload jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.photo_manager_review_queue_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  related_photo_reference text not null,
  review_type text not null default 'quality',
  priority text not null default 'normal',
  review_status text not null default 'open',
  assigned_manager_id uuid,
  review_notes text not null default '',
  source_payload jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.photo_sync_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  actor_id uuid not null default auth.uid(),
  event_type text not null,
  event_summary text not null default '',
  related_record_table text,
  related_record_id uuid,
  event_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- RLS and policy layer applied in live Supabase migration.
-- Managers control AI findings/reviews; users control their own upload batches and photo sync activity.
