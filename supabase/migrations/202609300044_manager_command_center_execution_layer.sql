-- HAMRIQ manager command-center execution layer
-- Adds manager approval inbox routing, saved smart views, bulk action execution, task queues, escalation rules, and dashboard widgets.

create table if not exists public.manager_approval_inbox_items (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  source_table text not null,
  source_id uuid not null,
  approval_type text not null,
  priority text not null default 'normal' check (priority in ('low','normal','high','urgent')),
  status text not null default 'open' check (status in ('open','in_review','approved','rejected','cancelled')),
  assigned_manager_id uuid,
  requested_by uuid default auth.uid(),
  due_at timestamptz,
  summary text not null default '',
  decision_notes text not null default '',
  decided_by uuid,
  decided_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.smart_view_definitions_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  name text not null,
  module text not null,
  visibility text not null default 'manager' check (visibility in ('private','team','manager','company')),
  filter_json jsonb not null default '{}'::jsonb,
  sort_json jsonb not null default '[]'::jsonb,
  layout_json jsonb not null default '{}'::jsonb,
  owner_id uuid not null default auth.uid(),
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.bulk_action_jobs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  action_type text not null,
  target_module text not null,
  requested_by uuid not null default auth.uid(),
  requires_manager_approval boolean not null default true,
  approved_by uuid,
  approved_at timestamptz,
  status text not null default 'draft' check (status in ('draft','pending_approval','approved','running','completed','failed','cancelled')),
  target_count integer not null default 0,
  success_count integer not null default 0,
  failure_count integer not null default 0,
  parameters jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.bulk_action_job_items_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  bulk_action_job_id uuid not null references public.bulk_action_jobs_deep(id) on delete cascade,
  target_table text not null,
  target_id uuid not null,
  status text not null default 'pending' check (status in ('pending','running','completed','failed','skipped')),
  error_message text not null default '',
  result_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.manager_task_queue_items (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid references public.jobs(id),
  title text not null,
  task_type text not null,
  priority text not null default 'normal' check (priority in ('low','normal','high','urgent')),
  status text not null default 'open' check (status in ('open','in_progress','waiting','completed','cancelled')),
  assigned_to uuid,
  created_by uuid not null default auth.uid(),
  due_at timestamptz,
  completed_at timestamptz,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.escalation_rule_definitions_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  name text not null,
  module text not null,
  trigger_event text not null,
  is_enabled boolean not null default true,
  threshold_minutes integer not null default 60,
  escalation_target text not null default 'manager',
  message_template text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.escalation_rule_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  escalation_rule_id uuid not null references public.escalation_rule_definitions_deep(id) on delete cascade,
  source_table text not null,
  source_id uuid not null,
  status text not null default 'triggered' check (status in ('triggered','notified','resolved','suppressed','failed')),
  notified_user_ids uuid[] not null default '{}',
  resolution_notes text not null default '',
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create table if not exists public.manager_dashboard_widgets (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  widget_key text not null,
  title text not null,
  module text not null,
  config_json jsonb not null default '{}'::jsonb,
  position_json jsonb not null default '{}'::jsonb,
  visibility text not null default 'manager' check (visibility in ('private','manager','company')),
  owner_id uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.manager_approval_inbox_items enable row level security;
alter table public.smart_view_definitions_deep enable row level security;
alter table public.bulk_action_jobs_deep enable row level security;
alter table public.bulk_action_job_items_deep enable row level security;
alter table public.manager_task_queue_items enable row level security;
alter table public.escalation_rule_definitions_deep enable row level security;
alter table public.escalation_rule_runs_deep enable row level security;
alter table public.manager_dashboard_widgets enable row level security;

-- Full live migration also includes indexes, grants, and manager/company-scoped RLS policies.