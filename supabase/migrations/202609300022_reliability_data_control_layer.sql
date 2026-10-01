-- HAMRIQ reliability/data-control layer
-- Offline queue, photo upload protection, data import/export, audit log,
-- duplicate detection, universal search, and custom workflow builder foundations.

create table if not exists public.offline_sync_queue (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null default auth.uid(),
  device_id text,
  entity_type text not null,
  entity_id uuid,
  action text not null,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'queued',
  error_message text,
  queued_at timestamptz not null default now(),
  synced_at timestamptz
);

create table if not exists public.photo_upload_jobs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid,
  uploaded_by uuid not null default auth.uid(),
  local_reference text,
  storage_path text,
  file_name text,
  photo_category text not null default 'inspection',
  upload_status text not null default 'pending',
  retry_count integer not null default 0,
  checksum text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  completed_at timestamptz,
  constraint photo_upload_jobs_job_fk foreign key (company_id, job_id) references public.jobs(company_id, id) on delete set null
);

create table if not exists public.data_import_jobs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  import_type text not null,
  source_name text,
  source_file_path text,
  status text not null default 'uploaded',
  total_rows integer not null default 0,
  imported_rows integer not null default 0,
  failed_rows integer not null default 0,
  mapping jsonb not null default '{}'::jsonb,
  errors jsonb not null default '[]'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

create table if not exists public.data_export_jobs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  export_type text not null,
  status text not null default 'requested',
  filters jsonb not null default '{}'::jsonb,
  result_path text,
  requested_by uuid not null default auth.uid(),
  requested_at timestamptz not null default now(),
  completed_at timestamptz
);

create table if not exists public.audit_log_entries (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  actor_id uuid default auth.uid(),
  entity_type text not null,
  entity_id uuid,
  action text not null,
  before_state jsonb,
  after_state jsonb,
  ip_address text,
  user_agent text,
  created_at timestamptz not null default now()
);

create table if not exists public.duplicate_detection_candidates (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  candidate_type text not null default 'contact',
  primary_record_id uuid not null,
  duplicate_record_id uuid not null,
  confidence numeric(6,4) not null default 0,
  reasons jsonb not null default '[]'::jsonb,
  status text not null default 'needs_review',
  reviewed_by uuid,
  reviewed_at timestamptz,
  resolution_note text,
  created_at timestamptz not null default now()
);

create table if not exists public.universal_search_index (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  entity_type text not null,
  entity_id uuid not null,
  title text not null,
  subtitle text,
  searchable_text text not null,
  route_hint text,
  metadata jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  unique(company_id, entity_type, entity_id)
);

create table if not exists public.custom_workflow_definitions (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null,
  description text,
  entity_type text not null default 'job',
  trigger_type text not null,
  trigger_config jsonb not null default '{}'::jsonb,
  actions jsonb not null default '[]'::jsonb,
  active boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.custom_workflow_runs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  workflow_id uuid not null references public.custom_workflow_definitions(id) on delete cascade,
  entity_type text not null,
  entity_id uuid,
  status text not null default 'queued',
  input jsonb not null default '{}'::jsonb,
  output jsonb not null default '{}'::jsonb,
  error_message text,
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists offline_sync_queue_user_idx on public.offline_sync_queue(company_id, user_id, status, queued_at desc);
create index if not exists photo_upload_jobs_job_idx on public.photo_upload_jobs(company_id, job_id, upload_status);
create index if not exists data_import_jobs_company_idx on public.data_import_jobs(company_id, status, created_at desc);
create index if not exists data_export_jobs_company_idx on public.data_export_jobs(company_id, status, requested_at desc);
create index if not exists audit_log_entries_company_idx on public.audit_log_entries(company_id, created_at desc);
create index if not exists duplicate_detection_company_idx on public.duplicate_detection_candidates(company_id, status, confidence desc);
create index if not exists universal_search_company_idx on public.universal_search_index(company_id, entity_type);
create index if not exists custom_workflow_definitions_company_idx on public.custom_workflow_definitions(company_id, active, entity_type);
create index if not exists custom_workflow_runs_company_idx on public.custom_workflow_runs(company_id, status, created_at desc);

alter table public.offline_sync_queue enable row level security;
alter table public.photo_upload_jobs enable row level security;
alter table public.data_import_jobs enable row level security;
alter table public.data_export_jobs enable row level security;
alter table public.audit_log_entries enable row level security;
alter table public.duplicate_detection_candidates enable row level security;
alter table public.universal_search_index enable row level security;
alter table public.custom_workflow_definitions enable row level security;
alter table public.custom_workflow_runs enable row level security;

grant select, insert, update on public.offline_sync_queue to authenticated;
grant select, insert, update on public.photo_upload_jobs to authenticated;
grant select, insert, update on public.data_import_jobs to authenticated;
grant select, insert, update on public.data_export_jobs to authenticated;
grant select, insert, update on public.audit_log_entries to authenticated;
grant select, insert, update on public.duplicate_detection_candidates to authenticated;
grant select, insert, update on public.universal_search_index to authenticated;
grant select, insert, update on public.custom_workflow_definitions to authenticated;
grant select, insert, update on public.custom_workflow_runs to authenticated;

-- RLS policies are idempotently applied in the live database using the private.company_access/private.is_manager helpers.