create table if not exists public.workflow_template_catalog_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  template_name text not null,
  module_key text not null,
  description text not null default '',
  default_trigger_type text not null default 'manual',
  template_payload jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  requires_manager_review boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.custom_workflow_definitions_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  workflow_name text not null,
  workflow_key text not null,
  module_key text not null,
  status text not null default 'draft' check (status in ('draft','review_needed','published','paused','archived')),
  description text not null default '',
  owner_user_id uuid,
  version_number integer not null default 1,
  definition_payload jsonb not null default '{}'::jsonb,
  manager_approved_by uuid,
  manager_approved_at timestamptz,
  published_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, workflow_key, version_number)
);

create table if not exists public.workflow_trigger_conditions_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  workflow_id uuid not null references public.custom_workflow_definitions_deep(id) on delete cascade,
  trigger_name text not null,
  trigger_type text not null check (trigger_type in ('manual','record_created','record_updated','stage_changed','date_due','scheduled','webhook','ai_signal')),
  target_table text not null default '',
  condition_payload jsonb not null default '{}'::jsonb,
  is_required boolean not null default true,
  sort_order integer not null default 0,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.workflow_action_steps_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  workflow_id uuid not null references public.custom_workflow_definitions_deep(id) on delete cascade,
  step_name text not null,
  action_type text not null check (action_type in ('create_task','send_message','update_record','create_approval','notify_manager','create_followup','generate_ai_draft','webhook','hold_for_review')),
  action_payload jsonb not null default '{}'::jsonb,
  sort_order integer not null default 0,
  requires_human_review boolean not null default false,
  is_active boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.workflow_approval_gates_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  workflow_id uuid not null references public.custom_workflow_definitions_deep(id) on delete cascade,
  gate_name text not null,
  gate_type text not null default 'manager' check (gate_type in ('manager','role','specific_user','system')),
  required_role text not null default 'manager',
  approval_payload jsonb not null default '{}'::jsonb,
  blocks_execution boolean not null default true,
  sort_order integer not null default 0,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.workflow_execution_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  workflow_id uuid not null references public.custom_workflow_definitions_deep(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  target_record_type text not null default '',
  target_record_id uuid,
  run_status text not null default 'queued' check (run_status in ('queued','running','waiting_for_approval','completed','failed','canceled','rolled_back')),
  trigger_context jsonb not null default '{}'::jsonb,
  started_at timestamptz,
  completed_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.workflow_execution_step_logs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  workflow_run_id uuid not null references public.workflow_execution_runs_deep(id) on delete cascade,
  workflow_step_id uuid references public.workflow_action_steps_deep(id) on delete set null,
  step_status text not null default 'pending' check (step_status in ('pending','running','waiting_for_review','completed','failed','skipped','rolled_back')),
  input_payload jsonb not null default '{}'::jsonb,
  output_payload jsonb not null default '{}'::jsonb,
  error_message text not null default '',
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.workflow_failure_recovery_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  workflow_run_id uuid not null references public.workflow_execution_runs_deep(id) on delete cascade,
  failure_type text not null default 'unknown',
  severity text not null default 'medium' check (severity in ('low','medium','high','critical')),
  recovery_status text not null default 'open' check (recovery_status in ('open','assigned','resolved','dismissed')),
  recovery_payload jsonb not null default '{}'::jsonb,
  assigned_to uuid,
  resolved_by uuid,
  resolved_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_workflow_template_catalog_deep_company on public.workflow_template_catalog_deep(company_id, module_key, is_active);
create index if not exists idx_custom_workflow_definitions_deep_company on public.custom_workflow_definitions_deep(company_id, module_key, status);
create index if not exists idx_workflow_trigger_conditions_deep_workflow on public.workflow_trigger_conditions_deep(company_id, workflow_id);
create index if not exists idx_workflow_action_steps_deep_workflow on public.workflow_action_steps_deep(company_id, workflow_id, sort_order);
create index if not exists idx_workflow_approval_gates_deep_workflow on public.workflow_approval_gates_deep(company_id, workflow_id, sort_order);
create index if not exists idx_workflow_execution_runs_deep_company on public.workflow_execution_runs_deep(company_id, workflow_id, run_status);
create index if not exists idx_workflow_execution_runs_deep_job on public.workflow_execution_runs_deep(company_id, job_id);
create index if not exists idx_workflow_execution_step_logs_deep_run on public.workflow_execution_step_logs_deep(company_id, workflow_run_id);
create index if not exists idx_workflow_failure_recovery_events_deep_run on public.workflow_failure_recovery_events_deep(company_id, workflow_run_id, recovery_status);

alter table public.workflow_template_catalog_deep enable row level security;
alter table public.custom_workflow_definitions_deep enable row level security;
alter table public.workflow_trigger_conditions_deep enable row level security;
alter table public.workflow_action_steps_deep enable row level security;
alter table public.workflow_approval_gates_deep enable row level security;
alter table public.workflow_execution_runs_deep enable row level security;
alter table public.workflow_execution_step_logs_deep enable row level security;
alter table public.workflow_failure_recovery_events_deep enable row level security;

revoke all on public.workflow_template_catalog_deep from anon, authenticated;
revoke all on public.custom_workflow_definitions_deep from anon, authenticated;
revoke all on public.workflow_trigger_conditions_deep from anon, authenticated;
revoke all on public.workflow_action_steps_deep from anon, authenticated;
revoke all on public.workflow_approval_gates_deep from anon, authenticated;
revoke all on public.workflow_execution_runs_deep from anon, authenticated;
revoke all on public.workflow_execution_step_logs_deep from anon, authenticated;
revoke all on public.workflow_failure_recovery_events_deep from anon, authenticated;

grant select, insert, update on public.workflow_template_catalog_deep to authenticated;
grant select, insert, update on public.custom_workflow_definitions_deep to authenticated;
grant select, insert, update on public.workflow_trigger_conditions_deep to authenticated;
grant select, insert, update on public.workflow_action_steps_deep to authenticated;
grant select, insert, update on public.workflow_approval_gates_deep to authenticated;
grant select, insert, update on public.workflow_execution_runs_deep to authenticated;
grant select, insert, update on public.workflow_execution_step_logs_deep to authenticated;
grant select, insert, update on public.workflow_failure_recovery_events_deep to authenticated;

create policy workflow_template_catalog_deep_manager_all on public.workflow_template_catalog_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy workflow_template_catalog_deep_company_select on public.workflow_template_catalog_deep for select to authenticated using (private.company_access(company_id));
create policy custom_workflow_definitions_deep_manager_all on public.custom_workflow_definitions_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy custom_workflow_definitions_deep_company_select on public.custom_workflow_definitions_deep for select to authenticated using (private.company_access(company_id));
create policy workflow_trigger_conditions_deep_manager_all on public.workflow_trigger_conditions_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy workflow_trigger_conditions_deep_company_select on public.workflow_trigger_conditions_deep for select to authenticated using (private.company_access(company_id));
create policy workflow_action_steps_deep_manager_all on public.workflow_action_steps_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy workflow_action_steps_deep_company_select on public.workflow_action_steps_deep for select to authenticated using (private.company_access(company_id));
create policy workflow_approval_gates_deep_manager_all on public.workflow_approval_gates_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy workflow_approval_gates_deep_company_select on public.workflow_approval_gates_deep for select to authenticated using (private.company_access(company_id));
create policy workflow_execution_runs_deep_manager_all on public.workflow_execution_runs_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy workflow_execution_runs_deep_company_insert on public.workflow_execution_runs_deep for insert to authenticated with check (private.company_access(company_id));
create policy workflow_execution_runs_deep_company_select on public.workflow_execution_runs_deep for select to authenticated using (private.company_access(company_id));
create policy workflow_execution_step_logs_deep_manager_all on public.workflow_execution_step_logs_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy workflow_execution_step_logs_deep_company_select on public.workflow_execution_step_logs_deep for select to authenticated using (private.company_access(company_id));
create policy workflow_failure_recovery_events_deep_manager_all on public.workflow_failure_recovery_events_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy workflow_failure_recovery_events_deep_company_select on public.workflow_failure_recovery_events_deep for select to authenticated using (private.company_access(company_id));