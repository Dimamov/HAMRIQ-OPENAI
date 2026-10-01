create table if not exists public.time_clock_sessions (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  employee_id uuid not null,
  job_id uuid,
  clock_in_at timestamptz not null default now(),
  clock_out_at timestamptz,
  status text not null default 'open' check (status in ('open','submitted','approved','rejected','exported')),
  source text not null default 'mobile' check (source in ('mobile','web','manager_adjustment','import')),
  clock_in_location jsonb not null default '{}'::jsonb,
  clock_out_location jsonb not null default '{}'::jsonb,
  manager_note text not null default '',
  employee_note text not null default '',
  approved_by uuid,
  approved_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.geofence_clock_events (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  time_clock_session_id uuid references public.time_clock_sessions(id) on delete cascade,
  employee_id uuid not null,
  job_id uuid,
  event_type text not null check (event_type in ('entered_job_area','left_job_area','clock_in_inside','clock_in_outside','clock_out_inside','clock_out_outside','exception')),
  distance_from_job_meters numeric(10,2),
  location_payload jsonb not null default '{}'::jsonb,
  exception_reason text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.mileage_trip_logs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  employee_id uuid not null,
  job_id uuid,
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  start_location text not null default '',
  end_location text not null default '',
  miles numeric(10,2) not null default 0,
  reimbursement_cents bigint not null default 0,
  status text not null default 'draft' check (status in ('draft','submitted','approved','rejected','exported')),
  route_payload jsonb not null default '{}'::jsonb,
  manager_note text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.expense_receipt_items (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  expense_reimbursement_id uuid,
  employee_id uuid not null,
  job_id uuid,
  vendor_name text not null default '',
  receipt_date date,
  category text not null default 'other',
  amount_cents bigint not null default 0,
  tax_cents bigint not null default 0,
  status text not null default 'draft' check (status in ('draft','submitted','approved','rejected','exported')),
  receipt_file_id uuid,
  ai_extracted_payload jsonb not null default '{}'::jsonb,
  manager_note text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.payroll_export_lines (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  payroll_export_id uuid,
  employee_id uuid not null,
  line_type text not null check (line_type in ('regular_hours','overtime_hours','commission','mileage','expense_reimbursement','bonus','deduction','adjustment')),
  source_table text not null default '',
  source_id uuid,
  quantity numeric(12,2) not null default 0,
  amount_cents bigint not null default 0,
  status text not null default 'pending' check (status in ('pending','reviewed','exported','error','void')),
  export_payload jsonb not null default '{}'::jsonb,
  error_message text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.commission_adjustments (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  employee_id uuid not null,
  job_id uuid,
  commission_statement_id uuid,
  adjustment_type text not null check (adjustment_type in ('bonus','chargeback','split','correction','holdback','release','manual')),
  amount_cents bigint not null default 0,
  reason text not null default '',
  status text not null default 'draft' check (status in ('draft','submitted','approved','rejected','posted')),
  approved_by uuid,
  approved_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.reimbursement_policy_rules (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  rule_name text not null,
  rule_type text not null check (rule_type in ('mileage_rate','expense_category_limit','receipt_required','manager_approval_required','per_diem')),
  is_active boolean not null default true,
  amount_cents bigint not null default 0,
  numeric_value numeric(12,4) not null default 0,
  rule_payload jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.payroll_exception_reviews (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  employee_id uuid not null,
  source_table text not null,
  source_id uuid,
  exception_type text not null check (exception_type in ('missing_clock_out','geofence_mismatch','duplicate_mileage','large_expense','commission_conflict','export_error','manual_review')),
  severity text not null default 'medium' check (severity in ('low','medium','high','critical')),
  status text not null default 'open' check (status in ('open','in_review','resolved','dismissed')),
  summary text not null default '',
  resolution_note text not null default '',
  resolved_by uuid,
  resolved_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.time_clock_sessions enable row level security;
alter table public.geofence_clock_events enable row level security;
alter table public.mileage_trip_logs enable row level security;
alter table public.expense_receipt_items enable row level security;
alter table public.payroll_export_lines enable row level security;
alter table public.commission_adjustments enable row level security;
alter table public.reimbursement_policy_rules enable row level security;
alter table public.payroll_exception_reviews enable row level security;

-- Full live migration also includes indexes, grants, and policies.
