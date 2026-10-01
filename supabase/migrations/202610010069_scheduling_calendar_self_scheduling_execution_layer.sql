create table if not exists public.scheduling_availability_rules_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null,
  rule_name text not null,
  rule_type text not null default 'working_hours' check (rule_type in ('working_hours','blackout','travel_buffer','appointment_limit','override')),
  day_of_week int check (day_of_week between 0 and 6),
  start_time time,
  end_time time,
  timezone text not null default 'America/Detroit',
  appointment_types jsonb not null default '[]'::jsonb,
  is_active boolean not null default true,
  manager_review_required boolean not null default false,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.calendar_event_sync_records_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid,
  contact_id uuid,
  assigned_user_id uuid,
  provider text not null default 'internal' check (provider in ('internal','google_calendar','outlook','apple_calendar','other')),
  provider_event_id text,
  event_title text not null,
  event_type text not null default 'appointment' check (event_type in ('appointment','inspection','adjuster_meeting','contract_review','production','service','followup','other')),
  start_at timestamptz not null,
  end_at timestamptz,
  sync_status text not null default 'pending' check (sync_status in ('pending','synced','failed','conflict','cancelled')),
  conflict_details jsonb not null default '{}'::jsonb,
  last_synced_at timestamptz,
  manager_review_required boolean not null default false,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.customer_self_scheduling_links_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid,
  contact_id uuid,
  assigned_user_id uuid,
  link_label text not null,
  link_token text not null unique,
  appointment_type text not null default 'appointment',
  allowed_windows jsonb not null default '[]'::jsonb,
  expires_at timestamptz,
  status text not null default 'active' check (status in ('draft','active','expired','used','revoked')),
  manager_review_required boolean not null default false,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.self_scheduling_booking_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  self_scheduling_link_id uuid references public.customer_self_scheduling_links_deep(id) on delete set null,
  job_id uuid,
  contact_id uuid,
  assigned_user_id uuid,
  requested_start_at timestamptz not null,
  requested_end_at timestamptz,
  booking_status text not null default 'requested' check (booking_status in ('requested','confirmed','needs_review','rescheduled','cancelled','expired')),
  homeowner_notes text not null default '',
  internal_notes text not null default '',
  manager_review_required boolean not null default false,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.appointment_confirmation_runs_exec_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  calendar_event_sync_record_id uuid references public.calendar_event_sync_records_deep(id) on delete set null,
  job_id uuid,
  contact_id uuid,
  assigned_user_id uuid,
  confirmation_channel text not null default 'sms' check (confirmation_channel in ('sms','email','voice','portal','manual')),
  confirmation_status text not null default 'pending' check (confirmation_status in ('pending','sent','confirmed','declined','no_response','failed')),
  scheduled_send_at timestamptz,
  sent_at timestamptz,
  responded_at timestamptz,
  response_payload jsonb not null default '{}'::jsonb,
  manager_review_required boolean not null default false,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.no_show_risk_escalations_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  calendar_event_sync_record_id uuid references public.calendar_event_sync_records_deep(id) on delete set null,
  job_id uuid,
  contact_id uuid,
  assigned_user_id uuid,
  risk_level text not null default 'medium' check (risk_level in ('low','medium','high','critical')),
  risk_reasons jsonb not null default '[]'::jsonb,
  recommended_action text not null default '',
  escalation_status text not null default 'open' check (escalation_status in ('open','working','resolved','dismissed')),
  manager_review_required boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.appointment_reschedule_requests_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  calendar_event_sync_record_id uuid references public.calendar_event_sync_records_deep(id) on delete set null,
  job_id uuid,
  contact_id uuid,
  requested_by_user_id uuid,
  assigned_user_id uuid,
  original_start_at timestamptz,
  requested_start_at timestamptz,
  requested_end_at timestamptz,
  request_reason text not null default '',
  status text not null default 'requested' check (status in ('requested','approved','declined','cancelled','completed')),
  manager_review_required boolean not null default false,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.scheduling_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid,
  contact_id uuid,
  actor_user_id uuid not null default auth.uid(),
  related_record_table text not null,
  related_record_id uuid,
  event_type text not null,
  event_summary text not null default '',
  event_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists scheduling_availability_rules_deep_company_user_idx on public.scheduling_availability_rules_deep(company_id, user_id);
create index if not exists calendar_event_sync_records_deep_company_start_idx on public.calendar_event_sync_records_deep(company_id, start_at);
create index if not exists customer_self_scheduling_links_deep_company_status_idx on public.customer_self_scheduling_links_deep(company_id, status);
create index if not exists self_scheduling_booking_runs_deep_company_status_idx on public.self_scheduling_booking_runs_deep(company_id, booking_status);
create index if not exists appointment_confirmation_runs_exec_deep_company_status_idx on public.appointment_confirmation_runs_exec_deep(company_id, confirmation_status);
create index if not exists no_show_risk_escalations_deep_company_status_idx on public.no_show_risk_escalations_deep(company_id, escalation_status);
create index if not exists appointment_reschedule_requests_deep_company_status_idx on public.appointment_reschedule_requests_deep(company_id, status);
create index if not exists scheduling_activity_events_deep_company_created_idx on public.scheduling_activity_events_deep(company_id, created_at desc);

alter table public.scheduling_availability_rules_deep enable row level security;
alter table public.calendar_event_sync_records_deep enable row level security;
alter table public.customer_self_scheduling_links_deep enable row level security;
alter table public.self_scheduling_booking_runs_deep enable row level security;
alter table public.appointment_confirmation_runs_exec_deep enable row level security;
alter table public.no_show_risk_escalations_deep enable row level security;
alter table public.appointment_reschedule_requests_deep enable row level security;
alter table public.scheduling_activity_events_deep enable row level security;