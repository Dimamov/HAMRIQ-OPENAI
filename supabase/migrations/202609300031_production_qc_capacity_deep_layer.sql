-- HAMRIQ production QC/capacity deep layer
-- Adds job readiness gates, QC checklist templates/runs/items, production punch items,
-- material waste records, live production feed events, and capacity allocations.

create table if not exists public.job_readiness_gates (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  gate_name text not null default 'production_readiness',
  status text not null default 'open',
  blocker_summary text,
  required_before date,
  approved_by uuid,
  approved_at timestamptz,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.job_readiness_gate_items (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  gate_id uuid not null references public.job_readiness_gates(id) on delete cascade,
  job_id uuid not null,
  item_name text not null,
  item_type text not null default 'checklist',
  status text not null default 'pending',
  required boolean not null default true,
  evidence_url text,
  notes text,
  completed_by uuid,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.qc_checklist_templates (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null,
  job_type text not null default 'roofing',
  required_items jsonb not null default '[]'::jsonb,
  active boolean not null default true,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.qc_checklist_runs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  template_id uuid references public.qc_checklist_templates(id),
  status text not null default 'in_progress',
  started_by uuid default auth.uid(),
  started_at timestamptz not null default now(),
  completed_by uuid,
  completed_at timestamptz,
  manager_approved_by uuid,
  manager_approved_at timestamptz
);

create table if not exists public.qc_checklist_run_items (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  run_id uuid not null references public.qc_checklist_runs(id) on delete cascade,
  job_id uuid not null,
  item_name text not null,
  status text not null default 'pending',
  required_photo boolean not null default false,
  photo_url text,
  notes text,
  checked_by uuid,
  checked_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.production_punch_items (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  qc_run_id uuid references public.qc_checklist_runs(id),
  title text not null,
  description text,
  priority text not null default 'normal',
  status text not null default 'open',
  assigned_to uuid,
  due_date date,
  evidence_before_url text,
  evidence_after_url text,
  created_by uuid default auth.uid(),
  resolved_by uuid,
  resolved_at timestamptz,
  verified_by uuid,
  verified_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.material_waste_records (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  material_name text not null,
  estimated_quantity numeric(12,2) not null default 0,
  ordered_quantity numeric(12,2) not null default 0,
  used_quantity numeric(12,2) not null default 0,
  returned_quantity numeric(12,2) not null default 0,
  wasted_quantity numeric(12,2) not null default 0,
  unit text not null default 'each',
  waste_reason text,
  ai_learning_note text,
  manager_review_status text not null default 'pending',
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.production_live_feed_events (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  event_type text not null,
  headline text not null,
  details jsonb not null default '{}'::jsonb,
  visible_to_customer boolean not null default false,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.production_capacity_allocations (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  plan_id uuid references public.production_capacity_plans(id) on delete cascade,
  crew_id uuid,
  planned_date date not null,
  capacity_units numeric(12,2) not null default 0,
  reserved_units numeric(12,2) not null default 0,
  notes text,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);

-- Live project migration also includes indexes, job/company-scoped RLS policies, grants,
-- and compound job foreign keys where the existing schema permits them.
