-- HAMRIQ jobsite staging / production readiness execution layer
-- Adds staging checklists, crew-ready packets, site access notes, dumpster/material placement,
-- blocker tracking, install-day go/no-go cards, notifications, and audit trail.

create table if not exists public.jobsite_staging_checklists_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  created_by uuid not null default auth.uid(),
  checklist_name text not null default 'Production readiness checklist',
  readiness_status text not null default 'draft' check (readiness_status in ('draft','in_review','ready','blocked','not_ready','completed','cancelled')),
  target_install_date date,
  assigned_production_user_id uuid,
  staging_notes text not null default '',
  required_items jsonb not null default '[]'::jsonb,
  completed_items jsonb not null default '[]'::jsonb,
  blocked_items jsonb not null default '[]'::jsonb,
  manager_review_required boolean not null default true,
  manager_approved_at timestamptz,
  manager_approved_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.crew_ready_packets_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  checklist_id uuid references public.jobsite_staging_checklists_deep(id) on delete set null,
  created_by uuid not null default auth.uid(),
  packet_status text not null default 'draft' check (packet_status in ('draft','sent_to_crew','acknowledged','needs_update','ready','blocked','archived')),
  crew_name text not null default '',
  crew_lead_name text not null default '',
  crew_lead_phone text not null default '',
  scope_summary text not null default '',
  material_summary text not null default '',
  safety_notes text not null default '',
  install_day_instructions text not null default '',
  packet_payload jsonb not null default '{}'::jsonb,
  crew_acknowledged_at timestamptz,
  crew_acknowledged_by text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.jobsite_access_notes_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  created_by uuid not null default auth.uid(),
  access_status text not null default 'unknown' check (access_status in ('unknown','clear','needs_confirmation','restricted','blocked')),
  gate_code text,
  driveway_notes text not null default '',
  parking_notes text not null default '',
  pet_notes text not null default '',
  homeowner_availability_notes text not null default '',
  hoa_or_neighbor_notes text not null default '',
  special_access_instructions text not null default '',
  confirmed_at timestamptz,
  confirmed_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.dumpster_material_placement_plans_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  created_by uuid not null default auth.uid(),
  placement_status text not null default 'draft' check (placement_status in ('draft','proposed','approved','needs_change','confirmed','blocked','completed')),
  dumpster_location text not null default '',
  material_drop_location text not null default '',
  trailer_location text not null default '',
  protection_required jsonb not null default '[]'::jsonb,
  overhead_obstructions text not null default '',
  driveway_protection_notes text not null default '',
  placement_photo_refs jsonb not null default '[]'::jsonb,
  approved_at timestamptz,
  approved_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.production_readiness_blockers_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  checklist_id uuid references public.jobsite_staging_checklists_deep(id) on delete set null,
  created_by uuid not null default auth.uid(),
  blocker_type text not null default 'other' check (blocker_type in ('permit','material','weather','crew','customer','payment','scope','access','dumpster','safety','other')),
  blocker_status text not null default 'open' check (blocker_status in ('open','assigned','waiting','resolved','waived','cancelled')),
  severity text not null default 'medium' check (severity in ('low','medium','high','critical')),
  title text not null,
  description text not null default '',
  assigned_to uuid,
  due_at timestamptz,
  resolved_at timestamptz,
  resolved_by uuid,
  resolution_notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.install_day_go_no_go_cards_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  checklist_id uuid references public.jobsite_staging_checklists_deep(id) on delete set null,
  created_by uuid not null default auth.uid(),
  decision_status text not null default 'pending' check (decision_status in ('pending','go','no_go','delayed','cancelled','completed')),
  install_date date not null,
  material_ready boolean not null default false,
  crew_ready boolean not null default false,
  permit_ready boolean not null default false,
  customer_ready boolean not null default false,
  access_ready boolean not null default false,
  weather_checked boolean not null default false,
  blockers_open integer not null default 0,
  decision_notes text not null default '',
  manager_decision_required boolean not null default true,
  decided_at timestamptz,
  decided_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.production_readiness_notifications_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  created_by uuid not null default auth.uid(),
  notification_type text not null default 'readiness_update' check (notification_type in ('readiness_update','blocked','ready','go','no_go','crew_packet','access_issue','placement_issue','material_issue','permit_issue')),
  recipient_role text not null default 'manager' check (recipient_role in ('manager','production','rep','crew','admin')),
  notification_status text not null default 'queued' check (notification_status in ('queued','sent','read','acknowledged','dismissed','failed')),
  title text not null,
  message text not null default '',
  action_url text,
  acknowledged_at timestamptz,
  acknowledged_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.jobsite_readiness_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  actor_user_id uuid not null default auth.uid(),
  event_type text not null default 'readiness_activity',
  event_summary text not null default '',
  event_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_jobsite_staging_checklists_deep_company_job on public.jobsite_staging_checklists_deep(company_id, job_id);
create index if not exists idx_crew_ready_packets_deep_company_job on public.crew_ready_packets_deep(company_id, job_id);
create index if not exists idx_jobsite_access_notes_deep_company_job on public.jobsite_access_notes_deep(company_id, job_id);
create index if not exists idx_dumpster_material_placement_plans_deep_company_job on public.dumpster_material_placement_plans_deep(company_id, job_id);
create index if not exists idx_production_readiness_blockers_deep_company_job on public.production_readiness_blockers_deep(company_id, job_id);
create index if not exists idx_install_day_go_no_go_cards_deep_company_job on public.install_day_go_no_go_cards_deep(company_id, job_id);
create index if not exists idx_production_readiness_notifications_deep_company_job on public.production_readiness_notifications_deep(company_id, job_id);
create index if not exists idx_jobsite_readiness_activity_events_deep_company_job on public.jobsite_readiness_activity_events_deep(company_id, job_id);

alter table public.jobsite_staging_checklists_deep enable row level security;
alter table public.crew_ready_packets_deep enable row level security;
alter table public.jobsite_access_notes_deep enable row level security;
alter table public.dumpster_material_placement_plans_deep enable row level security;
alter table public.production_readiness_blockers_deep enable row level security;
alter table public.install_day_go_no_go_cards_deep enable row level security;
alter table public.production_readiness_notifications_deep enable row level security;
alter table public.jobsite_readiness_activity_events_deep enable row level security;

-- Policies use existing HAMRIQ private helper functions.
