-- HAMRIQ permit/code/deadline execution deep layer
-- Adds building-code checks, permit applications, permit inspections, notice deadlines,
-- rescission timers, lien tracking, compliance exceptions, and activity history.

create table if not exists public.building_code_check_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid null references public.jobs(id) on delete cascade,
  jurisdiction text not null default '',
  code_source text not null default 'manual',
  check_status text not null default 'draft' check (check_status in ('draft','review_needed','approved','exception','rejected','archived')),
  reviewed_by uuid null,
  reviewed_at timestamptz null,
  ai_generated boolean not null default false,
  human_review_required boolean not null default true,
  findings jsonb not null default '[]'::jsonb,
  exceptions jsonb not null default '[]'::jsonb,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.permit_application_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid null references public.jobs(id) on delete cascade,
  permit_number text not null default '',
  jurisdiction text not null default '',
  permit_type text not null default 'roofing',
  status text not null default 'draft' check (status in ('draft','submitted','approved','rejected','revision_needed','issued','closed','expired')),
  submission_deadline date null,
  submitted_at timestamptz null,
  issued_at timestamptz null,
  expires_at timestamptz null,
  fee_cents bigint not null default 0,
  documents jsonb not null default '[]'::jsonb,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.permit_inspection_appointments_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid null references public.jobs(id) on delete cascade,
  permit_run_id uuid null references public.permit_application_runs_deep(id) on delete cascade,
  inspection_type text not null default 'final',
  appointment_status text not null default 'scheduled' check (appointment_status in ('scheduled','confirmed','passed','failed','rescheduled','cancelled','no_show')),
  scheduled_start timestamptz null,
  scheduled_end timestamptz null,
  inspector_name text not null default '',
  result_notes text not null default '',
  required_corrections jsonb not null default '[]'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.notice_deadline_trackers_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid null references public.jobs(id) on delete cascade,
  notice_type text not null default 'general',
  deadline_at timestamptz not null,
  status text not null default 'open' check (status in ('open','completed','waived','missed','cancelled')),
  responsible_user_id uuid null,
  completed_at timestamptz null,
  completion_evidence jsonb not null default '[]'::jsonb,
  reminder_schedule jsonb not null default '[]'::jsonb,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.rescission_timer_records_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid null references public.jobs(id) on delete cascade,
  contract_id uuid null,
  customer_name text not null default '',
  signed_at timestamptz null,
  rescission_deadline_at timestamptz null,
  status text not null default 'active' check (status in ('active','expired','rescinded','waived','cancelled')),
  customer_notice_sent_at timestamptz null,
  rescinded_at timestamptz null,
  evidence jsonb not null default '[]'::jsonb,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.lien_deadline_records_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid null references public.jobs(id) on delete cascade,
  lien_type text not null default 'notice',
  deadline_at timestamptz null,
  status text not null default 'tracking' check (status in ('tracking','filed','released','waived','missed','not_applicable')),
  amount_cents bigint not null default 0,
  filed_at timestamptz null,
  released_at timestamptz null,
  documents jsonb not null default '[]'::jsonb,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.compliance_exception_reviews_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid null references public.jobs(id) on delete cascade,
  exception_source text not null default 'manual',
  severity text not null default 'medium' check (severity in ('low','medium','high','critical')),
  status text not null default 'open' check (status in ('open','reviewing','approved_exception','resolved','rejected','closed')),
  requested_by uuid not null default auth.uid(),
  reviewed_by uuid null,
  reviewed_at timestamptz null,
  resolution_notes text not null default '',
  evidence jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.code_permit_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid null references public.jobs(id) on delete cascade,
  related_table text not null default '',
  related_id uuid null,
  event_type text not null default 'created',
  actor_id uuid null default auth.uid(),
  event_summary text not null default '',
  event_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- RLS policies are applied in the live Supabase project with manager/job/company scoped access.
