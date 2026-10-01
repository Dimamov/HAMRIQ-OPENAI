-- HAMRIQ dashboard/reporting execution deep layer
-- Applied to Supabase project baxgnpnfpzashcgiibwg on 2026-09-30.
-- Database source of truth: dashboard/reporting tables with RLS and company/job/user scoped policies.

create table if not exists public.saved_dashboards_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  owner_user_id uuid not null default auth.uid(),
  dashboard_name text not null,
  dashboard_type text not null default 'manager',
  layout_config jsonb not null default '{}'::jsonb,
  filter_config jsonb not null default '{}'::jsonb,
  is_shared boolean not null default false,
  is_default boolean not null default false,
  is_active boolean not null default true,
  created_by uuid not null default auth.uid(),
  updated_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.dashboard_kpi_widgets_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  dashboard_id uuid references public.saved_dashboards_deep(id) on delete cascade,
  widget_name text not null,
  widget_key text not null,
  widget_type text not null default 'metric',
  data_source text not null default 'hamriq',
  query_config jsonb not null default '{}'::jsonb,
  display_config jsonb not null default '{}'::jsonb,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.scheduled_report_configs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  report_name text not null,
  report_type text not null default 'manager_summary',
  cadence text not null default 'weekly',
  recipients jsonb not null default '[]'::jsonb,
  report_config jsonb not null default '{}'::jsonb,
  next_run_at timestamptz,
  last_run_at timestamptz,
  is_active boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.report_export_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  scheduled_report_config_id uuid references public.scheduled_report_configs_deep(id) on delete set null,
  requested_by uuid not null default auth.uid(),
  report_name text not null,
  export_format text not null default 'pdf',
  status text not null default 'queued',
  file_path text,
  file_size_bytes bigint not null default 0,
  error_message text,
  generated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.dashboard_anomaly_cards_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  assigned_user_id uuid,
  anomaly_type text not null,
  severity text not null default 'medium',
  title text not null,
  plain_language_summary text not null default '',
  supporting_data jsonb not null default '{}'::jsonb,
  ai_generated boolean not null default true,
  human_review_required boolean not null default true,
  reviewed_by uuid,
  reviewed_at timestamptz,
  status text not null default 'open',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.manager_snapshot_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  snapshot_date date not null default current_date,
  snapshot_type text not null default 'daily',
  pipeline_summary jsonb not null default '{}'::jsonb,
  production_summary jsonb not null default '{}'::jsonb,
  finance_summary jsonb not null default '{}'::jsonb,
  risk_summary jsonb not null default '{}'::jsonb,
  ai_summary text not null default '',
  human_review_required boolean not null default true,
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.rep_scorecard_history_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  rep_user_id uuid not null,
  scorecard_period_start date not null,
  scorecard_period_end date not null,
  lead_count integer not null default 0,
  inspection_count integer not null default 0,
  signed_contract_count integer not null default 0,
  revenue_cents bigint not null default 0,
  close_rate numeric(7,4) not null default 0,
  activity_score numeric(8,2) not null default 0,
  coaching_summary text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.dashboard_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  dashboard_id uuid references public.saved_dashboards_deep(id) on delete set null,
  report_export_run_id uuid references public.report_export_runs_deep(id) on delete set null,
  event_type text not null,
  event_summary text not null default '',
  event_payload jsonb not null default '{}'::jsonb,
  actor_user_id uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

-- RLS/policies applied in production Supabase migration dashboard_reporting_execution_deep_layer_v2.
