-- HAMRIQ subcontractor/crew execution deep layer
-- Crew portal invites, acknowledgments, logs, payables, safety, issue responses, scorecards, and activity.

create table if not exists public.crew_portal_invitations_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  crew_id uuid,
  subcontractor_name text not null default '',
  invited_email text not null default '',
  invited_phone text not null default '',
  invitation_status text not null default 'draft' check (invitation_status in ('draft','sent','accepted','expired','revoked')),
  portal_role text not null default 'crew_member',
  invited_by uuid not null default auth.uid(),
  accepted_by uuid,
  sent_at timestamptz,
  accepted_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.crew_work_order_acknowledgments_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  work_order_id uuid,
  crew_id uuid,
  acknowledged_by uuid not null default auth.uid(),
  acknowledgment_status text not null default 'pending' check (acknowledgment_status in ('pending','accepted','needs_clarification','declined')),
  response_notes text not null default '',
  acknowledged_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.crew_daily_logs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  crew_id uuid,
  log_date date not null default current_date,
  weather_summary text not null default '',
  crew_count integer not null default 0,
  start_time timestamptz,
  stop_time timestamptz,
  work_completed text not null default '',
  blockers text not null default '',
  photos jsonb not null default '[]'::jsonb,
  submitted_by uuid not null default auth.uid(),
  reviewed_by uuid,
  reviewed_at timestamptz,
  review_status text not null default 'submitted' check (review_status in ('draft','submitted','reviewed','needs_followup')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.crew_payable_approval_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  crew_id uuid,
  payable_id uuid,
  gross_amount_cents bigint not null default 0,
  holdback_amount_cents bigint not null default 0,
  approved_amount_cents bigint not null default 0,
  approval_status text not null default 'pending_manager_review' check (approval_status in ('draft','pending_manager_review','approved','held','rejected','paid')),
  approval_notes text not null default '',
  requested_by uuid not null default auth.uid(),
  approved_by uuid,
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.crew_safety_acknowledgments_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  crew_id uuid,
  safety_topic text not null default '',
  safety_content jsonb not null default '{}'::jsonb,
  acknowledged_by uuid not null default auth.uid(),
  acknowledgment_status text not null default 'pending' check (acknowledgment_status in ('pending','acknowledged','refused','expired')),
  acknowledged_at timestamptz,
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.crew_production_issue_responses_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  production_issue_id uuid,
  crew_id uuid,
  response_type text not null default 'update' check (response_type in ('update','clarification','delay_reason','resolution','photo_evidence')),
  response_body text not null default '',
  evidence jsonb not null default '[]'::jsonb,
  submitted_by uuid not null default auth.uid(),
  reviewed_by uuid,
  reviewed_at timestamptz,
  review_status text not null default 'submitted' check (review_status in ('submitted','accepted','needs_more_info','rejected')),
  created_at timestamptz not null default now()
);

create table if not exists public.crew_quality_scorecards_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  crew_id uuid,
  scorecard_period_start date,
  scorecard_period_end date,
  quality_metrics jsonb not null default '{}'::jsonb,
  callback_count integer not null default 0,
  punch_items_count integer not null default 0,
  waste_notes text not null default '',
  manager_notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.crew_portal_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  crew_id uuid,
  actor_id uuid not null default auth.uid(),
  event_type text not null default 'activity',
  event_summary text not null default '',
  event_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists crew_portal_invitations_deep_company_status_idx on public.crew_portal_invitations_deep(company_id, invitation_status);
create index if not exists crew_work_order_ack_deep_company_job_idx on public.crew_work_order_acknowledgments_deep(company_id, job_id);
create index if not exists crew_daily_logs_deep_company_job_date_idx on public.crew_daily_logs_deep(company_id, job_id, log_date);
create index if not exists crew_payable_approval_runs_deep_company_status_idx on public.crew_payable_approval_runs_deep(company_id, approval_status);
create index if not exists crew_safety_ack_deep_company_job_idx on public.crew_safety_acknowledgments_deep(company_id, job_id);
create index if not exists crew_issue_responses_deep_company_job_idx on public.crew_production_issue_responses_deep(company_id, job_id);
create index if not exists crew_quality_scorecards_deep_company_crew_idx on public.crew_quality_scorecards_deep(company_id, crew_id);
create index if not exists crew_portal_activity_events_deep_company_job_idx on public.crew_portal_activity_events_deep(company_id, job_id, created_at desc);

alter table public.crew_portal_invitations_deep enable row level security;
alter table public.crew_work_order_acknowledgments_deep enable row level security;
alter table public.crew_daily_logs_deep enable row level security;
alter table public.crew_payable_approval_runs_deep enable row level security;
alter table public.crew_safety_acknowledgments_deep enable row level security;
alter table public.crew_production_issue_responses_deep enable row level security;
alter table public.crew_quality_scorecards_deep enable row level security;
alter table public.crew_portal_activity_events_deep enable row level security;

revoke all on public.crew_portal_invitations_deep from anon, authenticated;
revoke all on public.crew_work_order_acknowledgments_deep from anon, authenticated;
revoke all on public.crew_daily_logs_deep from anon, authenticated;
revoke all on public.crew_payable_approval_runs_deep from anon, authenticated;
revoke all on public.crew_safety_acknowledgments_deep from anon, authenticated;
revoke all on public.crew_production_issue_responses_deep from anon, authenticated;
revoke all on public.crew_quality_scorecards_deep from anon, authenticated;
revoke all on public.crew_portal_activity_events_deep from anon, authenticated;

grant select, insert, update on public.crew_portal_invitations_deep to authenticated;
grant select, insert, update on public.crew_work_order_acknowledgments_deep to authenticated;
grant select, insert, update on public.crew_daily_logs_deep to authenticated;
grant select, insert, update on public.crew_payable_approval_runs_deep to authenticated;
grant select, insert, update on public.crew_safety_acknowledgments_deep to authenticated;
grant select, insert, update on public.crew_production_issue_responses_deep to authenticated;
grant select, insert, update on public.crew_quality_scorecards_deep to authenticated;
grant select, insert on public.crew_portal_activity_events_deep to authenticated;

drop policy if exists crew_portal_invitations_deep_manager_all on public.crew_portal_invitations_deep;
create policy crew_portal_invitations_deep_manager_all on public.crew_portal_invitations_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

drop policy if exists crew_work_order_ack_deep_job_access on public.crew_work_order_acknowledgments_deep;
create policy crew_work_order_ack_deep_job_access on public.crew_work_order_acknowledgments_deep for all to authenticated using (private.can_job(company_id, job_id) or private.is_manager(company_id)) with check (private.can_job(company_id, job_id) or private.is_manager(company_id));

drop policy if exists crew_daily_logs_deep_job_access on public.crew_daily_logs_deep;
create policy crew_daily_logs_deep_job_access on public.crew_daily_logs_deep for all to authenticated using (private.can_job(company_id, job_id) or private.is_manager(company_id)) with check (private.can_job(company_id, job_id) or private.is_manager(company_id));

drop policy if exists crew_payable_approval_runs_deep_manager_all on public.crew_payable_approval_runs_deep;
create policy crew_payable_approval_runs_deep_manager_all on public.crew_payable_approval_runs_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

drop policy if exists crew_safety_ack_deep_job_access on public.crew_safety_acknowledgments_deep;
create policy crew_safety_ack_deep_job_access on public.crew_safety_acknowledgments_deep for all to authenticated using (private.can_job(company_id, job_id) or private.is_manager(company_id) or acknowledged_by = auth.uid()) with check (private.can_job(company_id, job_id) or private.is_manager(company_id) or acknowledged_by = auth.uid());

drop policy if exists crew_issue_responses_deep_job_access on public.crew_production_issue_responses_deep;
create policy crew_issue_responses_deep_job_access on public.crew_production_issue_responses_deep for all to authenticated using (private.can_job(company_id, job_id) or private.is_manager(company_id)) with check (private.can_job(company_id, job_id) or private.is_manager(company_id));

drop policy if exists crew_quality_scorecards_deep_manager_read on public.crew_quality_scorecards_deep;
create policy crew_quality_scorecards_deep_manager_read on public.crew_quality_scorecards_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

drop policy if exists crew_portal_activity_events_deep_job_access on public.crew_portal_activity_events_deep;
create policy crew_portal_activity_events_deep_job_access on public.crew_portal_activity_events_deep for all to authenticated using (private.can_job(company_id, job_id) or private.company_access(company_id)) with check (private.can_job(company_id, job_id) or private.company_access(company_id));
