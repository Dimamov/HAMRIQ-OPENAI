-- Payment / final invoice collection layer
-- Tracks final invoice packets, deductible status, insurance balances, payment requests, delivery, disputes, closeout-payment approval, and audit events.

create table if not exists public.final_invoice_packets_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  status text not null default 'draft' check (status in ('draft','review','approved','sent','paid','disputed','void')),
  invoice_total_cents bigint not null default 0,
  deductible_due_cents bigint not null default 0,
  insurance_balance_due_cents bigint not null default 0,
  homeowner_balance_due_cents bigint not null default 0,
  line_items jsonb not null default '[]'::jsonb,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  approved_by uuid,
  approved_at timestamptz,
  sent_at timestamptz,
  paid_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.deductible_tracking_records_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  invoice_packet_id uuid references public.final_invoice_packets_deep(id) on delete set null,
  amount_due_cents bigint not null default 0,
  amount_received_cents bigint not null default 0,
  status text not null default 'open' check (status in ('open','requested','partial','received','manager_exception','disputed')),
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.insurance_balance_tracking_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  invoice_packet_id uuid references public.final_invoice_packets_deep(id) on delete set null,
  carrier_name text not null default '',
  claim_number text not null default '',
  recoverable_depreciation_due_cents bigint not null default 0,
  supplement_balance_due_cents bigint not null default 0,
  total_balance_due_cents bigint not null default 0,
  status text not null default 'pending' check (status in ('pending','requested','partial','received','short_paid','disputed','closed')),
  expected_payment_date date,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.payment_request_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  invoice_packet_id uuid references public.final_invoice_packets_deep(id) on delete set null,
  request_type text not null default 'final_invoice' check (request_type in ('deposit','deductible','progress_payment','final_invoice','insurance_balance','change_order','other')),
  recipient_type text not null default 'homeowner' check (recipient_type in ('homeowner','carrier','mortgage_company','other')),
  amount_requested_cents bigint not null default 0,
  status text not null default 'draft' check (status in ('draft','review','approved','sent','viewed','paid','partial','failed','cancelled')),
  delivery_channel text not null default 'portal' check (delivery_channel in ('portal','email','sms','manual','other')),
  sent_at timestamptz,
  viewed_at timestamptz,
  paid_at timestamptz,
  created_by uuid not null default auth.uid(),
  approved_by uuid,
  approved_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.final_invoice_delivery_records_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  invoice_packet_id uuid not null references public.final_invoice_packets_deep(id) on delete cascade,
  delivery_status text not null default 'pending' check (delivery_status in ('pending','delivered','viewed','failed','acknowledged')),
  delivered_to text not null default '',
  delivery_channel text not null default 'portal' check (delivery_channel in ('portal','email','sms','manual','other')),
  document_links jsonb not null default '[]'::jsonb,
  delivered_at timestamptz,
  viewed_at timestamptz,
  acknowledged_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.payment_dispute_review_cases_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  invoice_packet_id uuid references public.final_invoice_packets_deep(id) on delete set null,
  dispute_source text not null default 'homeowner' check (dispute_source in ('homeowner','carrier','mortgage_company','internal','other')),
  disputed_amount_cents bigint not null default 0,
  reason text not null default '',
  status text not null default 'open' check (status in ('open','manager_review','waiting_on_info','resolved','escalated','closed')),
  resolution_notes text not null default '',
  created_by uuid not null default auth.uid(),
  assigned_to uuid,
  resolved_by uuid,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.closeout_payment_approval_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  invoice_packet_id uuid references public.final_invoice_packets_deep(id) on delete set null,
  approval_status text not null default 'pending' check (approval_status in ('pending','approved','rejected','needs_followup','blocked')),
  invoice_paid boolean not null default false,
  deductible_collected boolean not null default false,
  insurance_balance_closed boolean not null default false,
  blocker_reason text not null default '',
  created_by uuid not null default auth.uid(),
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.payment_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  invoice_packet_id uuid references public.final_invoice_packets_deep(id) on delete set null,
  event_type text not null default 'note',
  event_title text not null default '',
  event_detail text not null default '',
  event_payload jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create index if not exists final_invoice_packets_deep_company_job_idx on public.final_invoice_packets_deep(company_id, job_id);
create index if not exists deductible_tracking_records_deep_company_job_idx on public.deductible_tracking_records_deep(company_id, job_id);
create index if not exists insurance_balance_tracking_deep_company_job_idx on public.insurance_balance_tracking_deep(company_id, job_id);
create index if not exists payment_request_runs_deep_company_job_idx on public.payment_request_runs_deep(company_id, job_id);
create index if not exists final_invoice_delivery_records_deep_company_job_idx on public.final_invoice_delivery_records_deep(company_id, job_id);
create index if not exists payment_dispute_review_cases_deep_company_job_idx on public.payment_dispute_review_cases_deep(company_id, job_id);
create index if not exists closeout_payment_approval_runs_deep_company_job_idx on public.closeout_payment_approval_runs_deep(company_id, job_id);
create index if not exists payment_activity_events_deep_company_job_idx on public.payment_activity_events_deep(company_id, job_id);

alter table public.final_invoice_packets_deep enable row level security;
alter table public.deductible_tracking_records_deep enable row level security;
alter table public.insurance_balance_tracking_deep enable row level security;
alter table public.payment_request_runs_deep enable row level security;
alter table public.final_invoice_delivery_records_deep enable row level security;
alter table public.payment_dispute_review_cases_deep enable row level security;
alter table public.closeout_payment_approval_runs_deep enable row level security;
alter table public.payment_activity_events_deep enable row level security;

grant select, insert, update on public.final_invoice_packets_deep to authenticated;
grant select, insert, update on public.deductible_tracking_records_deep to authenticated;
grant select, insert, update on public.insurance_balance_tracking_deep to authenticated;
grant select, insert, update on public.payment_request_runs_deep to authenticated;
grant select, insert, update on public.final_invoice_delivery_records_deep to authenticated;
grant select, insert, update on public.payment_dispute_review_cases_deep to authenticated;
grant select, insert, update on public.closeout_payment_approval_runs_deep to authenticated;
grant select, insert, update on public.payment_activity_events_deep to authenticated;

-- Policies are installed in the live database through payment_final_invoice_layer_rls.
