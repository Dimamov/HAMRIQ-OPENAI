-- Building-code intelligence / contract compliance execution layer
-- Live database migration source of truth: Supabase project baxgnpnfpzashcgiibwg.

create table if not exists public.building_code_rule_checks_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  check_name text not null,
  jurisdiction text,
  trade_area text not null default 'roofing',
  rule_source text,
  rule_summary text,
  status text not null default 'draft',
  findings_count integer not null default 0,
  ai_generated boolean not null default false,
  manager_review_required boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.jurisdiction_code_notes_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  jurisdiction text not null,
  municipality text,
  county text,
  state text,
  permit_office_contact jsonb not null default '{}'::jsonb,
  roofing_notes text,
  inspection_notes text,
  disclosure_notes text,
  effective_date date,
  status text not null default 'active',
  created_by uuid not null default auth.uid(),
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.code_compliance_findings_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  code_check_id uuid references public.building_code_rule_checks_deep(id) on delete cascade,
  finding_type text not null default 'code_issue',
  severity text not null default 'medium',
  title text not null,
  description text,
  recommended_action text,
  evidence jsonb not null default '[]'::jsonb,
  status text not null default 'open',
  ai_generated boolean not null default false,
  created_by uuid not null default auth.uid(),
  resolved_by uuid,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.contract_compliance_review_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  contract_id uuid,
  review_name text not null,
  review_scope text not null default 'full_contract',
  status text not null default 'queued',
  issue_count integer not null default 0,
  disclosure_count integer not null default 0,
  ai_generated boolean not null default false,
  manager_review_required boolean not null default true,
  summary jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.contract_risk_findings_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  review_run_id uuid references public.contract_compliance_review_runs_deep(id) on delete cascade,
  risk_category text not null,
  severity text not null default 'medium',
  title text not null,
  description text,
  suggested_fix text,
  status text not null default 'open',
  ai_generated boolean not null default false,
  created_by uuid not null default auth.uid(),
  resolved_by uuid,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.required_disclosure_tracking_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  review_run_id uuid references public.contract_compliance_review_runs_deep(id) on delete set null,
  disclosure_name text not null,
  disclosure_type text not null default 'contract',
  required_by text,
  due_context text,
  status text not null default 'required',
  customer_visible boolean not null default false,
  manager_review_required boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.compliance_manager_approval_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  source_table text not null,
  source_record_id uuid not null,
  approval_type text not null default 'code_or_contract_compliance',
  requested_decision text not null default 'approve',
  status text not null default 'pending',
  request_notes text,
  decision_notes text,
  created_by uuid not null default auth.uid(),
  decided_by uuid,
  decided_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.code_contract_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  event_type text not null,
  source_table text,
  source_record_id uuid,
  actor_id uuid not null default auth.uid(),
  event_summary text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- RLS and policies are applied in the live Supabase migration.