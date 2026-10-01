create table if not exists public.bulk_action_execution_batches_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  requested_by uuid not null default auth.uid(),
  batch_name text not null,
  target_record_type text not null,
  action_type text not null,
  status text not null default 'draft' check (status in ('draft','pending_approval','approved','running','completed','partially_completed','failed','cancelled','reversed')),
  total_records integer not null default 0,
  affected_records integer not null default 0,
  requires_manager_approval boolean not null default true,
  manager_review_status text not null default 'pending' check (manager_review_status in ('not_required','pending','approved','rejected','changes_requested')),
  request_payload jsonb not null default '{}'::jsonb,
  preview_payload jsonb not null default '{}'::jsonb,
  risk_notes text,
  approved_by uuid,
  approved_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.bulk_action_execution_items_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  batch_id uuid not null references public.bulk_action_execution_batches_deep(id) on delete cascade,
  target_record_type text not null,
  target_record_id uuid,
  action_status text not null default 'queued' check (action_status in ('queued','skipped','running','completed','failed','reversed')),
  before_snapshot jsonb not null default '{}'::jsonb,
  after_snapshot jsonb not null default '{}'::jsonb,
  error_message text,
  processed_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.manager_approval_center_items_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  source_type text not null,
  source_id uuid,
  approval_category text not null,
  title text not null,
  summary text,
  priority text not null default 'normal' check (priority in ('low','normal','high','urgent')),
  status text not null default 'pending' check (status in ('pending','approved','rejected','changes_requested','cancelled','expired')),
  assigned_manager_id uuid,
  requested_by uuid not null default auth.uid(),
  due_at timestamptz,
  decision_notes text,
  decision_by uuid,
  decision_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.approval_decision_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  approval_item_id uuid not null references public.manager_approval_center_items_deep(id) on delete cascade,
  decision text not null check (decision in ('approved','rejected','changes_requested','cancelled','reopened','delegated')),
  decision_by uuid not null default auth.uid(),
  decision_notes text,
  previous_status text,
  new_status text not null,
  attachments jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.approval_routing_rules_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  rule_name text not null,
  approval_category text not null,
  applies_to_role text,
  amount_threshold_cents bigint not null default 0,
  conditions jsonb not null default '{}'::jsonb,
  assigned_manager_id uuid,
  escalation_manager_id uuid,
  is_active boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.bulk_action_reversal_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  batch_id uuid not null references public.bulk_action_execution_batches_deep(id) on delete cascade,
  requested_by uuid not null default auth.uid(),
  status text not null default 'pending_approval' check (status in ('pending_approval','approved','running','completed','failed','rejected','cancelled')),
  reason text not null,
  records_to_reverse integer not null default 0,
  records_reversed integer not null default 0,
  manager_review_status text not null default 'pending' check (manager_review_status in ('pending','approved','rejected')),
  approved_by uuid,
  approved_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.approval_escalation_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  approval_item_id uuid not null references public.manager_approval_center_items_deep(id) on delete cascade,
  escalated_from uuid,
  escalated_to uuid,
  escalation_reason text not null,
  status text not null default 'open' check (status in ('open','acknowledged','resolved','cancelled')),
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create table if not exists public.bulk_approval_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  actor_id uuid not null default auth.uid(),
  event_type text not null,
  source_type text not null,
  source_id uuid,
  description text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_bulk_action_batches_company_status on public.bulk_action_execution_batches_deep(company_id,status);
create index if not exists idx_bulk_action_items_company_batch on public.bulk_action_execution_items_deep(company_id,batch_id);
create index if not exists idx_manager_approval_items_company_status on public.manager_approval_center_items_deep(company_id,status,priority);
create index if not exists idx_approval_decisions_company_item on public.approval_decision_events_deep(company_id,approval_item_id);
create index if not exists idx_approval_routing_rules_company on public.approval_routing_rules_deep(company_id,is_active);
create index if not exists idx_bulk_reversal_company_batch on public.bulk_action_reversal_runs_deep(company_id,batch_id);
create index if not exists idx_approval_escalation_company_status on public.approval_escalation_events_deep(company_id,status);
create index if not exists idx_bulk_approval_activity_company on public.bulk_approval_activity_events_deep(company_id,created_at desc);

alter table public.bulk_action_execution_batches_deep enable row level security;
alter table public.bulk_action_execution_items_deep enable row level security;
alter table public.manager_approval_center_items_deep enable row level security;
alter table public.approval_decision_events_deep enable row level security;
alter table public.approval_routing_rules_deep enable row level security;
alter table public.bulk_action_reversal_runs_deep enable row level security;
alter table public.approval_escalation_events_deep enable row level security;
alter table public.bulk_approval_activity_events_deep enable row level security;

revoke all on public.bulk_action_execution_batches_deep from anon, authenticated;
revoke all on public.bulk_action_execution_items_deep from anon, authenticated;
revoke all on public.manager_approval_center_items_deep from anon, authenticated;
revoke all on public.approval_decision_events_deep from anon, authenticated;
revoke all on public.approval_routing_rules_deep from anon, authenticated;
revoke all on public.bulk_action_reversal_runs_deep from anon, authenticated;
revoke all on public.approval_escalation_events_deep from anon, authenticated;
revoke all on public.bulk_approval_activity_events_deep from anon, authenticated;

grant select, insert, update on public.bulk_action_execution_batches_deep to authenticated;
grant select, insert, update on public.bulk_action_execution_items_deep to authenticated;
grant select, insert, update on public.manager_approval_center_items_deep to authenticated;
grant select, insert, update on public.approval_decision_events_deep to authenticated;
grant select, insert, update on public.approval_routing_rules_deep to authenticated;
grant select, insert, update on public.bulk_action_reversal_runs_deep to authenticated;
grant select, insert, update on public.approval_escalation_events_deep to authenticated;
grant select, insert, update on public.bulk_approval_activity_events_deep to authenticated;

create policy bulk_action_batches_company_access_deep on public.bulk_action_execution_batches_deep for select using (private.company_access(company_id));
create policy bulk_action_batches_insert_deep on public.bulk_action_execution_batches_deep for insert with check (private.company_access(company_id));
create policy bulk_action_batches_update_manager_deep on public.bulk_action_execution_batches_deep for update using (private.is_manager(company_id) or requested_by = auth.uid()) with check (private.company_access(company_id));

create policy bulk_action_items_company_access_deep on public.bulk_action_execution_items_deep for select using (private.company_access(company_id));
create policy bulk_action_items_insert_deep on public.bulk_action_execution_items_deep for insert with check (private.company_access(company_id));
create policy bulk_action_items_update_manager_deep on public.bulk_action_execution_items_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy manager_approval_items_company_access_deep on public.manager_approval_center_items_deep for select using (private.company_access(company_id));
create policy manager_approval_items_insert_deep on public.manager_approval_center_items_deep for insert with check (private.company_access(company_id));
create policy manager_approval_items_update_manager_deep on public.manager_approval_center_items_deep for update using (private.is_manager(company_id) or requested_by = auth.uid()) with check (private.company_access(company_id));

create policy approval_decision_events_company_access_deep on public.approval_decision_events_deep for select using (private.company_access(company_id));
create policy approval_decision_events_insert_manager_deep on public.approval_decision_events_deep for insert with check (private.is_manager(company_id));
create policy approval_decision_events_update_manager_deep on public.approval_decision_events_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy approval_routing_rules_company_access_deep on public.approval_routing_rules_deep for select using (private.company_access(company_id));
create policy approval_routing_rules_insert_manager_deep on public.approval_routing_rules_deep for insert with check (private.is_manager(company_id));
create policy approval_routing_rules_update_manager_deep on public.approval_routing_rules_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy bulk_reversal_company_access_deep on public.bulk_action_reversal_runs_deep for select using (private.company_access(company_id));
create policy bulk_reversal_insert_company_deep on public.bulk_action_reversal_runs_deep for insert with check (private.company_access(company_id));
create policy bulk_reversal_update_manager_deep on public.bulk_action_reversal_runs_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy approval_escalation_company_access_deep on public.approval_escalation_events_deep for select using (private.company_access(company_id));
create policy approval_escalation_insert_company_deep on public.approval_escalation_events_deep for insert with check (private.company_access(company_id));
create policy approval_escalation_update_manager_deep on public.approval_escalation_events_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy bulk_approval_activity_company_access_deep on public.bulk_approval_activity_events_deep for select using (private.company_access(company_id));
create policy bulk_approval_activity_insert_company_deep on public.bulk_approval_activity_events_deep for insert with check (private.company_access(company_id));
create policy bulk_approval_activity_update_manager_deep on public.bulk_approval_activity_events_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));
