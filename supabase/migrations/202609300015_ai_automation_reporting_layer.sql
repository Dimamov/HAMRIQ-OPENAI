-- HAMRIQ AI automation/reporting layer
-- Adds configurable trigger actions after lead status moves, Hammy command logs,
-- AI action suggestions, bulk action execution tracking, report snapshots, and data-quality findings.

alter table public.lead_stage_triggers add column if not exists action_type text not null default 'manual_tbd';
alter table public.lead_stage_triggers add column if not exists action_config jsonb not null default '{}'::jsonb;
alter table public.lead_stage_triggers add column if not exists requires_manager_approval boolean not null default true;
alter table public.lead_stage_trigger_runs add column if not exists result_summary text not null default '';

create table if not exists public.hammy_command_logs (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  user_id uuid not null default auth.uid(), job_id uuid,
  command_text text not null default '', command_source text not null default 'typed',
  interpreted_intent text not null default '', status text not null default 'captured',
  result jsonb not null default '{}'::jsonb, created_at timestamptz not null default now(),
  unique(company_id,id), foreign key(company_id,user_id) references public.users(company_id,id),
  foreign key(company_id,job_id) references public.jobs(company_id,id)
);

create table if not exists public.ai_action_suggestions (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  job_id uuid, contact_id uuid, suggestion_type text not null, title text not null,
  explanation text not null default '', supporting_data jsonb not null default '{}'::jsonb,
  status text not null default 'needs_review', created_by_ai boolean not null default true,
  reviewed_by uuid, reviewed_at timestamptz, created_at timestamptz not null default now(),
  unique(company_id,id), foreign key(company_id,job_id) references public.jobs(company_id,id),
  foreign key(company_id,contact_id) references public.contacts(company_id,id),
  foreign key(company_id,reviewed_by) references public.users(company_id,id)
);

create table if not exists public.bulk_action_batches (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  action_type text not null, preview jsonb not null default '{}'::jsonb,
  status text not null default 'preview', requested_by uuid not null default auth.uid(),
  approved_by uuid, approved_at timestamptz, executed_at timestamptz, created_at timestamptz not null default now(),
  unique(company_id,id), foreign key(company_id,requested_by) references public.users(company_id,id),
  foreign key(company_id,approved_by) references public.users(company_id,id)
);

create table if not exists public.bulk_action_items (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  batch_id uuid not null, entity_type text not null, entity_id uuid not null,
  before_state jsonb, after_state jsonb, status text not null default 'pending', error_message text not null default '',
  unique(company_id,id), foreign key(company_id,batch_id) references public.bulk_action_batches(company_id,id)
);

create table if not exists public.report_snapshots (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  report_type text not null, period_start date, period_end date,
  metrics jsonb not null default '{}'::jsonb, narrative text not null default '',
  created_by uuid default auth.uid(), created_at timestamptz not null default now(),
  unique(company_id,id), foreign key(company_id,created_by) references public.users(company_id,id)
);

create table if not exists public.data_quality_findings (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  entity_type text not null, entity_id uuid, severity text not null default 'medium',
  finding text not null, recommended_fix text not null default '',
  status text not null default 'open', resolved_by uuid, resolved_at timestamptz,
  created_at timestamptz not null default now(), unique(company_id,id),
  foreign key(company_id,resolved_by) references public.users(company_id,id)
);

alter table public.hammy_command_logs enable row level security;
alter table public.ai_action_suggestions enable row level security;
alter table public.bulk_action_batches enable row level security;
alter table public.bulk_action_items enable row level security;
alter table public.report_snapshots enable row level security;
alter table public.data_quality_findings enable row level security;

revoke all on public.hammy_command_logs, public.ai_action_suggestions, public.bulk_action_batches, public.bulk_action_items, public.report_snapshots, public.data_quality_findings from anon, authenticated;
grant select, insert, update on public.hammy_command_logs, public.ai_action_suggestions, public.bulk_action_batches, public.bulk_action_items, public.report_snapshots, public.data_quality_findings to authenticated;

create policy hammy_command_logs_read on public.hammy_command_logs for select to authenticated using (private.company_access(company_id) and (private.is_manager(company_id) or user_id = (select auth.uid())));
create policy hammy_command_logs_insert on public.hammy_command_logs for insert to authenticated with check (private.company_access(company_id) and user_id = (select auth.uid()) and (job_id is null or private.can_job(company_id,job_id)));
create policy ai_action_suggestions_read on public.ai_action_suggestions for select to authenticated using (private.company_access(company_id) and (private.is_manager(company_id) or (job_id is not null and private.can_job(company_id,job_id)) or (contact_id is not null and private.can_contact(company_id,contact_id))));
create policy ai_action_suggestions_update on public.ai_action_suggestions for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy bulk_action_batches_read on public.bulk_action_batches for select to authenticated using (private.is_manager(company_id) or requested_by=(select auth.uid()));
create policy bulk_action_batches_insert on public.bulk_action_batches for insert to authenticated with check (private.company_access(company_id) and requested_by=(select auth.uid()));
create policy bulk_action_batches_update on public.bulk_action_batches for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy bulk_action_items_read on public.bulk_action_items for select to authenticated using (private.is_manager(company_id));
create policy bulk_action_items_insert on public.bulk_action_items for insert to authenticated with check (private.is_manager(company_id));
create policy bulk_action_items_update on public.bulk_action_items for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy report_snapshots_read on public.report_snapshots for select to authenticated using (private.is_manager(company_id));
create policy report_snapshots_insert on public.report_snapshots for insert to authenticated with check (private.is_manager(company_id));
create policy data_quality_findings_read on public.data_quality_findings for select to authenticated using (private.is_manager(company_id));
create policy data_quality_findings_update on public.data_quality_findings for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
