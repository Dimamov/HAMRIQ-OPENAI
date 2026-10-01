-- HAMRIQ insurance-money and compliance layer
-- Applied live to Supabase project baxgnpnfpzashcgiibwg.
-- Adds supplement recovery, recoverable depreciation, mortgage check tracking,
-- deductible compliance, lien/notice/rescission deadline tracking,
-- e-sign audit events, and payment reconciliation controls.

create table if not exists public.supplement_recovery_items (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  item_type text not null default 'supplement',
  description text not null,
  amount_requested numeric(12,2) not null default 0,
  amount_approved numeric(12,2) not null default 0,
  status text not null default 'draft',
  evidence_summary text not null default '',
  human_review_required boolean not null default true,
  reviewed_by uuid,
  reviewed_at timestamptz,
  submitted_at timestamptz,
  response_due_on date,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key (company_id, job_id) references public.jobs(company_id,id) on delete cascade
);

create table if not exists public.depreciation_trackers (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  recoverable_depreciation_amount numeric(12,2) not null default 0,
  non_recoverable_depreciation_amount numeric(12,2) not null default 0,
  recovered_amount numeric(12,2) not null default 0,
  status text not null default 'not_started',
  carrier_requirements text not null default '',
  final_invoice_sent_at timestamptz,
  proof_of_completion_sent_at timestamptz,
  last_follow_up_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key (company_id, job_id) references public.jobs(company_id,id) on delete cascade
);

create table if not exists public.mortgage_check_trackers (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  check_number text,
  payees text[] not null default '{}',
  check_amount numeric(12,2) not null default 0,
  status text not null default 'expected',
  received_at timestamptz,
  sent_to_mortgage_company_at timestamptz,
  endorsed_at timestamptz,
  deposited_at timestamptz,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key (company_id, job_id) references public.jobs(company_id,id) on delete cascade
);

create table if not exists public.deductible_compliance_records (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  deductible_amount numeric(12,2) not null default 0,
  collected_amount numeric(12,2) not null default 0,
  compliance_status text not null default 'pending',
  manager_notes text not null default '',
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key (company_id, job_id) references public.jobs(company_id,id) on delete cascade
);

create table if not exists public.deadline_trackers (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid,
  contact_id uuid,
  deadline_type text not null,
  title text not null,
  due_on date not null,
  status text not null default 'open',
  legal_review_required boolean not null default false,
  completed_at timestamptz,
  completed_by uuid,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key (company_id, job_id) references public.jobs(company_id,id) on delete cascade,
  foreign key (company_id, contact_id) references public.contacts(company_id,id) on delete cascade
);

create table if not exists public.esign_audit_events (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid,
  contact_id uuid,
  document_title text not null,
  signer_name text not null,
  signer_email text,
  signer_phone text,
  event_type text not null,
  event_at timestamptz not null default now(),
  ip_address text,
  user_agent text,
  disclosure_text text not null default '',
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key (company_id, job_id) references public.jobs(company_id,id) on delete cascade,
  foreign key (company_id, contact_id) references public.contacts(company_id,id) on delete cascade
);

create table if not exists public.payment_reconciliation_items (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  source text not null default 'carrier',
  expected_amount numeric(12,2) not null default 0,
  received_amount numeric(12,2) not null default 0,
  variance_amount numeric(12,2) generated always as (received_amount - expected_amount) stored,
  status text not null default 'unmatched',
  matched_payment_id uuid,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key (company_id, job_id) references public.jobs(company_id,id) on delete cascade
);

alter table public.supplement_recovery_items enable row level security;
alter table public.depreciation_trackers enable row level security;
alter table public.mortgage_check_trackers enable row level security;
alter table public.deductible_compliance_records enable row level security;
alter table public.deadline_trackers enable row level security;
alter table public.esign_audit_events enable row level security;
alter table public.payment_reconciliation_items enable row level security;

-- Access model:
-- job-linked insurance money records follow job access;
-- deductible compliance and payment reconciliation are manager-controlled;
-- deadline and e-sign audit visibility follows company membership.
