create table if not exists public.mobile_device_states (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null default auth.uid(),
  device_fingerprint text not null,
  device_label text,
  platform text not null default 'unknown',
  app_version text,
  last_seen_at timestamptz,
  last_sync_started_at timestamptz,
  last_sync_completed_at timestamptz,
  offline_mode_enabled boolean not null default false,
  battery_level numeric,
  network_status text not null default 'unknown',
  sync_health text not null default 'unknown',
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, device_fingerprint)
);

create table if not exists public.offline_sync_conflicts (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null default auth.uid(),
  device_state_id uuid references public.mobile_device_states(id) on delete set null,
  record_table text not null,
  record_id uuid,
  local_payload jsonb not null default '{}'::jsonb,
  server_payload jsonb not null default '{}'::jsonb,
  conflict_type text not null default 'update_conflict',
  resolution_status text not null default 'open',
  resolved_by uuid,
  resolved_at timestamptz,
  resolution_notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.offline_recovery_queue_items (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null default auth.uid(),
  device_state_id uuid references public.mobile_device_states(id) on delete set null,
  job_id uuid references public.jobs(id) on delete set null,
  recovery_type text not null,
  payload jsonb not null default '{}'::jsonb,
  priority integer not null default 50,
  status text not null default 'queued',
  attempts integer not null default 0,
  last_error text,
  queued_at timestamptz not null default now(),
  processed_at timestamptz
);

create table if not exists public.photo_upload_batches_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  created_by uuid not null default auth.uid(),
  device_state_id uuid references public.mobile_device_states(id) on delete set null,
  batch_label text,
  inspection_area text,
  expected_count integer not null default 0,
  uploaded_count integer not null default 0,
  failed_count integer not null default 0,
  status text not null default 'pending',
  started_at timestamptz,
  completed_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.photo_upload_batch_items (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  batch_id uuid not null references public.photo_upload_batches_deep(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  storage_bucket text not null default 'job-files',
  storage_path text,
  file_name text,
  capture_side text,
  marked_damage_types text[] not null default '{}'::text[],
  upload_status text not null default 'pending',
  checksum text,
  error_message text,
  captured_at timestamptz,
  uploaded_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.photo_analysis_requests_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  photo_item_id uuid references public.photo_upload_batch_items(id) on delete cascade,
  requested_by uuid not null default auth.uid(),
  analysis_type text not null default 'hail_damage_check',
  status text not null default 'queued',
  model_provider text,
  confidence numeric,
  human_review_required boolean not null default true,
  reviewed_by uuid,
  reviewed_at timestamptz,
  summary text,
  error_message text,
  requested_at timestamptz not null default now(),
  completed_at timestamptz,
  result_payload jsonb not null default '{}'::jsonb
);

create table if not exists public.photo_analysis_findings (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  analysis_request_id uuid not null references public.photo_analysis_requests_deep(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  finding_type text not null,
  severity text not null default 'unknown',
  confidence numeric,
  bounding_box jsonb not null default '{}'::jsonb,
  finding_notes text,
  accepted_by_human boolean,
  human_notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.photo_tagging_results (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  photo_item_id uuid not null references public.photo_upload_batch_items(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  tags text[] not null default '{}'::text[],
  detected_side text,
  detected_components text[] not null default '{}'::text[],
  suggested_folder text,
  quality_score numeric,
  needs_retake boolean not null default false,
  retake_reason text,
  generated_by text not null default 'ai',
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists mobile_device_states_company_user_idx on public.mobile_device_states(company_id, user_id);
create index if not exists offline_sync_conflicts_company_status_idx on public.offline_sync_conflicts(company_id, resolution_status);
create index if not exists offline_recovery_queue_company_status_idx on public.offline_recovery_queue_items(company_id, status, priority);
create index if not exists photo_upload_batches_company_job_idx on public.photo_upload_batches_deep(company_id, job_id);
create index if not exists photo_upload_items_batch_idx on public.photo_upload_batch_items(batch_id);
create index if not exists photo_analysis_requests_company_job_idx on public.photo_analysis_requests_deep(company_id, job_id, status);
create index if not exists photo_analysis_findings_request_idx on public.photo_analysis_findings(analysis_request_id);
create index if not exists photo_tagging_results_photo_idx on public.photo_tagging_results(photo_item_id);

alter table public.mobile_device_states enable row level security;
alter table public.offline_sync_conflicts enable row level security;
alter table public.offline_recovery_queue_items enable row level security;
alter table public.photo_upload_batches_deep enable row level security;
alter table public.photo_upload_batch_items enable row level security;
alter table public.photo_analysis_requests_deep enable row level security;
alter table public.photo_analysis_findings enable row level security;
alter table public.photo_tagging_results enable row level security;

revoke all on public.mobile_device_states from anon, authenticated;
revoke all on public.offline_sync_conflicts from anon, authenticated;
revoke all on public.offline_recovery_queue_items from anon, authenticated;
revoke all on public.photo_upload_batches_deep from anon, authenticated;
revoke all on public.photo_upload_batch_items from anon, authenticated;
revoke all on public.photo_analysis_requests_deep from anon, authenticated;
revoke all on public.photo_analysis_findings from anon, authenticated;
revoke all on public.photo_tagging_results from anon, authenticated;

grant select, insert, update on public.mobile_device_states to authenticated;
grant select, insert, update on public.offline_sync_conflicts to authenticated;
grant select, insert, update on public.offline_recovery_queue_items to authenticated;
grant select, insert, update on public.photo_upload_batches_deep to authenticated;
grant select, insert, update on public.photo_upload_batch_items to authenticated;
grant select, insert, update on public.photo_analysis_requests_deep to authenticated;
grant select, insert, update on public.photo_analysis_findings to authenticated;
grant select, insert, update on public.photo_tagging_results to authenticated;

drop policy if exists mobile_device_states_access on public.mobile_device_states;
create policy mobile_device_states_access on public.mobile_device_states
  for all to authenticated
  using (private.company_access(company_id) and (private.is_manager(company_id) or user_id = auth.uid()))
  with check (private.company_access(company_id) and (private.is_manager(company_id) or user_id = auth.uid()));

drop policy if exists offline_sync_conflicts_access on public.offline_sync_conflicts;
create policy offline_sync_conflicts_access on public.offline_sync_conflicts
  for all to authenticated
  using (private.company_access(company_id) and (private.is_manager(company_id) or user_id = auth.uid()))
  with check (private.company_access(company_id) and (private.is_manager(company_id) or user_id = auth.uid()));

drop policy if exists offline_recovery_queue_items_access on public.offline_recovery_queue_items;
create policy offline_recovery_queue_items_access on public.offline_recovery_queue_items
  for all to authenticated
  using (private.company_access(company_id) and (private.is_manager(company_id) or user_id = auth.uid() or private.can_job(company_id, job_id)))
  with check (private.company_access(company_id) and (private.is_manager(company_id) or user_id = auth.uid() or private.can_job(company_id, job_id)));

drop policy if exists photo_upload_batches_deep_access on public.photo_upload_batches_deep;
create policy photo_upload_batches_deep_access on public.photo_upload_batches_deep
  for all to authenticated
  using (private.company_access(company_id) and (private.is_manager(company_id) or private.can_job(company_id, job_id)))
  with check (private.company_access(company_id) and (private.is_manager(company_id) or private.can_job(company_id, job_id)));

drop policy if exists photo_upload_batch_items_access on public.photo_upload_batch_items;
create policy photo_upload_batch_items_access on public.photo_upload_batch_items
  for all to authenticated
  using (private.company_access(company_id) and (private.is_manager(company_id) or private.can_job(company_id, job_id)))
  with check (private.company_access(company_id) and (private.is_manager(company_id) or private.can_job(company_id, job_id)));

drop policy if exists photo_analysis_requests_deep_access on public.photo_analysis_requests_deep;
create policy photo_analysis_requests_deep_access on public.photo_analysis_requests_deep
  for all to authenticated
  using (private.company_access(company_id) and (private.is_manager(company_id) or private.can_job(company_id, job_id)))
  with check (private.company_access(company_id) and (private.is_manager(company_id) or private.can_job(company_id, job_id)));

drop policy if exists photo_analysis_findings_access on public.photo_analysis_findings;
create policy photo_analysis_findings_access on public.photo_analysis_findings
  for all to authenticated
  using (private.company_access(company_id) and (private.is_manager(company_id) or private.can_job(company_id, job_id)))
  with check (private.company_access(company_id) and (private.is_manager(company_id) or private.can_job(company_id, job_id)));

drop policy if exists photo_tagging_results_access on public.photo_tagging_results;
create policy photo_tagging_results_access on public.photo_tagging_results
  for all to authenticated
  using (private.company_access(company_id) and (private.is_manager(company_id) or private.can_job(company_id, job_id)))
  with check (private.company_access(company_id) and (private.is_manager(company_id) or private.can_job(company_id, job_id)));