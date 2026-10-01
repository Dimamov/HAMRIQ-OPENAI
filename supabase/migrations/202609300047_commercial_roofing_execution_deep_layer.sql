-- HAMRIQ commercial roofing execution deep layer
-- Adds commercial bid packages, roof asset inspections, maintenance visits,
-- RFI/submittal workflows, progress billing, retainage, and closeout deliverables.

create table if not exists public.commercial_bid_packages_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid references public.jobs(id),
  commercial_bid_id uuid,
  package_name text not null,
  bid_status text not null default 'draft' check (bid_status in ('draft','review_needed','submitted','won','lost','withdrawn')),
  due_at timestamptz,
  submitted_at timestamptz,
  bid_amount_cents bigint not null default 0,
  alternates jsonb not null default '[]'::jsonb,
  exclusions jsonb not null default '[]'::jsonb,
  scope_summary text not null default '',
  ai_generated boolean not null default false,
  human_review_required boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.commercial_roof_asset_inspections_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  property_id uuid,
  roof_asset_id uuid,
  job_id uuid references public.jobs(id),
  inspected_by uuid not null default auth.uid(),
  inspection_status text not null default 'open' check (inspection_status in ('open','in_progress','complete','review_needed')),
  roof_condition text not null default '',
  priority text not null default 'normal' check (priority in ('low','normal','high','urgent')),
  leak_locations jsonb not null default '[]'::jsonb,
  membrane_findings jsonb not null default '[]'::jsonb,
  flashing_findings jsonb not null default '[]'::jsonb,
  drainage_findings jsonb not null default '[]'::jsonb,
  recommended_actions jsonb not null default '[]'::jsonb,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.commercial_maintenance_visit_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  maintenance_agreement_id uuid,
  property_id uuid,
  job_id uuid references public.jobs(id),
  scheduled_for date,
  completed_at timestamptz,
  visit_status text not null default 'scheduled' check (visit_status in ('scheduled','in_progress','complete','missed','rescheduled','cancelled')),
  checklist_results jsonb not null default '{}'::jsonb,
  photos_required boolean not null default true,
  followup_required boolean not null default false,
  followup_notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.commercial_rfi_threads_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid references public.jobs(id),
  rfi_id uuid,
  rfi_number text not null default '',
  subject text not null,
  question text not null default '',
  answer text not null default '',
  rfi_status text not null default 'draft' check (rfi_status in ('draft','submitted','answered','closed','void')),
  submitted_at timestamptz,
  answered_at timestamptz,
  due_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.commercial_submittal_packages_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid references public.jobs(id),
  submittal_id uuid,
  package_name text not null,
  submittal_type text not null default 'product_data' check (submittal_type in ('product_data','shop_drawing','sample','warranty','safety','other')),
  submittal_status text not null default 'draft' check (submittal_status in ('draft','submitted','approved','approved_as_noted','revise_resubmit','rejected','closed')),
  submitted_at timestamptz,
  reviewed_at timestamptz,
  reviewer_notes text not null default '',
  attachments jsonb not null default '[]'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.commercial_progress_billing_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid references public.jobs(id),
  progress_billing_id uuid,
  billing_period_start date,
  billing_period_end date,
  billing_status text not null default 'draft' check (billing_status in ('draft','submitted','approved','paid','disputed','void')),
  percent_complete numeric(6,2) not null default 0,
  amount_requested_cents bigint not null default 0,
  amount_approved_cents bigint not null default 0,
  amount_paid_cents bigint not null default 0,
  submitted_at timestamptz,
  paid_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.commercial_retainage_trackers_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid references public.jobs(id),
  billing_event_id uuid,
  retainage_percent numeric(6,2) not null default 0,
  retainage_held_cents bigint not null default 0,
  retainage_released_cents bigint not null default 0,
  retainage_status text not null default 'held' check (retainage_status in ('held','partially_released','released','disputed','waived')),
  expected_release_date date,
  released_at timestamptz,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.commercial_closeout_deliverables_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid references public.jobs(id),
  closeout_package_id uuid,
  deliverable_type text not null default 'warranty' check (deliverable_type in ('warranty','as_built','photo_report','lien_waiver','maintenance_manual','permit','inspection','other')),
  deliverable_status text not null default 'needed' check (deliverable_status in ('needed','requested','received','approved','rejected','not_required')),
  due_at timestamptz,
  completed_at timestamptz,
  rejection_reason text not null default '',
  attachments jsonb not null default '[]'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- indexes, grants, and RLS policies are applied in production with this migration.
