create table if not exists public.accounting_connection_health_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  provider text not null default 'quickbooks',
  connection_id uuid,
  health_status text not null default 'unknown' check (health_status in ('unknown','healthy','warning','failed','disabled')),
  last_success_at timestamptz,
  last_failure_at timestamptz,
  last_error_message text,
  token_expires_at timestamptz,
  requires_reauth boolean not null default false,
  additional_subscription_required boolean not null default false,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.accounting_sync_queue_items_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  provider text not null default 'quickbooks',
  record_type text not null,
  source_table text,
  source_record_id uuid,
  sync_direction text not null default 'to_accounting' check (sync_direction in ('to_accounting','from_accounting','two_way')),
  status text not null default 'queued' check (status in ('queued','processing','synced','failed','skipped','needs_review')),
  priority text not null default 'normal' check (priority in ('low','normal','high','urgent')),
  scheduled_for timestamptz not null default now(),
  processed_at timestamptz,
  attempt_count integer not null default 0,
  external_record_id text,
  payload jsonb not null default '{}'::jsonb,
  result_payload jsonb not null default '{}'::jsonb,
  error_message text,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.accounting_mapped_accounts_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  provider text not null default 'quickbooks',
  hamriq_account_key text not null,
  hamriq_account_label text not null,
  external_account_id text not null,
  external_account_name text not null,
  account_type text not null default 'other',
  is_active boolean not null default true,
  manager_review_required boolean not null default true,
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, provider, hamriq_account_key)
);

create table if not exists public.accounting_mapped_items_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  provider text not null default 'quickbooks',
  hamriq_item_type text not null,
  hamriq_item_key text not null,
  hamriq_item_label text not null,
  external_item_id text not null,
  external_item_name text not null,
  income_account_external_id text,
  expense_account_external_id text,
  is_active boolean not null default true,
  manager_review_required boolean not null default true,
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, provider, hamriq_item_type, hamriq_item_key)
);

create table if not exists public.accounting_failed_sync_retries_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  sync_queue_item_id uuid references public.accounting_sync_queue_items_deep(id) on delete cascade,
  retry_number integer not null default 1,
  retry_status text not null default 'pending' check (retry_status in ('pending','running','successful','failed','cancelled')),
  retry_after timestamptz not null default now(),
  ran_at timestamptz,
  error_message text,
  resolution_notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.deposit_match_records_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  provider text not null default 'quickbooks',
  external_deposit_id text,
  external_deposit_date date,
  external_amount_cents bigint not null default 0,
  matched_payment_transaction_id uuid references public.payment_transactions(id) on delete set null,
  match_status text not null default 'unmatched' check (match_status in ('unmatched','suggested','matched','rejected','needs_review')),
  confidence_score numeric(5,2) not null default 0,
  manager_review_required boolean not null default true,
  reviewed_by uuid,
  reviewed_at timestamptz,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.job_cost_sync_audits_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  provider text not null default 'quickbooks',
  audit_status text not null default 'pending' check (audit_status in ('pending','balanced','variance_found','needs_review','resolved')),
  hamriq_revenue_cents bigint not null default 0,
  accounting_revenue_cents bigint not null default 0,
  hamriq_cost_cents bigint not null default 0,
  accounting_cost_cents bigint not null default 0,
  revenue_variance_cents bigint generated always as (hamriq_revenue_cents - accounting_revenue_cents) stored,
  cost_variance_cents bigint generated always as (hamriq_cost_cents - accounting_cost_cents) stored,
  variance_summary text not null default '',
  manager_review_required boolean not null default true,
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.accounting_sync_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  event_type text not null,
  event_status text not null default 'logged' check (event_status in ('logged','review_needed','resolved','ignored')),
  summary text not null default '',
  details jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

-- Indexes, RLS, grants, and policies are applied in the live Supabase project migration.
