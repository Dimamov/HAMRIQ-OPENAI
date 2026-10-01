-- HAMRIQ insurance claim timeline/deadline automation execution layer
-- Adds claim milestones, carrier deadlines, document intake, adjuster appointments,
-- payment checkpoints, depreciation recovery, mortgage-check tracking, and activity audit.

create table if not exists public.claim_timeline_milestones_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  contact_id uuid references public.contacts(id) on delete set null,
  milestone_type text not null check (milestone_type in ('claim_created','inspection_scheduled','inspection_completed','carrier_estimate_received','supplement_needed','supplement_sent','carrier_response_received','approved','denied','payment_issued','closed','other')),
  milestone_status text not null default 'pending' check (milestone_status in ('pending','completed','blocked','cancelled','overdue')),
  milestone_title text not null,
  milestone_notes text not null default '',
  due_at timestamptz,
  completed_at timestamptz,
  assigned_user_id uuid,
  requires_manager_review boolean not null default false,
  review_status text not null default 'not_required' check (review_status in ('not_required','needs_review','approved','rejected')),
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.carrier_deadline_trackers_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  carrier_name text not null default '',
  claim_number text not null default '',
  deadline_type text not null check (deadline_type in ('inspection','estimate_due','supplement_response','payment_followup','depreciation_recovery','mortgage_endorsement','appeal','legal_notice','other')),
  deadline_at timestamptz not null,
  reminder_schedule jsonb not null default '[]'::jsonb,
  status text not null default 'active' check (status in ('active','snoozed','completed','missed','cancelled')),
  risk_level text not null default 'normal' check (risk_level in ('low','normal','high','critical')),
  assigned_user_id uuid,
  completed_at timestamptz,
  completion_notes text not null default '',
  requires_manager_review boolean not null default true,
  review_status text not null default 'needs_review' check (review_status in ('needs_review','approved','rejected','not_required')),
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.insurance_document_intake_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  document_type text not null check (document_type in ('policy','claim_letter','carrier_estimate','payment_statement','denial_letter','mortgage_letter','depreciation_letter','supplement_response','other')),
  source_channel text not null default 'manual' check (source_channel in ('manual','email','portal','upload','photo','api','other')),
  storage_path text not null default '',
  extracted_summary text not null default '',
  extracted_fields jsonb not null default '{}'::jsonb,
  intake_status text not null default 'received' check (intake_status in ('received','processing','review_needed','accepted','rejected','archived')),
  ai_extracted boolean not null default false,
  requires_human_review boolean not null default true,
  reviewed_by uuid,
  reviewed_at timestamptz,
  review_notes text not null default '',
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.adjuster_appointment_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  adjuster_name text not null default '',
  adjuster_phone text not null default '',
  adjuster_email text not null default '',
  carrier_name text not null default '',
  appointment_at timestamptz not null,
  appointment_status text not null default 'scheduled' check (appointment_status in ('scheduled','confirmed','completed','missed','rescheduled','cancelled')),
  rep_user_id uuid,
  homeowner_notified boolean not null default false,
  prep_packet_ready boolean not null default false,
  outcome_summary text not null default '',
  next_steps jsonb not null default '[]'::jsonb,
  requires_manager_review boolean not null default false,
  review_status text not null default 'not_required' check (review_status in ('not_required','needs_review','approved','rejected')),
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.carrier_payment_checkpoints_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  payment_type text not null check (payment_type in ('acv','rcv','supplement','depreciation','deductible','mortgage_release','other')),
  expected_amount_cents bigint not null default 0,
  received_amount_cents bigint not null default 0,
  payment_status text not null default 'expected' check (payment_status in ('expected','partial','received','short_paid','disputed','cancelled')),
  expected_at timestamptz,
  received_at timestamptz,
  carrier_reference text not null default '',
  variance_reason text not null default '',
  requires_manager_review boolean not null default true,
  review_status text not null default 'needs_review' check (review_status in ('needs_review','approved','rejected','not_required')),
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.depreciation_recovery_tasks_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  recoverable_amount_cents bigint not null default 0,
  recovered_amount_cents bigint not null default 0,
  task_status text not null default 'not_started' check (task_status in ('not_started','waiting_for_completion','submitted','followup_needed','recovered','denied','closed')),
  required_documents jsonb not null default '[]'::jsonb,
  submitted_at timestamptz,
  followup_at timestamptz,
  recovered_at timestamptz,
  assigned_user_id uuid,
  notes text not null default '',
  requires_manager_review boolean not null default true,
  review_status text not null default 'needs_review' check (review_status in ('needs_review','approved','rejected','not_required')),
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.mortgage_check_status_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  mortgage_company text not null default '',
  check_amount_cents bigint not null default 0,
  check_status text not null default 'not_started' check (check_status in ('not_started','received','sent_to_mortgage','documents_requested','endorsed','released','stalled','cancelled')),
  sent_at timestamptz,
  released_at timestamptz,
  tracking_reference text not null default '',
  required_documents jsonb not null default '[]'::jsonb,
  assigned_user_id uuid,
  next_followup_at timestamptz,
  notes text not null default '',
  requires_manager_review boolean not null default true,
  review_status text not null default 'needs_review' check (review_status in ('needs_review','approved','rejected','not_required')),
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.insurance_claim_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  event_type text not null,
  event_title text not null,
  event_summary text not null default '',
  actor_user_id uuid default auth.uid(),
  related_table text not null default '',
  related_record_id uuid,
  event_payload jsonb not null default '{}'::jsonb,
  requires_manager_review boolean not null default false,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create index if not exists idx_claim_timeline_milestones_deep_company_job on public.claim_timeline_milestones_deep(company_id, job_id);
create index if not exists idx_carrier_deadline_trackers_deep_company_due on public.carrier_deadline_trackers_deep(company_id, deadline_at);
create index if not exists idx_insurance_document_intake_runs_deep_company_job on public.insurance_document_intake_runs_deep(company_id, job_id);
create index if not exists idx_adjuster_appointment_runs_deep_company_appt on public.adjuster_appointment_runs_deep(company_id, appointment_at);
create index if not exists idx_carrier_payment_checkpoints_deep_company_job on public.carrier_payment_checkpoints_deep(company_id, job_id);
create index if not exists idx_depreciation_recovery_tasks_deep_company_job on public.depreciation_recovery_tasks_deep(company_id, job_id);
create index if not exists idx_mortgage_check_status_runs_deep_company_job on public.mortgage_check_status_runs_deep(company_id, job_id);
create index if not exists idx_insurance_claim_activity_events_deep_company_job on public.insurance_claim_activity_events_deep(company_id, job_id);

alter table public.claim_timeline_milestones_deep enable row level security;
alter table public.carrier_deadline_trackers_deep enable row level security;
alter table public.insurance_document_intake_runs_deep enable row level security;
alter table public.adjuster_appointment_runs_deep enable row level security;
alter table public.carrier_payment_checkpoints_deep enable row level security;
alter table public.depreciation_recovery_tasks_deep enable row level security;
alter table public.mortgage_check_status_runs_deep enable row level security;
alter table public.insurance_claim_activity_events_deep enable row level security;

revoke all on public.claim_timeline_milestones_deep from anon, authenticated;
revoke all on public.carrier_deadline_trackers_deep from anon, authenticated;
revoke all on public.insurance_document_intake_runs_deep from anon, authenticated;
revoke all on public.adjuster_appointment_runs_deep from anon, authenticated;
revoke all on public.carrier_payment_checkpoints_deep from anon, authenticated;
revoke all on public.depreciation_recovery_tasks_deep from anon, authenticated;
revoke all on public.mortgage_check_status_runs_deep from anon, authenticated;
revoke all on public.insurance_claim_activity_events_deep from anon, authenticated;

grant select, insert, update on public.claim_timeline_milestones_deep to authenticated;
grant select, insert, update on public.carrier_deadline_trackers_deep to authenticated;
grant select, insert, update on public.insurance_document_intake_runs_deep to authenticated;
grant select, insert, update on public.adjuster_appointment_runs_deep to authenticated;
grant select, insert, update on public.carrier_payment_checkpoints_deep to authenticated;
grant select, insert, update on public.depreciation_recovery_tasks_deep to authenticated;
grant select, insert, update on public.mortgage_check_status_runs_deep to authenticated;
grant select, insert on public.insurance_claim_activity_events_deep to authenticated;

create policy claim_timeline_milestones_deep_select on public.claim_timeline_milestones_deep for select using (private.company_access(company_id) or private.can_job(company_id, job_id));
create policy claim_timeline_milestones_deep_insert on public.claim_timeline_milestones_deep for insert with check (private.company_access(company_id) or private.can_job(company_id, job_id));
create policy claim_timeline_milestones_deep_update on public.claim_timeline_milestones_deep for update using (private.is_manager(company_id) or assigned_user_id = auth.uid() or private.can_job(company_id, job_id)) with check (private.is_manager(company_id) or assigned_user_id = auth.uid() or private.can_job(company_id, job_id));

create policy carrier_deadline_trackers_deep_select on public.carrier_deadline_trackers_deep for select using (private.company_access(company_id) or private.can_job(company_id, job_id));
create policy carrier_deadline_trackers_deep_insert on public.carrier_deadline_trackers_deep for insert with check (private.is_manager(company_id) or private.can_job(company_id, job_id));
create policy carrier_deadline_trackers_deep_update on public.carrier_deadline_trackers_deep for update using (private.is_manager(company_id) or assigned_user_id = auth.uid()) with check (private.is_manager(company_id) or assigned_user_id = auth.uid());

create policy insurance_document_intake_runs_deep_select on public.insurance_document_intake_runs_deep for select using (private.company_access(company_id) or private.can_job(company_id, job_id));
create policy insurance_document_intake_runs_deep_insert on public.insurance_document_intake_runs_deep for insert with check (private.company_access(company_id) or private.can_job(company_id, job_id));
create policy insurance_document_intake_runs_deep_update on public.insurance_document_intake_runs_deep for update using (private.is_manager(company_id) or created_by = auth.uid() or private.can_job(company_id, job_id)) with check (private.is_manager(company_id) or created_by = auth.uid() or private.can_job(company_id, job_id));

create policy adjuster_appointment_runs_deep_select on public.adjuster_appointment_runs_deep for select using (private.company_access(company_id) or private.can_job(company_id, job_id));
create policy adjuster_appointment_runs_deep_insert on public.adjuster_appointment_runs_deep for insert with check (private.company_access(company_id) or private.can_job(company_id, job_id));
create policy adjuster_appointment_runs_deep_update on public.adjuster_appointment_runs_deep for update using (private.is_manager(company_id) or rep_user_id = auth.uid() or private.can_job(company_id, job_id)) with check (private.is_manager(company_id) or rep_user_id = auth.uid() or private.can_job(company_id, job_id));

create policy carrier_payment_checkpoints_deep_select on public.carrier_payment_checkpoints_deep for select using (private.company_access(company_id) or private.can_job(company_id, job_id));
create policy carrier_payment_checkpoints_deep_insert on public.carrier_payment_checkpoints_deep for insert with check (private.is_manager(company_id) or private.can_job(company_id, job_id));
create policy carrier_payment_checkpoints_deep_update on public.carrier_payment_checkpoints_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy depreciation_recovery_tasks_deep_select on public.depreciation_recovery_tasks_deep for select using (private.company_access(company_id) or private.can_job(company_id, job_id));
create policy depreciation_recovery_tasks_deep_insert on public.depreciation_recovery_tasks_deep for insert with check (private.is_manager(company_id) or private.can_job(company_id, job_id));
create policy depreciation_recovery_tasks_deep_update on public.depreciation_recovery_tasks_deep for update using (private.is_manager(company_id) or assigned_user_id = auth.uid()) with check (private.is_manager(company_id) or assigned_user_id = auth.uid());

create policy mortgage_check_status_runs_deep_select on public.mortgage_check_status_runs_deep for select using (private.company_access(company_id) or private.can_job(company_id, job_id));
create policy mortgage_check_status_runs_deep_insert on public.mortgage_check_status_runs_deep for insert with check (private.is_manager(company_id) or private.can_job(company_id, job_id));
create policy mortgage_check_status_runs_deep_update on public.mortgage_check_status_runs_deep for update using (private.is_manager(company_id) or assigned_user_id = auth.uid()) with check (private.is_manager(company_id) or assigned_user_id = auth.uid());

create policy insurance_claim_activity_events_deep_select on public.insurance_claim_activity_events_deep for select using (private.company_access(company_id) or private.can_job(company_id, job_id));
create policy insurance_claim_activity_events_deep_insert on public.insurance_claim_activity_events_deep for insert with check (private.company_access(company_id) or private.can_job(company_id, job_id));
