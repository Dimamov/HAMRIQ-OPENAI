-- HAMRIQ integrations and automation deep layer
-- Live project migration adds provider settings, sync jobs, webhook events,
-- API usage logs, automation rules/runs, scheduled reports, and integration errors.

create table if not exists public.integration_provider_settings (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  provider text not null,
  category text not null default 'general',
  display_name text not null,
  connection_status text not null default 'not_connected',
  requires_additional_subscription boolean not null default false,
  subscription_notice text not null default 'Additional subscription required. Contact HAMRIQ for information.',
  settings jsonb not null default '{}'::jsonb,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, provider)
);

create table if not exists public.integration_sync_jobs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  provider text not null,
  job_type text not null,
  status text not null default 'queued',
  records_processed integer not null default 0,
  error_message text,
  details jsonb not null default '{}'::jsonb,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.integration_webhook_events (
  id uuid primary key default gen_random_uuid(),
  company_id uuid references public.companies(id) on delete cascade,
  provider text not null,
  event_type text not null,
  delivery_status text not null default 'received',
  related_job_id uuid references public.jobs(id) on delete set null,
  payload_summary jsonb not null default '{}'::jsonb,
  received_at timestamptz not null default now()
);

create table if not exists public.api_usage_logs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid references public.companies(id) on delete cascade,
  provider text not null,
  feature_area text not null,
  request_count integer not null default 1,
  estimated_cost_cents bigint not null default 0,
  usage_date date not null default current_date,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.automation_rules (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null,
  trigger_type text not null,
  action_type text not null,
  status text not null default 'active',
  conditions jsonb not null default '{}'::jsonb,
  actions jsonb not null default '[]'::jsonb,
  requires_manager_approval boolean not null default true,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.automation_rule_runs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  automation_rule_id uuid references public.automation_rules(id) on delete set null,
  related_job_id uuid references public.jobs(id) on delete set null,
  related_contact_id uuid references public.contacts(id) on delete set null,
  status text not null default 'queued',
  outcome_summary text,
  run_details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.scheduled_report_configs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  report_name text not null,
  report_type text not null,
  cadence text not null default 'daily',
  recipients jsonb not null default '[]'::jsonb,
  filters jsonb not null default '{}'::jsonb,
  enabled boolean not null default true,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.scheduled_report_runs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  scheduled_report_config_id uuid references public.scheduled_report_configs(id) on delete set null,
  status text not null default 'queued',
  generated_snapshot_id uuid references public.report_snapshots(id) on delete set null,
  delivery_summary jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.integration_error_events (
  id uuid primary key default gen_random_uuid(),
  company_id uuid references public.companies(id) on delete cascade,
  provider text not null,
  severity text not null default 'warning',
  error_code text,
  message text not null,
  related_sync_job_id uuid references public.integration_sync_jobs(id) on delete set null,
  resolved_at timestamptz,
  resolved_by uuid,
  created_at timestamptz not null default now()
);

-- RLS policies in the live project scope manager-owned integration setup and
-- automation/report configuration to company managers, with company read access
-- for automation runs where appropriate.