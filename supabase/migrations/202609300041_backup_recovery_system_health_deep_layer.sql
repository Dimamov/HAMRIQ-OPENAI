create table if not exists public.backup_job_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  backup_scope text not null default 'company_data' check (backup_scope in ('company_data','files','database','configuration','full_system')),
  status text not null default 'queued' check (status in ('queued','running','completed','failed','cancelled')),
  started_at timestamptz,
  completed_at timestamptz,
  record_count integer not null default 0,
  storage_location text,
  checksum text,
  error_message text,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.restore_request_runs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  backup_job_id uuid references public.backup_job_runs_deep(id) on delete set null,
  requested_by uuid not null default auth.uid(),
  approved_by uuid,
  status text not null default 'requested' check (status in ('requested','approved','rejected','running','completed','failed','cancelled')),
  restore_reason text not null default '',
  restore_scope jsonb not null default '{}'::jsonb,
  approval_notes text,
  started_at timestamptz,
  completed_at timestamptz,
  error_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.disaster_recovery_tests (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  test_name text not null,
  test_status text not null default 'planned' check (test_status in ('planned','running','passed','failed','needs_review','cancelled')),
  test_scope jsonb not null default '{}'::jsonb,
  findings jsonb not null default '[]'::jsonb,
  corrective_actions jsonb not null default '[]'::jsonb,
  tested_by uuid default auth.uid(),
  scheduled_for timestamptz,
  completed_at timestamptz,
  manager_reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.system_health_checks_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid references public.companies(id) on delete cascade,
  component text not null,
  status text not null default 'healthy' check (status in ('healthy','degraded','down','maintenance','unknown')),
  severity text not null default 'info' check (severity in ('info','warning','critical')),
  response_time_ms integer,
  checked_at timestamptz not null default now(),
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.system_incident_records (
  id uuid primary key default gen_random_uuid(),
  company_id uuid references public.companies(id) on delete cascade,
  title text not null,
  incident_type text not null default 'system' check (incident_type in ('system','integration','database','storage','auth','messaging','ai','billing','other')),
  severity text not null default 'minor' check (severity in ('minor','major','critical')),
  status text not null default 'investigating' check (status in ('investigating','identified','monitoring','resolved','cancelled')),
  started_at timestamptz not null default now(),
  resolved_at timestamptz,
  impact_summary text not null default '',
  root_cause text,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.system_incident_updates (
  id uuid primary key default gen_random_uuid(),
  company_id uuid references public.companies(id) on delete cascade,
  incident_id uuid not null references public.system_incident_records(id) on delete cascade,
  update_type text not null default 'status' check (update_type in ('status','customer_notice','internal_note','resolution','postmortem')),
  message text not null,
  posted_by uuid default auth.uid(),
  posted_at timestamptz not null default now(),
  visible_to_company boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.ai_recovery_assistant_events (
  id uuid primary key default gen_random_uuid(),
  company_id uuid references public.companies(id) on delete cascade,
  incident_id uuid references public.system_incident_records(id) on delete set null,
  restore_request_id uuid references public.restore_request_runs(id) on delete set null,
  event_type text not null default 'recommendation' check (event_type in ('recommendation','diagnosis','restore_plan','risk_warning','summary','human_review_required')),
  recommendation text not null,
  confidence numeric(5,2),
  requires_human_review boolean not null default true,
  reviewed_by uuid,
  reviewed_at timestamptz,
  review_decision text check (review_decision is null or review_decision in ('approved','rejected','needs_changes')),
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.uptime_monitor_targets (
  id uuid primary key default gen_random_uuid(),
  company_id uuid references public.companies(id) on delete cascade,
  target_name text not null,
  target_type text not null default 'app' check (target_type in ('app','api','integration','webhook','storage','database','ai_service','other')),
  target_url text,
  is_enabled boolean not null default true,
  expected_status text not null default 'healthy',
  check_frequency_minutes integer not null default 15,
  manager_alert_on_failure boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists backup_job_runs_deep_company_idx on public.backup_job_runs_deep(company_id, created_at desc);
create index if not exists restore_request_runs_company_idx on public.restore_request_runs(company_id, created_at desc);
create index if not exists disaster_recovery_tests_company_idx on public.disaster_recovery_tests(company_id, scheduled_for desc);
create index if not exists system_health_checks_deep_company_idx on public.system_health_checks_deep(company_id, checked_at desc);
create index if not exists system_incident_records_company_idx on public.system_incident_records(company_id, started_at desc);
create index if not exists system_incident_updates_incident_idx on public.system_incident_updates(incident_id, posted_at desc);
create index if not exists ai_recovery_assistant_events_company_idx on public.ai_recovery_assistant_events(company_id, created_at desc);
create index if not exists uptime_monitor_targets_company_idx on public.uptime_monitor_targets(company_id, is_enabled);

alter table public.backup_job_runs_deep enable row level security;
alter table public.restore_request_runs enable row level security;
alter table public.disaster_recovery_tests enable row level security;
alter table public.system_health_checks_deep enable row level security;
alter table public.system_incident_records enable row level security;
alter table public.system_incident_updates enable row level security;
alter table public.ai_recovery_assistant_events enable row level security;
alter table public.uptime_monitor_targets enable row level security;

revoke all on public.backup_job_runs_deep from anon, authenticated;
revoke all on public.restore_request_runs from anon, authenticated;
revoke all on public.disaster_recovery_tests from anon, authenticated;
revoke all on public.system_health_checks_deep from anon, authenticated;
revoke all on public.system_incident_records from anon, authenticated;
revoke all on public.system_incident_updates from anon, authenticated;
revoke all on public.ai_recovery_assistant_events from anon, authenticated;
revoke all on public.uptime_monitor_targets from anon, authenticated;

grant select, insert, update on public.backup_job_runs_deep to authenticated;
grant select, insert, update on public.restore_request_runs to authenticated;
grant select, insert, update on public.disaster_recovery_tests to authenticated;
grant select, insert, update on public.system_health_checks_deep to authenticated;
grant select, insert, update on public.system_incident_records to authenticated;
grant select, insert, update on public.system_incident_updates to authenticated;
grant select, insert, update on public.ai_recovery_assistant_events to authenticated;
grant select, insert, update on public.uptime_monitor_targets to authenticated;

drop policy if exists backup_job_runs_deep_manager_all on public.backup_job_runs_deep;
create policy backup_job_runs_deep_manager_all on public.backup_job_runs_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

drop policy if exists restore_request_runs_manager_all on public.restore_request_runs;
create policy restore_request_runs_manager_all on public.restore_request_runs for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

drop policy if exists disaster_recovery_tests_manager_all on public.disaster_recovery_tests;
create policy disaster_recovery_tests_manager_all on public.disaster_recovery_tests for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

drop policy if exists system_health_checks_deep_company_read on public.system_health_checks_deep;
create policy system_health_checks_deep_company_read on public.system_health_checks_deep for select to authenticated using (company_id is null or private.company_access(company_id));
drop policy if exists system_health_checks_deep_manager_write on public.system_health_checks_deep;
create policy system_health_checks_deep_manager_write on public.system_health_checks_deep for insert to authenticated with check (company_id is null or private.is_manager(company_id));

drop policy if exists system_incident_records_company_read on public.system_incident_records;
create policy system_incident_records_company_read on public.system_incident_records for select to authenticated using (company_id is null or private.company_access(company_id));
drop policy if exists system_incident_records_manager_write on public.system_incident_records;
create policy system_incident_records_manager_write on public.system_incident_records for all to authenticated using (company_id is null or private.is_manager(company_id)) with check (company_id is null or private.is_manager(company_id));

drop policy if exists system_incident_updates_company_read on public.system_incident_updates;
create policy system_incident_updates_company_read on public.system_incident_updates for select to authenticated using (company_id is null or private.company_access(company_id));
drop policy if exists system_incident_updates_manager_write on public.system_incident_updates;
create policy system_incident_updates_manager_write on public.system_incident_updates for all to authenticated using (company_id is null or private.is_manager(company_id)) with check (company_id is null or private.is_manager(company_id));

drop policy if exists ai_recovery_assistant_events_manager_all on public.ai_recovery_assistant_events;
create policy ai_recovery_assistant_events_manager_all on public.ai_recovery_assistant_events for all to authenticated using (company_id is null or private.is_manager(company_id)) with check (company_id is null or private.is_manager(company_id));

drop policy if exists uptime_monitor_targets_company_read on public.uptime_monitor_targets;
create policy uptime_monitor_targets_company_read on public.uptime_monitor_targets for select to authenticated using (company_id is null or private.company_access(company_id));
drop policy if exists uptime_monitor_targets_manager_write on public.uptime_monitor_targets;
create policy uptime_monitor_targets_manager_write on public.uptime_monitor_targets for all to authenticated using (company_id is null or private.is_manager(company_id)) with check (company_id is null or private.is_manager(company_id));
