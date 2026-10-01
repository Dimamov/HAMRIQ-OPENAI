-- HAMRIQ inspection completeness / AI scope builder execution layer
-- Live Supabase migration applied 2026-10-01.

create table if not exists public.inspection_checklist_templates_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  template_name text not null,
  trade_type text not null default 'roofing',
  required_sections jsonb not null default '[]'::jsonb,
  required_photo_rules jsonb not null default '[]'::jsonb,
  is_active boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.inspection_completeness_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  template_id uuid references public.inspection_checklist_templates_deep(id) on delete set null,
  run_status text not null default 'draft',
  completeness_score numeric(5,2) not null default 0,
  missing_count integer not null default 0,
  created_by uuid not null default auth.uid(),
  assigned_rep_user_id uuid,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.inspection_missing_item_findings_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  completeness_run_id uuid references public.inspection_completeness_runs_deep(id) on delete cascade,
  finding_type text not null default 'missing_required_item',
  severity text not null default 'medium',
  description text not null,
  suggested_fix text,
  status text not null default 'open',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ai_scope_builder_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  inspection_run_id uuid references public.inspection_completeness_runs_deep(id) on delete set null,
  ai_status text not null default 'drafted',
  draft_scope jsonb not null default '{}'::jsonb,
  assumptions jsonb not null default '[]'::jsonb,
  confidence_score numeric(5,2) not null default 0,
  requires_human_review boolean not null default true,
  created_by uuid not null default auth.uid(),
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.scope_draft_line_items_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  scope_builder_run_id uuid references public.ai_scope_builder_runs_deep(id) on delete cascade,
  line_item_code text,
  line_item_name text not null,
  quantity numeric(12,2),
  unit text,
  reason text,
  evidence_summary text,
  review_status text not null default 'needs_review',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.scope_required_evidence_links_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  scope_line_item_id uuid references public.scope_draft_line_items_deep(id) on delete cascade,
  evidence_type text not null default 'photo',
  evidence_reference text,
  requirement_status text not null default 'missing',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.scope_human_review_queue_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  scope_builder_run_id uuid references public.ai_scope_builder_runs_deep(id) on delete cascade,
  review_type text not null default 'scope_review',
  priority text not null default 'normal',
  status text not null default 'open',
  assigned_manager_user_id uuid,
  decision_notes text,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.scope_builder_learning_records_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  scope_builder_run_id uuid references public.ai_scope_builder_runs_deep(id) on delete set null,
  learning_type text not null default 'manager_correction',
  original_value jsonb not null default '{}'::jsonb,
  corrected_value jsonb not null default '{}'::jsonb,
  manager_approved boolean not null default false,
  approved_by uuid,
  approved_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.inspection_checklist_templates_deep enable row level security;
alter table public.inspection_completeness_runs_deep enable row level security;
alter table public.inspection_missing_item_findings_deep enable row level security;
alter table public.ai_scope_builder_runs_deep enable row level security;
alter table public.scope_draft_line_items_deep enable row level security;
alter table public.scope_required_evidence_links_deep enable row level security;
alter table public.scope_human_review_queue_deep enable row level security;
alter table public.scope_builder_learning_records_deep enable row level security;

-- Full RLS policies are applied in the live database. Database is source of truth.