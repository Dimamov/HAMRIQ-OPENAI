-- HAMRIQ safety / incident execution deep layer
-- Covers agreed features: toolbox talks, required acknowledgments, site safety inspections,
-- incident reporting, corrective actions, PPE checks, stop-work follow-through, and activity history.

create table if not exists public.toolbox_talk_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  topic text not null,
  status text not null default 'draft' check (status in ('draft','scheduled','in_progress','completed','archived')),
  scheduled_for timestamptz,
  completed_at timestamptz,
  facilitator_user_id uuid,
  required_roles jsonb not null default '[]'::jsonb,
  talk_materials jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.toolbox_talk_acknowledgments_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  toolbox_talk_run_id uuid not null references public.toolbox_talk_runs_deep(id) on delete cascade,
  user_id uuid not null,
  acknowledgment_status text not null default 'pending' check (acknowledgment_status in ('pending','acknowledged','missed','excused')),
  acknowledged_at timestamptz,
  quiz_score numeric(5,2),
  signature_data jsonb not null default '{}'::jsonb,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (toolbox_talk_run_id, user_id)
);

create table if not exists public.site_safety_inspections_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  inspected_by uuid not null default auth.uid(),
  inspection_type text not null default 'daily' check (inspection_type in ('daily','pre_job','mid_job','post_incident','manager_audit','other')),
  inspection_status text not null default 'open' check (inspection_status in ('open','passed','failed','needs_review','closed')),
  inspected_at timestamptz not null default now(),
  checklist_results jsonb not null default '{}'::jsonb,
  hazard_count integer not null default 0,
  photo_refs jsonb not null default '[]'::jsonb,
  manager_review_required boolean not null default false,
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.safety_incident_reports_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  reported_by uuid not null default auth.uid(),
  incident_type text not null default 'near_miss' check (incident_type in ('near_miss','injury','property_damage','fall_risk','ppe_violation','vehicle','other')),
  severity text not null default 'low' check (severity in ('low','medium','high','critical')),
  status text not null default 'reported' check (status in ('reported','under_review','corrective_action_required','resolved','closed')),
  occurred_at timestamptz not null default now(),
  location_notes text not null default '',
  incident_summary text not null default '',
  people_involved jsonb not null default '[]'::jsonb,
  photo_refs jsonb not null default '[]'::jsonb,
  stop_work_required boolean not null default false,
  regulatory_followup_required boolean not null default false,
  manager_review_required boolean not null default true,
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.safety_corrective_action_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  incident_report_id uuid references public.safety_incident_reports_deep(id) on delete set null,
  inspection_id uuid references public.site_safety_inspections_deep(id) on delete set null,
  job_id uuid references public.jobs(id) on delete set null,
  assigned_to uuid,
  status text not null default 'open' check (status in ('open','assigned','in_progress','completed','verified','closed','overdue')),
  priority text not null default 'normal' check (priority in ('low','normal','high','urgent')),
  due_at timestamptz,
  action_summary text not null default '',
  completion_notes text not null default '',
  evidence_refs jsonb not null default '[]'::jsonb,
  verified_by uuid,
  verified_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ppe_check_records_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  user_id uuid not null default auth.uid(),
  check_status text not null default 'pending' check (check_status in ('pending','passed','failed','needs_replacement','waived')),
  checked_at timestamptz not null default now(),
  ppe_items jsonb not null default '{}'::jsonb,
  missing_items jsonb not null default '[]'::jsonb,
  photo_refs jsonb not null default '[]'::jsonb,
  manager_review_required boolean not null default false,
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.stop_work_followup_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  incident_report_id uuid references public.safety_incident_reports_deep(id) on delete set null,
  stop_work_status text not null default 'active' check (stop_work_status in ('active','reviewing','resolved','released','cancelled')),
  issued_by uuid not null default auth.uid(),
  issued_at timestamptz not null default now(),
  released_by uuid,
  released_at timestamptz,
  reason text not null default '',
  release_conditions jsonb not null default '{}'::jsonb,
  manager_review_required boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.safety_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  related_table text not null,
  related_id uuid,
  event_type text not null,
  event_summary text not null default '',
  event_payload jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

-- RLS/policies are applied in production migration. Database is source of truth.