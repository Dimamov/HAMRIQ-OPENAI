-- HAMRIQ approved production, billing, transfer, and profitability foundation.
-- Applied live to Supabase project baxgnpnfpzashcgiibwg.

create table if not exists public.progress_billings (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid not null,
  billing_period text not null default '',
  contract_value_cents bigint not null default 0,
  work_completed_cents bigint not null default 0,
  stored_materials_cents bigint not null default 0,
  previous_billings_cents bigint not null default 0,
  current_due_cents bigint not null default 0,
  retainage_cents bigint not null default 0,
  balance_remaining_cents bigint not null default 0,
  status text not null default 'draft',
  attachments jsonb not null default '[]'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,job_id) references public.jobs(company_id,id),
  foreign key(created_by) references public.users(id)
);

create table if not exists public.rfis (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid not null,
  title text not null,
  question text not null default '',
  response text not null default '',
  status text not null default 'created',
  response_due_on date,
  cost_impact_cents bigint,
  schedule_impact_days integer,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,job_id) references public.jobs(company_id,id),
  foreign key(created_by) references public.users(id)
);

create table if not exists public.submittals (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid not null,
  title text not null,
  package_path text not null default '',
  status text not null default 'prepared',
  due_on date,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,job_id) references public.jobs(company_id,id),
  foreign key(created_by) references public.users(id)
);

create table if not exists public.punch_items (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid not null,
  title text not null,
  description text not null default '',
  owner_id uuid,
  due_on date,
  status text not null default 'open',
  photo_paths jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,job_id) references public.jobs(company_id,id),
  foreign key(owner_id) references public.users(id)
);

create table if not exists public.closeout_packages (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid not null,
  status text not null default 'assembling',
  required_items jsonb not null default '[]'::jsonb,
  package_path text not null default '',
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,job_id) references public.jobs(company_id,id)
);

create table if not exists public.production_issues (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid not null,
  issue_type text not null default 'Other',
  severity text not null default 'normal',
  description text not null default '',
  status text not null default 'open',
  reported_by uuid not null default auth.uid(),
  assigned_to uuid,
  photo_paths jsonb not null default '[]'::jsonb,
  resolution text not null default '',
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  unique(company_id,id),
  foreign key(company_id,job_id) references public.jobs(company_id,id),
  foreign key(reported_by) references public.users(id),
  foreign key(assigned_to) references public.users(id)
);

create table if not exists public.hidden_conditions (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid not null,
  condition_type text not null,
  quantity numeric,
  unit text not null default '',
  price_cents bigint not null default 0,
  photo_paths jsonb not null default '[]'::jsonb,
  approval_status text not null default 'needs_review',
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,job_id) references public.jobs(company_id,id)
);

create table if not exists public.lead_transfers (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  contact_id uuid,
  job_id uuid,
  from_user_id uuid,
  to_user_id uuid not null,
  reason text not null default '',
  status text not null default 'completed',
  requested_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,contact_id) references public.contacts(company_id,id),
  foreign key(company_id,job_id) references public.jobs(company_id,id),
  foreign key(from_user_id) references public.users(id),
  foreign key(to_user_id) references public.users(id),
  foreign key(requested_by) references public.users(id)
);

create table if not exists public.rep_credit_assignments (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid not null,
  lead_generator_id uuid,
  sales_rep_id uuid,
  account_owner_id uuid,
  production_rep_id uuid,
  commission_rule jsonb not null default '{}'::jsonb,
  changed_by uuid not null default auth.uid(),
  change_reason text not null default '',
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,job_id) references public.jobs(company_id,id),
  foreign key(lead_generator_id) references public.users(id),
  foreign key(sales_rep_id) references public.users(id),
  foreign key(account_owner_id) references public.users(id),
  foreign key(production_rep_id) references public.users(id),
  foreign key(changed_by) references public.users(id)
);

create table if not exists public.job_profitability_reviews (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid not null,
  estimated_profit_cents bigint not null default 0,
  final_profit_cents bigint not null default 0,
  variance_reasons jsonb not null default '[]'::jsonb,
  manager_approved_learning boolean not null default false,
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,job_id) references public.jobs(company_id,id)
);
