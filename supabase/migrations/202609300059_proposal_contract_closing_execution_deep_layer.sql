-- HAMRIQ proposal / contract closing execution layer
-- Adds proposal presentation, good/better/best option tracking, contract review,
-- selected scope locks, signing readiness, homeowner decisions, follow-up tasks,
-- and closing activity audit history.

create table if not exists public.proposal_presentation_sessions_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid,
  contact_id uuid,
  presented_by uuid not null default auth.uid(),
  session_status text not null default 'draft' check (session_status in ('draft','presented','customer_reviewing','decision_pending','won','lost','void')),
  presented_at timestamptz,
  homeowner_viewed_at timestamptz,
  ai_summary text,
  human_review_required boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.proposal_option_tracking_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid,
  proposal_session_id uuid,
  option_level text not null check (option_level in ('good','better','best','custom')),
  title text not null default '',
  price_cents bigint not null default 0,
  margin_cents bigint not null default 0,
  included_scope jsonb not null default '[]'::jsonb,
  excluded_scope jsonb not null default '[]'::jsonb,
  selected boolean not null default false,
  selected_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.contract_review_meetings_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid,
  contact_id uuid,
  proposal_session_id uuid,
  assigned_rep_user_id uuid,
  meeting_status text not null default 'scheduled' check (meeting_status in ('scheduled','confirmed','completed','rescheduled','no_show','cancelled')),
  scheduled_start_at timestamptz,
  scheduled_end_at timestamptz,
  meeting_notes text not null default '',
  homeowner_questions jsonb not null default '[]'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.selected_scope_locks_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid,
  proposal_session_id uuid,
  selected_option_id uuid,
  locked_scope jsonb not null default '{}'::jsonb,
  locked_price_cents bigint not null default 0,
  locked_by uuid not null default auth.uid(),
  locked_at timestamptz not null default now(),
  unlock_reason text,
  unlocked_by uuid,
  unlocked_at timestamptz,
  manager_review_required boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.signing_readiness_checks_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid,
  contract_review_meeting_id uuid,
  readiness_status text not null default 'needs_review' check (readiness_status in ('needs_review','ready_to_sign','blocked','signed','void')),
  missing_items jsonb not null default '[]'::jsonb,
  required_disclosures jsonb not null default '[]'::jsonb,
  legal_language_locked boolean not null default true,
  scope_language_locked boolean not null default true,
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.homeowner_decision_history_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid,
  contact_id uuid,
  proposal_session_id uuid,
  decision_type text not null default 'pending' check (decision_type in ('pending','selected_option','requested_changes','approved','declined','delayed','signed')),
  decision_notes text not null default '',
  decision_payload jsonb not null default '{}'::jsonb,
  recorded_by uuid not null default auth.uid(),
  recorded_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.proposal_followup_tasks_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid,
  proposal_session_id uuid,
  assigned_user_id uuid,
  task_status text not null default 'open' check (task_status in ('open','in_progress','completed','cancelled','overdue')),
  due_at timestamptz,
  task_reason text not null default '',
  followup_script text,
  ai_suggested_next_step text,
  human_review_required boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.proposal_closing_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid,
  proposal_session_id uuid,
  actor_user_id uuid not null default auth.uid(),
  event_type text not null default 'note',
  event_summary text not null default '',
  event_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_proposal_presentation_sessions_deep_company_job on public.proposal_presentation_sessions_deep(company_id, job_id);
create index if not exists idx_proposal_option_tracking_deep_company_job on public.proposal_option_tracking_deep(company_id, job_id);
create index if not exists idx_contract_review_meetings_deep_company_job on public.contract_review_meetings_deep(company_id, job_id);
create index if not exists idx_selected_scope_locks_deep_company_job on public.selected_scope_locks_deep(company_id, job_id);
create index if not exists idx_signing_readiness_checks_deep_company_job on public.signing_readiness_checks_deep(company_id, job_id);
create index if not exists idx_homeowner_decision_history_deep_company_job on public.homeowner_decision_history_deep(company_id, job_id);
create index if not exists idx_proposal_followup_tasks_deep_company_assigned on public.proposal_followup_tasks_deep(company_id, assigned_user_id, task_status);
create index if not exists idx_proposal_closing_activity_events_deep_company_job on public.proposal_closing_activity_events_deep(company_id, job_id, created_at desc);

alter table public.proposal_presentation_sessions_deep enable row level security;
alter table public.proposal_option_tracking_deep enable row level security;
alter table public.contract_review_meetings_deep enable row level security;
alter table public.selected_scope_locks_deep enable row level security;
alter table public.signing_readiness_checks_deep enable row level security;
alter table public.homeowner_decision_history_deep enable row level security;
alter table public.proposal_followup_tasks_deep enable row level security;
alter table public.proposal_closing_activity_events_deep enable row level security;

revoke all on public.proposal_presentation_sessions_deep from anon, authenticated;
revoke all on public.proposal_option_tracking_deep from anon, authenticated;
revoke all on public.contract_review_meetings_deep from anon, authenticated;
revoke all on public.selected_scope_locks_deep from anon, authenticated;
revoke all on public.signing_readiness_checks_deep from anon, authenticated;
revoke all on public.homeowner_decision_history_deep from anon, authenticated;
revoke all on public.proposal_followup_tasks_deep from anon, authenticated;
revoke all on public.proposal_closing_activity_events_deep from anon, authenticated;

grant select, insert, update on public.proposal_presentation_sessions_deep to authenticated;
grant select, insert, update on public.proposal_option_tracking_deep to authenticated;
grant select, insert, update on public.contract_review_meetings_deep to authenticated;
grant select, insert, update on public.selected_scope_locks_deep to authenticated;
grant select, insert, update on public.signing_readiness_checks_deep to authenticated;
grant select, insert, update on public.homeowner_decision_history_deep to authenticated;
grant select, insert, update on public.proposal_followup_tasks_deep to authenticated;
grant select, insert, update on public.proposal_closing_activity_events_deep to authenticated;

create policy proposal_presentation_sessions_deep_select on public.proposal_presentation_sessions_deep for select using (private.company_access(company_id));
create policy proposal_presentation_sessions_deep_insert on public.proposal_presentation_sessions_deep for insert with check (private.company_access(company_id));
create policy proposal_presentation_sessions_deep_update on public.proposal_presentation_sessions_deep for update using (private.company_access(company_id)) with check (private.company_access(company_id));

create policy proposal_option_tracking_deep_select on public.proposal_option_tracking_deep for select using (private.company_access(company_id));
create policy proposal_option_tracking_deep_insert on public.proposal_option_tracking_deep for insert with check (private.company_access(company_id));
create policy proposal_option_tracking_deep_update on public.proposal_option_tracking_deep for update using (private.company_access(company_id)) with check (private.company_access(company_id));

create policy contract_review_meetings_deep_select on public.contract_review_meetings_deep for select using (private.company_access(company_id));
create policy contract_review_meetings_deep_insert on public.contract_review_meetings_deep for insert with check (private.company_access(company_id));
create policy contract_review_meetings_deep_update on public.contract_review_meetings_deep for update using (private.company_access(company_id)) with check (private.company_access(company_id));

create policy selected_scope_locks_deep_select on public.selected_scope_locks_deep for select using (private.company_access(company_id));
create policy selected_scope_locks_deep_insert on public.selected_scope_locks_deep for insert with check (private.company_access(company_id));
create policy selected_scope_locks_deep_update on public.selected_scope_locks_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy signing_readiness_checks_deep_select on public.signing_readiness_checks_deep for select using (private.company_access(company_id));
create policy signing_readiness_checks_deep_insert on public.signing_readiness_checks_deep for insert with check (private.company_access(company_id));
create policy signing_readiness_checks_deep_update on public.signing_readiness_checks_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy homeowner_decision_history_deep_select on public.homeowner_decision_history_deep for select using (private.company_access(company_id));
create policy homeowner_decision_history_deep_insert on public.homeowner_decision_history_deep for insert with check (private.company_access(company_id));
create policy homeowner_decision_history_deep_update on public.homeowner_decision_history_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy proposal_followup_tasks_deep_select on public.proposal_followup_tasks_deep for select using (private.company_access(company_id));
create policy proposal_followup_tasks_deep_insert on public.proposal_followup_tasks_deep for insert with check (private.company_access(company_id));
create policy proposal_followup_tasks_deep_update on public.proposal_followup_tasks_deep for update using (private.company_access(company_id)) with check (private.company_access(company_id));

create policy proposal_closing_activity_events_deep_select on public.proposal_closing_activity_events_deep for select using (private.company_access(company_id));
create policy proposal_closing_activity_events_deep_insert on public.proposal_closing_activity_events_deep for insert with check (private.company_access(company_id));
create policy proposal_closing_activity_events_deep_update on public.proposal_closing_activity_events_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));
