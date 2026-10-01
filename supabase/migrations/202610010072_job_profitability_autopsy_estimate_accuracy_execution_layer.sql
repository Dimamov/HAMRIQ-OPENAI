-- HAMRIQ job profitability/autopsy + estimate accuracy learning execution layer
-- Adds final margin review, variance analysis, missed-cost tracking, estimate accuracy feedback,
-- underpriced-item alerts, profitability learning records, margin exception reviews, and activity audit.

create table if not exists public.job_profitability_autopsy_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  status text not null default 'draft' check (status in ('draft','review_needed','reviewed','locked','archived')),
  original_contract_cents bigint not null default 0,
  approved_change_order_cents bigint not null default 0,
  total_revenue_cents bigint not null default 0,
  estimated_cost_cents bigint not null default 0,
  actual_cost_cents bigint not null default 0,
  gross_profit_cents bigint not null default 0,
  gross_margin_percent numeric(8,4) not null default 0,
  reviewed_by uuid,
  reviewed_at timestamptz,
  requires_manager_review boolean not null default true,
  notes text not null default '',
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.job_cost_variance_lines_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  autopsy_run_id uuid references public.job_profitability_autopsy_runs_deep(id) on delete cascade,
  variance_type text not null default 'other' check (variance_type in ('labor','material','dumpster','permit','subcontractor','supplement','production_delay','warranty_callback','other')),
  estimated_cents bigint not null default 0,
  actual_cents bigint not null default 0,
  variance_cents bigint not null default 0,
  explanation text not null default '',
  owner_user_id uuid,
  requires_manager_review boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.missed_cost_item_records_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  autopsy_run_id uuid references public.job_profitability_autopsy_runs_deep(id) on delete set null,
  item_name text not null,
  category text not null default 'other',
  missed_reason text not null default '',
  estimated_impact_cents bigint not null default 0,
  should_update_template boolean not null default false,
  reviewed_by uuid,
  reviewed_at timestamptz,
  requires_manager_review boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.estimate_accuracy_feedback_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  estimate_id uuid,
  score numeric(8,4) not null default 0,
  rating text not null default 'unrated' check (rating in ('unrated','accurate','slightly_off','materially_off','bad')),
  estimator_user_id uuid,
  feedback_summary text not null default '',
  recommended_template_updates jsonb not null default '[]'::jsonb,
  requires_manager_review boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.underpriced_item_alerts_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid,
  price_item_id uuid,
  alert_status text not null default 'open' check (alert_status in ('open','reviewing','approved_update','dismissed','archived')),
  item_name text not null default '',
  current_price_cents bigint not null default 0,
  suggested_price_cents bigint not null default 0,
  evidence jsonb not null default '{}'::jsonb,
  reviewed_by uuid,
  reviewed_at timestamptz,
  requires_manager_review boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.profitability_learning_records_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid,
  source_table text not null default '',
  source_record_id uuid,
  learning_type text not null default 'estimate_accuracy' check (learning_type in ('estimate_accuracy','pricing','production','sales','supplement','warranty','other')),
  learning_summary text not null default '',
  ai_generated boolean not null default true,
  accepted_by uuid,
  accepted_at timestamptz,
  rejected_by uuid,
  rejected_at timestamptz,
  requires_manager_review boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.margin_exception_reviews_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  autopsy_run_id uuid references public.job_profitability_autopsy_runs_deep(id) on delete cascade,
  exception_type text not null default 'low_margin' check (exception_type in ('low_margin','negative_margin','high_variance','missing_cost','unapproved_discount','other')),
  severity text not null default 'medium' check (severity in ('low','medium','high','critical')),
  status text not null default 'open' check (status in ('open','reviewing','resolved','dismissed','archived')),
  resolution_notes text not null default '',
  assigned_to uuid,
  resolved_by uuid,
  resolved_at timestamptz,
  requires_manager_review boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.profitability_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid,
  event_type text not null default 'created',
  event_summary text not null default '',
  related_table text not null default '',
  related_record_id uuid,
  actor_user_id uuid not null default auth.uid(),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- RLS is enforced in production DB migration with company/manager policies.
