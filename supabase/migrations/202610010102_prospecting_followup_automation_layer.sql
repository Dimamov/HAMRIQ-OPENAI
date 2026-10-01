create table if not exists public.prospecting_followup_sequences_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null,
  trigger_outcome text not null default 'Set for follow-up',
  default_delay_minutes integer not null default 1440,
  channel text not null default 'task' check (channel in ('task','call','sms','email','door_return','hammy')),
  is_active boolean not null default true,
  requires_manager_approval boolean not null default false,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.prospecting_followup_tasks_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  prospecting_visit_id uuid,
  contact_id uuid references public.contacts(id) on delete set null,
  job_id uuid references public.jobs(id) on delete set null,
  assigned_to uuid not null default auth.uid(),
  sequence_id uuid references public.prospecting_followup_sequences_deep(id) on delete set null,
  task_type text not null default 'callback',
  priority text not null default 'normal',
  status text not null default 'open',
  due_at timestamptz not null default (now() + interval '1 day'),
  completed_at timestamptz,
  missed_at timestamptz,
  homeowner_name text not null default '',
  property_address text not null default '',
  outcome text not null default '',
  note text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.prospecting_no_answer_followups_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  prospecting_visit_id uuid,
  assigned_to uuid not null default auth.uid(),
  property_address text not null default '',
  first_knocked_at timestamptz not null default now(),
  next_attempt_at timestamptz not null default (now() + interval '2 days'),
  attempt_count integer not null default 1,
  max_attempts integer not null default 3,
  status text not null default 'scheduled',
  last_attempt_note text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.prospecting_interested_homeowner_tasks_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  prospecting_visit_id uuid,
  contact_id uuid references public.contacts(id) on delete set null,
  job_id uuid references public.jobs(id) on delete set null,
  assigned_to uuid not null default auth.uid(),
  property_address text not null default '',
  homeowner_name text not null default '',
  interest_level text not null default 'warm',
  requested_action text not null default 'follow_up',
  due_at timestamptz not null default (now() + interval '4 hours'),
  status text not null default 'open',
  note text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.prospecting_rep_reminders_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  assigned_to uuid not null default auth.uid(),
  followup_task_id uuid references public.prospecting_followup_tasks_deep(id) on delete cascade,
  reminder_type text not null default 'push',
  remind_at timestamptz not null,
  status text not null default 'pending',
  message text not null default '',
  delivered_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.prospecting_missed_followup_manager_alerts_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  rep_user_id uuid not null,
  followup_task_id uuid references public.prospecting_followup_tasks_deep(id) on delete cascade,
  alert_status text not null default 'open',
  missed_minutes integer not null default 0,
  severity text not null default 'normal',
  property_address text not null default '',
  manager_note text not null default '',
  acknowledged_by uuid,
  acknowledged_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.prospecting_followup_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  followup_task_id uuid references public.prospecting_followup_tasks_deep(id) on delete cascade,
  actor_user_id uuid not null default auth.uid(),
  event_type text not null default 'created',
  event_summary text not null default '',
  before_state jsonb not null default '{}'::jsonb,
  after_state jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

alter table public.prospecting_followup_sequences_deep enable row level security;
alter table public.prospecting_followup_tasks_deep enable row level security;
alter table public.prospecting_no_answer_followups_deep enable row level security;
alter table public.prospecting_interested_homeowner_tasks_deep enable row level security;
alter table public.prospecting_rep_reminders_deep enable row level security;
alter table public.prospecting_missed_followup_manager_alerts_deep enable row level security;
alter table public.prospecting_followup_activity_events_deep enable row level security;

grant select, insert, update on public.prospecting_followup_sequences_deep to authenticated;
grant select, insert, update on public.prospecting_followup_tasks_deep to authenticated;
grant select, insert, update on public.prospecting_no_answer_followups_deep to authenticated;
grant select, insert, update on public.prospecting_interested_homeowner_tasks_deep to authenticated;
grant select, insert, update on public.prospecting_rep_reminders_deep to authenticated;
grant select, insert, update on public.prospecting_missed_followup_manager_alerts_deep to authenticated;
grant select, insert, update on public.prospecting_followup_activity_events_deep to authenticated;

-- Policies applied in production migration: managers control sequences and missed-follow-up alerts;
-- reps control their own follow-up tasks, reminders, interested-homeowner tasks, and no-answer follow-ups;
-- company users can view permitted records through private.company_access(company_id).