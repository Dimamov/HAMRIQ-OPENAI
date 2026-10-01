-- HAMRIQ production handoff/readiness execution layer
-- Adds one-tap handoff packages, homeowner confirmations, readiness reviews,
-- install packets, crew handoffs, preflight exceptions, and audit events.

create table if not exists public.production_handoff_packages_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  source_stage text not null default 'build_contract_signed',
  package_status text not null default 'draft' check (package_status in ('draft','ready_for_review','approved','sent_to_production','blocked','cancelled')),
  handoff_summary text not null default '',
  scope_snapshot jsonb not null default '{}'::jsonb,
  material_snapshot jsonb not null default '{}'::jsonb,
  customer_commitments jsonb not null default '[]'::jsonb,
  open_risks jsonb not null default '[]'::jsonb,
  requires_manager_review boolean not null default true,
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.prebuild_homeowner_confirmation_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  handoff_package_id uuid references public.production_handoff_packages_deep(id) on delete set null,
  confirmation_status text not null default 'not_started' check (confirmation_status in ('not_started','sent','partially_confirmed','confirmed','needs_followup','declined','cancelled')),
  homeowner_name text not null default '',
  contact_method text not null default 'sms' check (contact_method in ('sms','email','phone','portal','in_person','other')),
  confirmed_items jsonb not null default '[]'::jsonb,
  unresolved_items jsonb not null default '[]'::jsonb,
  customer_notes text not null default '',
  confirmed_at timestamptz,
  created_by uuid not null default auth.uid(),
  assigned_to uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.production_readiness_reviews_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  handoff_package_id uuid references public.production_handoff_packages_deep(id) on delete set null,
  review_status text not null default 'pending' check (review_status in ('pending','passed','failed','blocked','waived','needs_manager_review')),
  readiness_score numeric(6,2) not null default 0,
  missing_requirements jsonb not null default '[]'::jsonb,
  passed_requirements jsonb not null default '[]'::jsonb,
  blocker_summary text not null default '',
  manager_override_reason text not null default '',
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.material_scope_lock_reviews_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  handoff_package_id uuid references public.production_handoff_packages_deep(id) on delete set null,
  lock_status text not null default 'unlocked' check (lock_status in ('unlocked','ready_to_lock','locked','unlock_requested','unlocked_by_manager','blocked')),
  locked_scope jsonb not null default '{}'::jsonb,
  locked_materials jsonb not null default '{}'::jsonb,
  price_snapshot_cents bigint not null default 0,
  unlock_reason text not null default '',
  locked_by uuid,
  locked_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.install_day_packet_generations_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  handoff_package_id uuid references public.production_handoff_packages_deep(id) on delete set null,
  packet_status text not null default 'draft' check (packet_status in ('draft','generated','sent_to_crew','sent_to_homeowner','revised','void')),
  packet_sections jsonb not null default '[]'::jsonb,
  crew_notes text not null default '',
  homeowner_notes text not null default '',
  file_url text not null default '',
  generated_by uuid,
  generated_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.crew_assignment_handoffs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  handoff_package_id uuid references public.production_handoff_packages_deep(id) on delete set null,
  crew_id uuid,
  crew_lead_name text not null default '',
  handoff_status text not null default 'not_sent' check (handoff_status in ('not_sent','sent','acknowledged','questions_open','accepted','declined','reassigned')),
  assignment_notes text not null default '',
  open_questions jsonb not null default '[]'::jsonb,
  acknowledged_by uuid,
  acknowledged_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.production_preflight_exceptions_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  handoff_package_id uuid references public.production_handoff_packages_deep(id) on delete set null,
  exception_type text not null default 'other' check (exception_type in ('missing_material','scope_conflict','customer_unconfirmed','permit_issue','payment_issue','crew_issue','weather_risk','other')),
  severity text not null default 'medium' check (severity in ('low','medium','high','critical')),
  exception_status text not null default 'open' check (exception_status in ('open','assigned','resolved','waived','blocked')),
  description text not null default '',
  resolution_notes text not null default '',
  assigned_to uuid,
  resolved_by uuid,
  resolved_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.production_handoff_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  handoff_package_id uuid references public.production_handoff_packages_deep(id) on delete set null,
  event_type text not null,
  event_summary text not null default '',
  event_payload jsonb not null default '{}'::jsonb,
  actor_user_id uuid default auth.uid(),
  created_at timestamptz not null default now()
);

create index if not exists idx_production_handoff_packages_deep_company_job on public.production_handoff_packages_deep(company_id, job_id);
create index if not exists idx_prebuild_homeowner_confirmation_runs_deep_company_job on public.prebuild_homeowner_confirmation_runs_deep(company_id, job_id);
create index if not exists idx_production_readiness_reviews_deep_company_job on public.production_readiness_reviews_deep(company_id, job_id);
create index if not exists idx_material_scope_lock_reviews_deep_company_job on public.material_scope_lock_reviews_deep(company_id, job_id);
create index if not exists idx_install_day_packet_generations_deep_company_job on public.install_day_packet_generations_deep(company_id, job_id);
create index if not exists idx_crew_assignment_handoffs_deep_company_job on public.crew_assignment_handoffs_deep(company_id, job_id);
create index if not exists idx_production_preflight_exceptions_deep_company_job on public.production_preflight_exceptions_deep(company_id, job_id);
create index if not exists idx_production_handoff_activity_events_deep_company_job on public.production_handoff_activity_events_deep(company_id, job_id);

alter table public.production_handoff_packages_deep enable row level security;
alter table public.prebuild_homeowner_confirmation_runs_deep enable row level security;
alter table public.production_readiness_reviews_deep enable row level security;
alter table public.material_scope_lock_reviews_deep enable row level security;
alter table public.install_day_packet_generations_deep enable row level security;
alter table public.crew_assignment_handoffs_deep enable row level security;
alter table public.production_preflight_exceptions_deep enable row level security;
alter table public.production_handoff_activity_events_deep enable row level security;

revoke all on public.production_handoff_packages_deep from anon, authenticated;
revoke all on public.prebuild_homeowner_confirmation_runs_deep from anon, authenticated;
revoke all on public.production_readiness_reviews_deep from anon, authenticated;
revoke all on public.material_scope_lock_reviews_deep from anon, authenticated;
revoke all on public.install_day_packet_generations_deep from anon, authenticated;
revoke all on public.crew_assignment_handoffs_deep from anon, authenticated;
revoke all on public.production_preflight_exceptions_deep from anon, authenticated;
revoke all on public.production_handoff_activity_events_deep from anon, authenticated;

grant select, insert, update on public.production_handoff_packages_deep to authenticated;
grant select, insert, update on public.prebuild_homeowner_confirmation_runs_deep to authenticated;
grant select, insert, update on public.production_readiness_reviews_deep to authenticated;
grant select, insert, update on public.material_scope_lock_reviews_deep to authenticated;
grant select, insert, update on public.install_day_packet_generations_deep to authenticated;
grant select, insert, update on public.crew_assignment_handoffs_deep to authenticated;
grant select, insert, update on public.production_preflight_exceptions_deep to authenticated;
grant select, insert on public.production_handoff_activity_events_deep to authenticated;

-- Policies are applied in production through the live migration.
-- Database source of truth includes job-scoped and manager-reviewed access checks.