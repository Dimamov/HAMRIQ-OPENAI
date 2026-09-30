create table if not exists public.kpi_goals (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  name text not null, metric_key text not null, target_value numeric not null default 0,
  period_start date not null, period_end date not null, scope text not null default 'company',
  owner_id uuid, created_by uuid not null default auth.uid(), created_at timestamptz not null default now(),
  unique(company_id,id)
);
create table if not exists public.sales_forecasts (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  forecast_date date not null default current_date, period_start date not null, period_end date not null,
  expected_contracts numeric not null default 0, expected_sold_cents bigint not null default 0,
  expected_collected_cents bigint not null default 0, assumptions jsonb not null default '{}'::jsonb,
  confidence_note text not null default 'Forecast is a range, not a guarantee.',
  created_by uuid not null default auth.uid(), created_at timestamptz not null default now(), unique(company_id,id)
);
create table if not exists public.business_health_items (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  area text not null, severity text not null default 'attention', title text not null,
  explanation text not null default '', entity_type text, entity_id uuid, status text not null default 'open',
  created_at timestamptz not null default now(), unique(company_id,id)
);
create table if not exists public.anomaly_alerts (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  alert_type text not null, severity text not null default 'review', entity_type text not null, entity_id uuid,
  explanation text not null, suggested_action text not null default '', status text not null default 'open',
  reviewed_by uuid, reviewed_at timestamptz, created_at timestamptz not null default now(), unique(company_id,id)
);
create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  job_id uuid not null, invoice_number text not null, status text not null default 'draft',
  subtotal_cents bigint not null default 0, total_cents bigint not null default 0,
  balance_cents bigint not null default 0, due_on date, sent_at timestamptz,
  created_by uuid not null default auth.uid(), created_at timestamptz not null default now(),
  unique(company_id,id), unique(company_id,invoice_number)
);
create table if not exists public.payment_transactions (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  job_id uuid, invoice_id uuid, processor text not null default 'pending', processor_reference text,
  amount_cents bigint not null check(amount_cents>=0), fee_cents bigint not null default 0 check(fee_cents>=0),
  method text not null default 'unknown', status text not null default 'pending', received_at timestamptz,
  created_at timestamptz not null default now(), unique(company_id,id)
);
create table if not exists public.contract_compliance_checks (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  contract_id uuid not null, status text not null default 'needs_review', missing_items jsonb not null default '[]'::jsonb,
  protected_language_changed boolean not null default false, checked_by uuid not null default auth.uid(),
  checked_at timestamptz not null default now(), unique(company_id,id)
);
create table if not exists public.permits (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  job_id uuid not null, municipality text not null default '', status text not null default 'required',
  permit_number text not null default '', fee_cents bigint not null default 0, inspection_date date,
  created_by uuid not null default auth.uid(), created_at timestamptz not null default now(), unique(company_id,id)
);
create table if not exists public.warranty_records (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  job_id uuid not null, warranty_type text not null, provider text not null default '',
  registration_status text not null default 'not_started', effective_on date, expires_on date,
  document_path text not null default '', created_at timestamptz not null default now(), unique(company_id,id)
);
create table if not exists public.service_tickets (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  job_id uuid, contact_id uuid, priority text not null default 'normal', status text not null default 'open',
  issue_type text not null default 'service', description text not null default '', assigned_to uuid,
  scheduled_for timestamptz, completed_at timestamptz, created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(), unique(company_id,id)
);
create table if not exists public.renewal_items (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  item_type text not null, owner_type text not null default 'company', owner_id uuid, title text not null,
  document_path text not null default '', expires_on date not null, reminder_days integer not null default 30,
  status text not null default 'active', created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(), unique(company_id,id)
);
create table if not exists public.integration_connections (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  provider text not null, category text not null, status text not null default 'not_connected',
  public_config jsonb not null default '{}'::jsonb,
  subscription_notice text not null default 'Additional subscription required. Contact HAMRIQ for information.',
  connected_by uuid, connected_at timestamptz, created_at timestamptz not null default now(),
  unique(company_id,id), unique(company_id,provider,category)
);
create index if not exists invoices_job on public.invoices(company_id,job_id);
create index if not exists payments_job on public.payment_transactions(company_id,job_id);
create index if not exists permits_job on public.permits(company_id,job_id);
create index if not exists warranty_job on public.warranty_records(company_id,job_id);
create index if not exists service_job on public.service_tickets(company_id,job_id);
create index if not exists renewals_due on public.renewal_items(company_id,expires_on,status);
