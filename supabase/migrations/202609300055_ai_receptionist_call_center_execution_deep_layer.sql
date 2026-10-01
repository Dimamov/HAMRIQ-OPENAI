-- HAMRIQ AI receptionist / call-center execution layer
-- Captures inbound/missed calls, call-created leads, voicemail summaries, missed-call recovery, and handoff tasks.

create table if not exists public.ai_receptionist_inbound_calls_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  contact_id uuid references public.contacts(id),
  job_id uuid references public.jobs(id),
  caller_name text,
  caller_phone text,
  caller_email text,
  call_direction text not null default 'inbound' check (call_direction in ('inbound','outbound','missed','voicemail')),
  call_status text not null default 'new' check (call_status in ('new','answered','missed','voicemail','completed','needs_follow_up','archived')),
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  duration_seconds integer not null default 0,
  recording_url text,
  transcript text,
  summary text,
  ai_confidence numeric(5,2),
  human_review_required boolean not null default true,
  reviewed_by uuid,
  reviewed_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ai_receptionist_lead_capture_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  call_id uuid not null references public.ai_receptionist_inbound_calls_deep(id) on delete cascade,
  contact_id uuid references public.contacts(id),
  job_id uuid references public.jobs(id),
  captured_name text,
  captured_phone text,
  captured_email text,
  captured_address text,
  lead_source text not null default 'AI Receptionist',
  damage_type text,
  urgency_level text not null default 'normal' check (urgency_level in ('low','normal','high','emergency')),
  insurance_mentioned boolean not null default false,
  appointment_requested boolean not null default false,
  ai_created_lead boolean not null default false,
  manager_review_required boolean not null default true,
  review_status text not null default 'pending' check (review_status in ('pending','approved','rejected','merged','created')),
  reviewed_by uuid,
  reviewed_at timestamptz,
  details jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ai_receptionist_call_outcomes_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  call_id uuid not null references public.ai_receptionist_inbound_calls_deep(id) on delete cascade,
  contact_id uuid references public.contacts(id),
  job_id uuid references public.jobs(id),
  outcome_type text not null default 'needs_follow_up' check (outcome_type in ('new_lead','appointment_booked','message_taken','spam','existing_customer','needs_follow_up','emergency','no_action')),
  outcome_summary text,
  next_action text,
  assigned_to uuid,
  due_at timestamptz,
  completed_at timestamptz,
  human_review_required boolean not null default true,
  details jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.missed_call_recovery_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  call_id uuid references public.ai_receptionist_inbound_calls_deep(id) on delete set null,
  contact_id uuid references public.contacts(id),
  job_id uuid references public.jobs(id),
  recovery_status text not null default 'queued' check (recovery_status in ('queued','sent','called_back','replied','booked','failed','cancelled')),
  recovery_channel text not null default 'sms' check (recovery_channel in ('sms','email','call','task','mixed')),
  message_body text,
  assigned_to uuid,
  scheduled_at timestamptz,
  sent_at timestamptz,
  replied_at timestamptz,
  booked_at timestamptz,
  failure_reason text,
  human_review_required boolean not null default true,
  details jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.voicemail_summary_records_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  call_id uuid not null references public.ai_receptionist_inbound_calls_deep(id) on delete cascade,
  contact_id uuid references public.contacts(id),
  job_id uuid references public.jobs(id),
  voicemail_url text,
  transcription text,
  ai_summary text,
  detected_intent text,
  urgency_level text not null default 'normal' check (urgency_level in ('low','normal','high','emergency')),
  callback_required boolean not null default true,
  assigned_to uuid,
  reviewed_by uuid,
  reviewed_at timestamptz,
  human_review_required boolean not null default true,
  details jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.receptionist_handoff_tasks_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  call_id uuid references public.ai_receptionist_inbound_calls_deep(id) on delete set null,
  contact_id uuid references public.contacts(id),
  job_id uuid references public.jobs(id),
  task_type text not null default 'follow_up' check (task_type in ('follow_up','schedule_inspection','call_back','manager_review','emergency','claim_question','production_question','billing_question')),
  task_title text not null,
  task_notes text,
  assigned_to uuid,
  priority text not null default 'normal' check (priority in ('low','normal','high','urgent')),
  status text not null default 'open' check (status in ('open','in_progress','completed','cancelled')),
  due_at timestamptz,
  completed_at timestamptz,
  completed_by uuid,
  details jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ai_receptionist_settings_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  receptionist_name text not null default 'Hammy',
  active boolean not null default false,
  answer_mode text not null default 'after_hours' check (answer_mode in ('off','after_hours','overflow','always')),
  business_hours jsonb not null default '{}'::jsonb,
  emergency_keywords jsonb not null default '[]'::jsonb,
  booking_enabled boolean not null default false,
  missed_call_recovery_enabled boolean not null default true,
  lead_creation_enabled boolean not null default true,
  manager_review_required boolean not null default true,
  voice_provider text,
  phone_provider text,
  settings jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id)
);

create table if not exists public.ai_receptionist_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  call_id uuid references public.ai_receptionist_inbound_calls_deep(id) on delete set null,
  contact_id uuid references public.contacts(id),
  job_id uuid references public.jobs(id),
  event_type text not null,
  event_summary text,
  actor_user_id uuid,
  actor_type text not null default 'system' check (actor_type in ('system','hammy','manager','rep','customer')),
  event_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists ai_receptionist_inbound_calls_deep_company_idx on public.ai_receptionist_inbound_calls_deep(company_id, started_at desc);
create index if not exists ai_receptionist_inbound_calls_deep_job_idx on public.ai_receptionist_inbound_calls_deep(company_id, job_id);
create index if not exists ai_receptionist_lead_capture_deep_company_idx on public.ai_receptionist_lead_capture_deep(company_id, created_at desc);
create index if not exists ai_receptionist_call_outcomes_deep_assigned_idx on public.ai_receptionist_call_outcomes_deep(company_id, assigned_to, due_at);
create index if not exists missed_call_recovery_runs_deep_company_idx on public.missed_call_recovery_runs_deep(company_id, recovery_status, scheduled_at);
create index if not exists voicemail_summary_records_deep_company_idx on public.voicemail_summary_records_deep(company_id, created_at desc);
create index if not exists receptionist_handoff_tasks_deep_assigned_idx on public.receptionist_handoff_tasks_deep(company_id, assigned_to, status, due_at);
create index if not exists ai_receptionist_activity_events_deep_company_idx on public.ai_receptionist_activity_events_deep(company_id, created_at desc);

alter table public.ai_receptionist_inbound_calls_deep enable row level security;
alter table public.ai_receptionist_lead_capture_deep enable row level security;
alter table public.ai_receptionist_call_outcomes_deep enable row level security;
alter table public.missed_call_recovery_runs_deep enable row level security;
alter table public.voicemail_summary_records_deep enable row level security;
alter table public.receptionist_handoff_tasks_deep enable row level security;
alter table public.ai_receptionist_settings_deep enable row level security;
alter table public.ai_receptionist_activity_events_deep enable row level security;

revoke all on public.ai_receptionist_inbound_calls_deep from anon, authenticated;
revoke all on public.ai_receptionist_lead_capture_deep from anon, authenticated;
revoke all on public.ai_receptionist_call_outcomes_deep from anon, authenticated;
revoke all on public.missed_call_recovery_runs_deep from anon, authenticated;
revoke all on public.voicemail_summary_records_deep from anon, authenticated;
revoke all on public.receptionist_handoff_tasks_deep from anon, authenticated;
revoke all on public.ai_receptionist_settings_deep from anon, authenticated;
revoke all on public.ai_receptionist_activity_events_deep from anon, authenticated;

grant select, insert, update on public.ai_receptionist_inbound_calls_deep to authenticated;
grant select, insert, update on public.ai_receptionist_lead_capture_deep to authenticated;
grant select, insert, update on public.ai_receptionist_call_outcomes_deep to authenticated;
grant select, insert, update on public.missed_call_recovery_runs_deep to authenticated;
grant select, insert, update on public.voicemail_summary_records_deep to authenticated;
grant select, insert, update on public.receptionist_handoff_tasks_deep to authenticated;
grant select, insert, update on public.ai_receptionist_settings_deep to authenticated;
grant select, insert on public.ai_receptionist_activity_events_deep to authenticated;

create policy ai_receptionist_inbound_calls_company_select on public.ai_receptionist_inbound_calls_deep for select using (private.company_access(company_id));
create policy ai_receptionist_inbound_calls_company_insert on public.ai_receptionist_inbound_calls_deep for insert with check (private.company_access(company_id));
create policy ai_receptionist_inbound_calls_manager_update on public.ai_receptionist_inbound_calls_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy ai_receptionist_lead_capture_company_select on public.ai_receptionist_lead_capture_deep for select using (private.company_access(company_id));
create policy ai_receptionist_lead_capture_company_insert on public.ai_receptionist_lead_capture_deep for insert with check (private.company_access(company_id));
create policy ai_receptionist_lead_capture_manager_update on public.ai_receptionist_lead_capture_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy ai_receptionist_call_outcomes_company_select on public.ai_receptionist_call_outcomes_deep for select using (private.company_access(company_id));
create policy ai_receptionist_call_outcomes_company_insert on public.ai_receptionist_call_outcomes_deep for insert with check (private.company_access(company_id));
create policy ai_receptionist_call_outcomes_update_assigned_or_manager on public.ai_receptionist_call_outcomes_deep for update using (private.is_manager(company_id) or assigned_to = auth.uid()) with check (private.is_manager(company_id) or assigned_to = auth.uid());

create policy missed_call_recovery_company_select on public.missed_call_recovery_runs_deep for select using (private.company_access(company_id));
create policy missed_call_recovery_company_insert on public.missed_call_recovery_runs_deep for insert with check (private.company_access(company_id));
create policy missed_call_recovery_update_assigned_or_manager on public.missed_call_recovery_runs_deep for update using (private.is_manager(company_id) or assigned_to = auth.uid()) with check (private.is_manager(company_id) or assigned_to = auth.uid());

create policy voicemail_summary_company_select on public.voicemail_summary_records_deep for select using (private.company_access(company_id));
create policy voicemail_summary_company_insert on public.voicemail_summary_records_deep for insert with check (private.company_access(company_id));
create policy voicemail_summary_update_assigned_or_manager on public.voicemail_summary_records_deep for update using (private.is_manager(company_id) or assigned_to = auth.uid()) with check (private.is_manager(company_id) or assigned_to = auth.uid());

create policy receptionist_handoff_tasks_company_select on public.receptionist_handoff_tasks_deep for select using (private.company_access(company_id));
create policy receptionist_handoff_tasks_company_insert on public.receptionist_handoff_tasks_deep for insert with check (private.company_access(company_id));
create policy receptionist_handoff_tasks_update_assigned_or_manager on public.receptionist_handoff_tasks_deep for update using (private.is_manager(company_id) or assigned_to = auth.uid()) with check (private.is_manager(company_id) or assigned_to = auth.uid());

create policy ai_receptionist_settings_manager_select on public.ai_receptionist_settings_deep for select using (private.company_access(company_id));
create policy ai_receptionist_settings_manager_insert on public.ai_receptionist_settings_deep for insert with check (private.is_manager(company_id));
create policy ai_receptionist_settings_manager_update on public.ai_receptionist_settings_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy ai_receptionist_activity_events_company_select on public.ai_receptionist_activity_events_deep for select using (private.company_access(company_id));
create policy ai_receptionist_activity_events_company_insert on public.ai_receptionist_activity_events_deep for insert with check (private.company_access(company_id));
