-- HAMRIQ data migration / import / export execution layer
-- Adds CRM migration projects, import mappings, import batches, row-level validation, export manifests, duplicate merge review, and data retention policies.

create table if not exists public.crm_migration_projects (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  source_system text not null default 'unknown',
  source_description text not null default '',
  migration_status text not null default 'planning' check (migration_status in ('planning','mapping','test_import','review_needed','approved','importing','completed','failed','paused')),
  owner_user_id uuid default auth.uid(),
  total_records_estimated integer not null default 0,
  total_records_imported integer not null default 0,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.import_mapping_profiles (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  migration_project_id uuid references public.crm_migration_projects(id) on delete set null,
  profile_name text not null,
  source_object text not null default 'contacts',
  target_object text not null default 'contacts',
  field_map jsonb not null default '{}'::jsonb,
  transformation_rules jsonb not null default '[]'::jsonb,
  required_review boolean not null default true,
  is_active boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.import_batches_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  migration_project_id uuid references public.crm_migration_projects(id) on delete set null,
  mapping_profile_id uuid references public.import_mapping_profiles(id) on delete set null,
  batch_name text not null default 'Import batch',
  source_file_name text not null default '',
  source_file_path text not null default '',
  batch_status text not null default 'uploaded' check (batch_status in ('uploaded','validating','needs_mapping','review_needed','approved','importing','completed','completed_with_errors','failed','canceled')),
  row_count integer not null default 0,
  valid_row_count integer not null default 0,
  error_row_count integer not null default 0,
  duplicate_candidate_count integer not null default 0,
  approved_by uuid,
  approved_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.import_batch_rows (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  import_batch_id uuid not null references public.import_batches_deep(id) on delete cascade,
  source_row_number integer not null,
  raw_payload jsonb not null default '{}'::jsonb,
  normalized_payload jsonb not null default '{}'::jsonb,
  row_status text not null default 'pending' check (row_status in ('pending','valid','warning','error','duplicate_candidate','imported','skipped')),
  error_messages jsonb not null default '[]'::jsonb,
  warning_messages jsonb not null default '[]'::jsonb,
  target_record_type text not null default '',
  target_record_id uuid,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.export_request_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  export_name text not null default 'Company data export',
  export_scope text not null default 'company' check (export_scope in ('company','jobs','contacts','financials','photos','documents','audit','custom')),
  filters jsonb not null default '{}'::jsonb,
  export_status text not null default 'requested' check (export_status in ('requested','queued','running','ready','failed','expired','canceled')),
  requested_by uuid not null default auth.uid(),
  approved_by uuid,
  approved_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.export_file_manifests (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  export_request_run_id uuid not null references public.export_request_runs_deep(id) on delete cascade,
  file_label text not null,
  file_path text not null default '',
  file_format text not null default 'csv' check (file_format in ('csv','json','xlsx','zip','pdf')),
  record_count integer not null default 0,
  checksum text not null default '',
  file_status text not null default 'pending' check (file_status in ('pending','generated','failed','expired')),
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.duplicate_merge_requests_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  record_type text not null default 'contact' check (record_type in ('contact','job','property','company','other')),
  primary_record_id uuid,
  duplicate_record_id uuid,
  confidence_score numeric(5,2) not null default 0,
  detected_reasons jsonb not null default '[]'::jsonb,
  proposed_merge_payload jsonb not null default '{}'::jsonb,
  request_status text not null default 'review_needed' check (request_status in ('review_needed','approved','rejected','merged','failed','ignored')),
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.data_retention_policies_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  policy_name text not null,
  data_category text not null default 'general',
  retention_days integer not null default 2555,
  archive_before_delete boolean not null default true,
  requires_manager_approval boolean not null default true,
  is_active boolean not null default true,
  legal_hold_enabled boolean not null default false,
  policy_notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists crm_migration_projects_company_status_idx on public.crm_migration_projects(company_id, migration_status);
create index if not exists import_mapping_profiles_company_idx on public.import_mapping_profiles(company_id, target_object);
create index if not exists import_batches_deep_company_status_idx on public.import_batches_deep(company_id, batch_status);
create index if not exists import_batch_rows_batch_status_idx on public.import_batch_rows(import_batch_id, row_status);
create index if not exists export_request_runs_deep_company_status_idx on public.export_request_runs_deep(company_id, export_status);
create index if not exists export_file_manifests_run_idx on public.export_file_manifests(export_request_run_id);
create index if not exists duplicate_merge_requests_deep_company_status_idx on public.duplicate_merge_requests_deep(company_id, request_status);
create index if not exists data_retention_policies_deep_company_idx on public.data_retention_policies_deep(company_id, data_category);

alter table public.crm_migration_projects enable row level security;
alter table public.import_mapping_profiles enable row level security;
alter table public.import_batches_deep enable row level security;
alter table public.import_batch_rows enable row level security;
alter table public.export_request_runs_deep enable row level security;
alter table public.export_file_manifests enable row level security;
alter table public.duplicate_merge_requests_deep enable row level security;
alter table public.data_retention_policies_deep enable row level security;

revoke all on public.crm_migration_projects from anon, authenticated;
revoke all on public.import_mapping_profiles from anon, authenticated;
revoke all on public.import_batches_deep from anon, authenticated;
revoke all on public.import_batch_rows from anon, authenticated;
revoke all on public.export_request_runs_deep from anon, authenticated;
revoke all on public.export_file_manifests from anon, authenticated;
revoke all on public.duplicate_merge_requests_deep from anon, authenticated;
revoke all on public.data_retention_policies_deep from anon, authenticated;

grant select, insert, update on public.crm_migration_projects to authenticated;
grant select, insert, update on public.import_mapping_profiles to authenticated;
grant select, insert, update on public.import_batches_deep to authenticated;
grant select, insert, update on public.import_batch_rows to authenticated;
grant select, insert, update on public.export_request_runs_deep to authenticated;
grant select, insert, update on public.export_file_manifests to authenticated;
grant select, insert, update on public.duplicate_merge_requests_deep to authenticated;
grant select, insert, update on public.data_retention_policies_deep to authenticated;

create policy crm_migration_projects_manager_all_v43 on public.crm_migration_projects
  for all to authenticated
  using (private.is_manager(company_id))
  with check (private.is_manager(company_id));
create policy import_mapping_profiles_manager_all_v43 on public.import_mapping_profiles
  for all to authenticated
  using (private.is_manager(company_id))
  with check (private.is_manager(company_id));
create policy import_batches_deep_manager_all_v43 on public.import_batches_deep
  for all to authenticated
  using (private.is_manager(company_id))
  with check (private.is_manager(company_id));
create policy import_batch_rows_manager_all_v43 on public.import_batch_rows
  for all to authenticated
  using (private.is_manager(company_id))
  with check (private.is_manager(company_id));
create policy export_request_runs_deep_manager_all_v43 on public.export_request_runs_deep
  for all to authenticated
  using (private.is_manager(company_id))
  with check (private.is_manager(company_id));
create policy export_file_manifests_manager_all_v43 on public.export_file_manifests
  for all to authenticated
  using (private.is_manager(company_id))
  with check (private.is_manager(company_id));
create policy duplicate_merge_requests_deep_manager_all_v43 on public.duplicate_merge_requests_deep
  for all to authenticated
  using (private.is_manager(company_id))
  with check (private.is_manager(company_id));
create policy data_retention_policies_deep_manager_all_v43 on public.data_retention_policies_deep
  for all to authenticated
  using (private.is_manager(company_id))
  with check (private.is_manager(company_id));
create policy export_request_runs_deep_requester_read_v43 on public.export_request_runs_deep
  for select to authenticated
  using (requested_by = (select auth.uid()) and private.company_access(company_id));
create policy import_batches_deep_company_read_v43 on public.import_batches_deep
  for select to authenticated
  using (private.company_access(company_id));
create policy duplicate_merge_requests_deep_company_read_v43 on public.duplicate_merge_requests_deep
  for select to authenticated
  using (private.company_access(company_id));
