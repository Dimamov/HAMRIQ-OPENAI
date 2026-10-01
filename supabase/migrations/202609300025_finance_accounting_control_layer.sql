-- HAMRIQ finance/accounting control layer
-- Adds AR, collections, accounting sync, job cost ledger, financial snapshots,
-- payment processing intents, and fraud/duplicate payment review.

create table if not exists public.accounts_receivable_items (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid,
  contact_id uuid,
  invoice_id uuid,
  title text not null,
  status text not null default 'open',
  balance_cents bigint not null default 0,
  original_amount_cents bigint not null default 0,
  due_date date,
  last_contacted_at timestamptz,
  next_collection_action_at timestamptz,
  assigned_to uuid,
  notes text,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.collection_activities (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  ar_item_id uuid not null references public.accounts_receivable_items(id) on delete cascade,
  job_id uuid,
  activity_type text not null default 'follow_up',
  channel text,
  outcome text,
  note text,
  next_action_at timestamptz,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.accounting_sync_connections (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  provider text not null default 'quickbooks',
  status text not null default 'not_connected',
  external_company_id text,
  sync_settings jsonb not null default '{}'::jsonb,
  last_sync_at timestamptz,
  last_error text,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.accounting_sync_events (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  connection_id uuid references public.accounting_sync_connections(id) on delete set null,
  record_type text not null,
  record_id uuid,
  direction text not null default 'export',
  status text not null default 'queued',
  external_id text,
  payload jsonb not null default '{}'::jsonb,
  error_message text,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

create table if not exists public.job_cost_ledger_entries (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  source_type text not null,
  source_id uuid,
  category text not null default 'other',
  description text,
  amount_cents bigint not null default 0,
  cost_type text not null default 'actual',
  incurred_at date default current_date,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  constraint job_cost_ledger_job_fk foreign key (company_id, job_id) references public.jobs(company_id, id) on delete cascade
);

create table if not exists public.company_financial_snapshots (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  snapshot_date date not null default current_date,
  period text not null default 'daily',
  revenue_cents bigint not null default 0,
  gross_profit_cents bigint not null default 0,
  ar_balance_cents bigint not null default 0,
  payments_collected_cents bigint not null default 0,
  open_invoice_count integer not null default 0,
  job_costs_cents bigint not null default 0,
  metrics jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique(company_id, snapshot_date, period)
);

create table if not exists public.payment_processing_intents (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid,
  invoice_id uuid,
  provider text not null default 'stripe',
  status text not null default 'draft',
  amount_cents bigint not null default 0,
  customer_email text,
  external_intent_id text,
  payment_link_url text,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.payment_fraud_checks (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  payment_transaction_id uuid,
  job_id uuid,
  check_type text not null default 'duplicate_payment',
  risk_level text not null default 'review',
  status text not null default 'open',
  evidence jsonb not null default '{}'::jsonb,
  manager_decision text,
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists ar_items_company_status_idx on public.accounts_receivable_items(company_id, status, due_date);
create index if not exists collection_activities_ar_idx on public.collection_activities(company_id, ar_item_id, created_at desc);
create index if not exists accounting_sync_connections_company_idx on public.accounting_sync_connections(company_id, provider, status);
create index if not exists accounting_sync_events_company_idx on public.accounting_sync_events(company_id, status, created_at desc);
create index if not exists job_cost_ledger_job_idx on public.job_cost_ledger_entries(company_id, job_id, incurred_at desc);
create index if not exists financial_snapshots_company_idx on public.company_financial_snapshots(company_id, snapshot_date desc);
create index if not exists payment_intents_company_idx on public.payment_processing_intents(company_id, status, created_at desc);
create index if not exists payment_fraud_checks_company_idx on public.payment_fraud_checks(company_id, status, risk_level);

alter table public.accounts_receivable_items enable row level security;
alter table public.collection_activities enable row level security;
alter table public.accounting_sync_connections enable row level security;
alter table public.accounting_sync_events enable row level security;
alter table public.job_cost_ledger_entries enable row level security;
alter table public.company_financial_snapshots enable row level security;
alter table public.payment_processing_intents enable row level security;
alter table public.payment_fraud_checks enable row level security;

grant select, insert, update on public.accounts_receivable_items to authenticated;
grant select, insert, update on public.collection_activities to authenticated;
grant select, insert, update on public.accounting_sync_connections to authenticated;
grant select, insert, update on public.accounting_sync_events to authenticated;
grant select, insert, update on public.job_cost_ledger_entries to authenticated;
grant select, insert, update on public.company_financial_snapshots to authenticated;
grant select, insert, update on public.payment_processing_intents to authenticated;
grant select, insert, update on public.payment_fraud_checks to authenticated;

create policy ar_manager_all on public.accounts_receivable_items for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy collection_manager_all on public.collection_activities for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy accounting_connections_manager_all on public.accounting_sync_connections for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy accounting_events_manager_all on public.accounting_sync_events for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy job_cost_manager_all on public.job_cost_ledger_entries for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy job_cost_rep_job_read on public.job_cost_ledger_entries for select to authenticated using (private.can_job(company_id, job_id));
create policy financial_snapshots_manager_all on public.company_financial_snapshots for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy payment_intents_manager_all on public.payment_processing_intents for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy payment_intents_rep_job_read on public.payment_processing_intents for select to authenticated using (job_id is not null and private.can_job(company_id, job_id));
create policy payment_fraud_manager_all on public.payment_fraud_checks for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
