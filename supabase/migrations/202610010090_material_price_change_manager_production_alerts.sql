create table if not exists public.material_price_alert_routing_rules_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  created_by uuid not null default auth.uid(),
  rule_name text not null default 'Material price change alert routing',
  applies_to_material_categories text[] not null default array[]::text[],
  alert_on_increase boolean not null default true,
  alert_on_decrease boolean not null default true,
  minimum_change_percent numeric(8,4) not null default 0,
  minimum_change_cents bigint not null default 0,
  notify_managers boolean not null default true,
  notify_production boolean not null default true,
  notify_estimating boolean not null default true,
  require_manager_acknowledgment boolean not null default true,
  require_production_acknowledgment boolean not null default true,
  is_active boolean not null default true,
  routing_config jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.material_price_change_alert_recipients_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  created_by uuid not null default auth.uid(),
  price_change_alert_id uuid not null references public.material_price_change_alerts_deep(id) on delete cascade,
  recipient_user_id uuid,
  recipient_role text not null check (recipient_role in ('manager','production','estimating','admin','owner')),
  alert_channel text not null default 'in_app' check (alert_channel in ('in_app','push','email','sms','hammy','dashboard')),
  delivery_status text not null default 'queued' check (delivery_status in ('queued','sent','delivered','failed','dismissed','acknowledged')),
  acknowledged_at timestamptz,
  acknowledged_by uuid,
  acknowledgment_note text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.production_material_price_impact_cards_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  created_by uuid not null default auth.uid(),
  price_change_alert_id uuid not null references public.material_price_change_alerts_deep(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  production_phase text not null default 'pending_review',
  material_name text not null default '',
  supplier_name text not null default '',
  old_unit_price_cents bigint not null default 0,
  new_unit_price_cents bigint not null default 0,
  price_delta_cents bigint not null default 0,
  price_delta_percent numeric(10,4) not null default 0,
  change_direction text not null check (change_direction in ('increase','decrease','no_change')),
  estimated_job_cost_impact_cents bigint not null default 0,
  affects_open_estimates boolean not null default true,
  affects_signed_contracts boolean not null default false,
  affects_ordered_materials boolean not null default false,
  requires_production_action boolean not null default true,
  production_action_status text not null default 'open' check (production_action_status in ('open','reviewing','adjusted','ignored','closed')),
  production_notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.manager_material_price_decision_queue_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  created_by uuid not null default auth.uid(),
  price_change_alert_id uuid not null references public.material_price_change_alerts_deep(id) on delete cascade,
  decision_status text not null default 'needs_review' check (decision_status in ('needs_review','approved','rejected','deferred','auto_approved')),
  decision_type text not null default 'pricing_update' check (decision_type in ('pricing_update','supplier_change','estimate_adjustment','production_notice','substitution_review')),
  old_pricing_snapshot jsonb not null default '{}'::jsonb,
  new_pricing_snapshot jsonb not null default '{}'::jsonb,
  recommended_action text not null default '',
  manager_decision_note text not null default '',
  decided_by uuid,
  decided_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.material_price_change_alert_activity_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  created_by uuid not null default auth.uid(),
  price_change_alert_id uuid references public.material_price_change_alerts_deep(id) on delete set null,
  activity_type text not null check (activity_type in ('price_increase_detected','price_decrease_detected','manager_alert_created','production_alert_created','recipient_notified','acknowledged','manager_decision_recorded','production_impact_card_created','pricing_updated')),
  actor_user_id uuid,
  activity_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_material_price_alert_routing_rules_company on public.material_price_alert_routing_rules_deep(company_id, is_active);
create index if not exists idx_material_price_alert_recipients_company_alert on public.material_price_change_alert_recipients_deep(company_id, price_change_alert_id);
create index if not exists idx_production_material_price_impact_company_job on public.production_material_price_impact_cards_deep(company_id, job_id);
create index if not exists idx_manager_material_price_decision_queue_company_status on public.manager_material_price_decision_queue_deep(company_id, decision_status);
create index if not exists idx_material_price_change_alert_activity_company_alert on public.material_price_change_alert_activity_deep(company_id, price_change_alert_id);

alter table public.material_price_alert_routing_rules_deep enable row level security;
alter table public.material_price_change_alert_recipients_deep enable row level security;
alter table public.production_material_price_impact_cards_deep enable row level security;
alter table public.manager_material_price_decision_queue_deep enable row level security;
alter table public.material_price_change_alert_activity_deep enable row level security;

revoke all on public.material_price_alert_routing_rules_deep from anon, authenticated;
revoke all on public.material_price_change_alert_recipients_deep from anon, authenticated;
revoke all on public.production_material_price_impact_cards_deep from anon, authenticated;
revoke all on public.manager_material_price_decision_queue_deep from anon, authenticated;
revoke all on public.material_price_change_alert_activity_deep from anon, authenticated;

grant select, insert, update on public.material_price_alert_routing_rules_deep to authenticated;
grant select, insert, update on public.material_price_change_alert_recipients_deep to authenticated;
grant select, insert, update on public.production_material_price_impact_cards_deep to authenticated;
grant select, insert, update on public.manager_material_price_decision_queue_deep to authenticated;
grant select, insert, update on public.material_price_change_alert_activity_deep to authenticated;

drop policy if exists manager_material_price_alert_routing_rules_all on public.material_price_alert_routing_rules_deep;
create policy manager_material_price_alert_routing_rules_all on public.material_price_alert_routing_rules_deep
  for all to authenticated
  using (private.is_manager(company_id))
  with check (private.is_manager(company_id));

drop policy if exists company_material_price_alert_recipients_select on public.material_price_change_alert_recipients_deep;
create policy company_material_price_alert_recipients_select on public.material_price_change_alert_recipients_deep
  for select to authenticated
  using (private.company_access(company_id));

drop policy if exists manager_material_price_alert_recipients_manage on public.material_price_change_alert_recipients_deep;
create policy manager_material_price_alert_recipients_manage on public.material_price_change_alert_recipients_deep
  for all to authenticated
  using (private.is_manager(company_id) or recipient_user_id = auth.uid())
  with check (private.is_manager(company_id) or recipient_user_id = auth.uid());

drop policy if exists company_production_material_price_impact_select on public.production_material_price_impact_cards_deep;
create policy company_production_material_price_impact_select on public.production_material_price_impact_cards_deep
  for select to authenticated
  using (private.company_access(company_id));

drop policy if exists manager_production_material_price_impact_manage on public.production_material_price_impact_cards_deep;
create policy manager_production_material_price_impact_manage on public.production_material_price_impact_cards_deep
  for all to authenticated
  using (private.is_manager(company_id))
  with check (private.is_manager(company_id));

drop policy if exists manager_material_price_decision_queue_manage on public.manager_material_price_decision_queue_deep;
create policy manager_material_price_decision_queue_manage on public.manager_material_price_decision_queue_deep
  for all to authenticated
  using (private.is_manager(company_id))
  with check (private.is_manager(company_id));

drop policy if exists company_material_price_change_alert_activity_select on public.material_price_change_alert_activity_deep;
create policy company_material_price_change_alert_activity_select on public.material_price_change_alert_activity_deep
  for select to authenticated
  using (private.company_access(company_id));

drop policy if exists manager_material_price_change_alert_activity_insert on public.material_price_change_alert_activity_deep;
create policy manager_material_price_change_alert_activity_insert on public.material_price_change_alert_activity_deep
  for insert to authenticated
  with check (private.company_access(company_id));
