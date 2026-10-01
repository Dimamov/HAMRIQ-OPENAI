create table if not exists public.guided_walkthrough_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null default auth.uid(),
  walkthrough_key text not null,
  current_step_key text,
  status text not null default 'in_progress' check (status in ('not_started','in_progress','completed','dismissed','reset')),
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  last_seen_at timestamptz not null default now(),
  progress jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.onboarding_checklists_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  assigned_user_id uuid not null,
  assigned_by uuid default auth.uid(),
  checklist_name text not null,
  role_scope text not null default 'rep' check (role_scope in ('rep','manager','production','office','admin','crew','custom')),
  status text not null default 'assigned' check (status in ('assigned','in_progress','completed','blocked','archived')),
  due_date date,
  completed_at timestamptz,
  completion_percent integer not null default 0 check (completion_percent between 0 and 100),
  checklist_items jsonb not null default '[]'::jsonb,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.training_quiz_attempts_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  training_module_id uuid,
  user_id uuid not null default auth.uid(),
  attempt_number integer not null default 1,
  score_percent numeric(5,2),
  passed boolean not null default false,
  answers jsonb not null default '{}'::jsonb,
  ai_feedback text,
  manager_review_required boolean not null default false,
  reviewed_by uuid,
  reviewed_at timestamptz,
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.help_feedback_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null default auth.uid(),
  source_type text not null default 'help_article' check (source_type in ('help_article','walkthrough','hammy_answer','training','support_prompt','other')),
  source_key text not null,
  rating integer check (rating between 1 and 5),
  feedback_text text,
  follow_up_required boolean not null default false,
  resolved_by uuid,
  resolved_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.policy_acknowledgment_requirements_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  title text not null,
  policy_type text not null default 'company' check (policy_type in ('company','safety','legal','privacy','sales','production','payroll','custom')),
  required_for_roles text[] not null default array['rep','manager'],
  document_record_id uuid,
  active boolean not null default true,
  due_days_after_assignment integer not null default 7,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.policy_acknowledgment_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  requirement_id uuid not null references public.policy_acknowledgment_requirements_deep(id) on delete cascade,
  user_id uuid not null,
  status text not null default 'assigned' check (status in ('assigned','viewed','acknowledged','overdue','waived')),
  acknowledged_at timestamptz,
  signature_text text,
  ip_address text,
  user_agent text,
  waiver_reason text,
  waived_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.hammy_knowledge_queries_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null default auth.uid(),
  query_text text not null,
  answer_text text,
  answer_source_ids uuid[] not null default '{}',
  confidence numeric(5,2),
  human_review_required boolean not null default true,
  reviewed_by uuid,
  reviewed_at timestamptz,
  feedback_rating integer check (feedback_rating between 1 and 5),
  created_at timestamptz not null default now()
);

create table if not exists public.support_ticket_escalations_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  created_by uuid not null default auth.uid(),
  assigned_to uuid,
  related_table text,
  related_id uuid,
  issue_type text not null default 'help_needed',
  priority text not null default 'normal' check (priority in ('low','normal','high','urgent')),
  status text not null default 'open' check (status in ('open','in_progress','waiting','resolved','closed')),
  subject text not null,
  description text,
  resolution_notes text,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists guided_walkthrough_runs_deep_company_user_idx on public.guided_walkthrough_runs_deep(company_id, user_id, status);
create index if not exists onboarding_checklists_deep_company_user_idx on public.onboarding_checklists_deep(company_id, assigned_user_id, status);
create index if not exists training_quiz_attempts_deep_company_user_idx on public.training_quiz_attempts_deep(company_id, user_id, passed);
create index if not exists help_feedback_events_deep_company_idx on public.help_feedback_events_deep(company_id, follow_up_required);
create index if not exists policy_ack_requirements_deep_company_idx on public.policy_acknowledgment_requirements_deep(company_id, active);
create index if not exists policy_ack_events_deep_company_user_idx on public.policy_acknowledgment_events_deep(company_id, user_id, status);
create index if not exists hammy_knowledge_queries_deep_company_user_idx on public.hammy_knowledge_queries_deep(company_id, user_id, human_review_required);
create index if not exists support_ticket_escalations_deep_company_status_idx on public.support_ticket_escalations_deep(company_id, status, priority);

alter table public.guided_walkthrough_runs_deep enable row level security;
alter table public.onboarding_checklists_deep enable row level security;
alter table public.training_quiz_attempts_deep enable row level security;
alter table public.help_feedback_events_deep enable row level security;
alter table public.policy_acknowledgment_requirements_deep enable row level security;
alter table public.policy_acknowledgment_events_deep enable row level security;
alter table public.hammy_knowledge_queries_deep enable row level security;
alter table public.support_ticket_escalations_deep enable row level security;

revoke all on public.guided_walkthrough_runs_deep from anon, authenticated;
revoke all on public.onboarding_checklists_deep from anon, authenticated;
revoke all on public.training_quiz_attempts_deep from anon, authenticated;
revoke all on public.help_feedback_events_deep from anon, authenticated;
revoke all on public.policy_acknowledgment_requirements_deep from anon, authenticated;
revoke all on public.policy_acknowledgment_events_deep from anon, authenticated;
revoke all on public.hammy_knowledge_queries_deep from anon, authenticated;
revoke all on public.support_ticket_escalations_deep from anon, authenticated;

grant select, insert, update on public.guided_walkthrough_runs_deep to authenticated;
grant select, insert, update on public.onboarding_checklists_deep to authenticated;
grant select, insert, update on public.training_quiz_attempts_deep to authenticated;
grant select, insert, update on public.help_feedback_events_deep to authenticated;
grant select, insert, update on public.policy_acknowledgment_requirements_deep to authenticated;
grant select, insert, update on public.policy_acknowledgment_events_deep to authenticated;
grant select, insert, update on public.hammy_knowledge_queries_deep to authenticated;
grant select, insert, update on public.support_ticket_escalations_deep to authenticated;

drop policy if exists guided_walkthrough_runs_deep_user_or_manager on public.guided_walkthrough_runs_deep;
create policy guided_walkthrough_runs_deep_user_or_manager on public.guided_walkthrough_runs_deep
  for all to authenticated
  using (private.is_manager(company_id) or user_id = (select auth.uid()))
  with check (private.is_manager(company_id) or user_id = (select auth.uid()));

drop policy if exists onboarding_checklists_deep_user_or_manager on public.onboarding_checklists_deep;
create policy onboarding_checklists_deep_user_or_manager on public.onboarding_checklists_deep
  for all to authenticated
  using (private.is_manager(company_id) or assigned_user_id = (select auth.uid()))
  with check (private.is_manager(company_id) or assigned_user_id = (select auth.uid()));

drop policy if exists training_quiz_attempts_deep_user_or_manager on public.training_quiz_attempts_deep;
create policy training_quiz_attempts_deep_user_or_manager on public.training_quiz_attempts_deep
  for all to authenticated
  using (private.is_manager(company_id) or user_id = (select auth.uid()))
  with check (private.is_manager(company_id) or user_id = (select auth.uid()));

drop policy if exists help_feedback_events_deep_company on public.help_feedback_events_deep;
create policy help_feedback_events_deep_company on public.help_feedback_events_deep
  for all to authenticated
  using (private.company_access(company_id))
  with check (private.company_access(company_id));

drop policy if exists policy_ack_requirements_deep_manager on public.policy_acknowledgment_requirements_deep;
create policy policy_ack_requirements_deep_manager on public.policy_acknowledgment_requirements_deep
  for all to authenticated
  using (private.is_manager(company_id))
  with check (private.is_manager(company_id));

drop policy if exists policy_ack_events_deep_user_or_manager on public.policy_acknowledgment_events_deep;
create policy policy_ack_events_deep_user_or_manager on public.policy_acknowledgment_events_deep
  for all to authenticated
  using (private.is_manager(company_id) or user_id = (select auth.uid()))
  with check (private.is_manager(company_id) or user_id = (select auth.uid()));

drop policy if exists hammy_knowledge_queries_deep_user_or_manager on public.hammy_knowledge_queries_deep;
create policy hammy_knowledge_queries_deep_user_or_manager on public.hammy_knowledge_queries_deep
  for all to authenticated
  using (private.is_manager(company_id) or user_id = (select auth.uid()))
  with check (private.is_manager(company_id) or user_id = (select auth.uid()));

drop policy if exists support_ticket_escalations_deep_company on public.support_ticket_escalations_deep;
create policy support_ticket_escalations_deep_company on public.support_ticket_escalations_deep
  for all to authenticated
  using (private.company_access(company_id))
  with check (private.company_access(company_id));
