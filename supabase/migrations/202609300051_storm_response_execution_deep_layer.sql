-- HAMRIQ storm-response execution layer
-- Storm response plans, affected property queues, canvassing assignments,
-- reinspection campaigns, evidence packets, storm ROI, provider imports,
-- and activity history.

create table if not exists public.storm_response_work_plans_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  storm_event_id uuid null,
  plan_name text not null,
  response_status text not null default 'draft' check (response_status in ('draft','active','paused','completed','archived')),
  target_markets text[] not null default '{}',
  severity_summary jsonb not null default '{}'::jsonb,
  provider_source text not null default 'manual',
  ai_summary text,
  requires_human_review boolean not null default true,
  approved_by uuid,
  approved_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.storm_affected_property_queues_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  work_plan_id uuid not null references public.storm_response_work_plans_deep(id) on delete cascade,
  property_id uuid,
  contact_id uuid,
  job_id uuid,
  address_text text,
  queue_status text not null default 'queued' check (queue_status in ('queued','assigned','contacted','inspection_set','not_interested','converted','dead')),
  severity_score numeric(8,2) not null default 0,
  opportunity_score numeric(8,2) not null default 0,
  reason_added text,
  assigned_to uuid,
  assigned_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.storm_canvassing_assignments_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  work_plan_id uuid not null references public.storm_response_work_plans_deep(id) on delete cascade,
  territory_id uuid,
  assigned_rep_id uuid not null,
  assignment_status text not null default 'assigned' check (assignment_status in ('assigned','in_progress','paused','completed','cancelled')),
  start_date date,
  end_date date,
  target_doors integer not null default 0,
  knocked_doors integer not null default 0,
  conversations integer not null default 0,
  appointments_set integer not null default 0,
  door_hangers_placed integer not null default 0,
  manager_notes text,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.storm_reinspection_campaigns_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  work_plan_id uuid not null references public.storm_response_work_plans_deep(id) on delete cascade,
  campaign_name text not null,
  campaign_status text not null default 'draft' check (campaign_status in ('draft','active','paused','completed','archived')),
  target_count integer not null default 0,
  contacted_count integer not null default 0,
  scheduled_count integer not null default 0,
  completed_count integer not null default 0,
  converted_count integer not null default 0,
  message_template text,
  ai_generated boolean not null default false,
  requires_human_review boolean not null default true,
  approved_by uuid,
  approved_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.hail_wind_evidence_packets_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  work_plan_id uuid references public.storm_response_work_plans_deep(id) on delete set null,
  job_id uuid,
  contact_id uuid,
  packet_status text not null default 'draft' check (packet_status in ('draft','review_needed','approved','sent','archived')),
  storm_date date,
  hail_size_inches numeric(5,2),
  wind_speed_mph numeric(6,2),
  source_provider text not null default 'manual',
  evidence_summary text,
  packet_assets jsonb not null default '[]'::jsonb,
  ai_generated boolean not null default false,
  requires_human_review boolean not null default true,
  approved_by uuid,
  approved_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.storm_roi_snapshots_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  work_plan_id uuid not null references public.storm_response_work_plans_deep(id) on delete cascade,
  snapshot_date date not null default current_date,
  spend_cents bigint not null default 0,
  leads_created integer not null default 0,
  inspections_completed integer not null default 0,
  contracts_signed integer not null default 0,
  revenue_cents bigint not null default 0,
  gross_profit_cents bigint not null default 0,
  roi_notes text,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.storm_provider_import_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  provider_name text not null,
  import_status text not null default 'pending' check (import_status in ('pending','running','completed','failed','cancelled')),
  imported_records integer not null default 0,
  matched_properties integer not null default 0,
  error_count integer not null default 0,
  source_file_name text,
  source_metadata jsonb not null default '{}'::jsonb,
  started_at timestamptz,
  completed_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.storm_response_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  work_plan_id uuid references public.storm_response_work_plans_deep(id) on delete cascade,
  job_id uuid,
  contact_id uuid,
  actor_id uuid not null default auth.uid(),
  event_type text not null,
  event_summary text not null,
  event_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists storm_response_work_plans_deep_company_idx on public.storm_response_work_plans_deep(company_id, response_status);
create index if not exists storm_affected_property_queues_deep_company_idx on public.storm_affected_property_queues_deep(company_id, queue_status);
create index if not exists storm_canvassing_assignments_deep_rep_idx on public.storm_canvassing_assignments_deep(company_id, assigned_rep_id, assignment_status);
create index if not exists storm_reinspection_campaigns_deep_company_idx on public.storm_reinspection_campaigns_deep(company_id, campaign_status);
create index if not exists hail_wind_evidence_packets_deep_job_idx on public.hail_wind_evidence_packets_deep(company_id, job_id, packet_status);
create index if not exists storm_roi_snapshots_deep_plan_idx on public.storm_roi_snapshots_deep(company_id, work_plan_id, snapshot_date desc);
create index if not exists storm_provider_import_runs_deep_company_idx on public.storm_provider_import_runs_deep(company_id, provider_name, import_status);
create index if not exists storm_response_activity_events_deep_plan_idx on public.storm_response_activity_events_deep(company_id, work_plan_id, created_at desc);

alter table public.storm_response_work_plans_deep enable row level security;
alter table public.storm_affected_property_queues_deep enable row level security;
alter table public.storm_canvassing_assignments_deep enable row level security;
alter table public.storm_reinspection_campaigns_deep enable row level security;
alter table public.hail_wind_evidence_packets_deep enable row level security;
alter table public.storm_roi_snapshots_deep enable row level security;
alter table public.storm_provider_import_runs_deep enable row level security;
alter table public.storm_response_activity_events_deep enable row level security;

revoke all on public.storm_response_work_plans_deep from anon, authenticated;
revoke all on public.storm_affected_property_queues_deep from anon, authenticated;
revoke all on public.storm_canvassing_assignments_deep from anon, authenticated;
revoke all on public.storm_reinspection_campaigns_deep from anon, authenticated;
revoke all on public.hail_wind_evidence_packets_deep from anon, authenticated;
revoke all on public.storm_roi_snapshots_deep from anon, authenticated;
revoke all on public.storm_provider_import_runs_deep from anon, authenticated;
revoke all on public.storm_response_activity_events_deep from anon, authenticated;

grant select, insert, update on public.storm_response_work_plans_deep to authenticated;
grant select, insert, update on public.storm_affected_property_queues_deep to authenticated;
grant select, insert, update on public.storm_canvassing_assignments_deep to authenticated;
grant select, insert, update on public.storm_reinspection_campaigns_deep to authenticated;
grant select, insert, update on public.hail_wind_evidence_packets_deep to authenticated;
grant select, insert, update on public.storm_roi_snapshots_deep to authenticated;
grant select, insert, update on public.storm_provider_import_runs_deep to authenticated;
grant select, insert on public.storm_response_activity_events_deep to authenticated;

create policy storm_response_work_plans_deep_select on public.storm_response_work_plans_deep for select using (private.company_access(company_id));
create policy storm_response_work_plans_deep_write on public.storm_response_work_plans_deep for all using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy storm_affected_property_queues_deep_select on public.storm_affected_property_queues_deep for select using (private.company_access(company_id));
create policy storm_affected_property_queues_deep_write on public.storm_affected_property_queues_deep for all using (private.is_manager(company_id) or assigned_to = auth.uid()) with check (private.is_manager(company_id) or assigned_to = auth.uid());

create policy storm_canvassing_assignments_deep_select on public.storm_canvassing_assignments_deep for select using (private.company_access(company_id));
create policy storm_canvassing_assignments_deep_write on public.storm_canvassing_assignments_deep for all using (private.is_manager(company_id) or assigned_rep_id = auth.uid()) with check (private.is_manager(company_id) or assigned_rep_id = auth.uid());

create policy storm_reinspection_campaigns_deep_select on public.storm_reinspection_campaigns_deep for select using (private.company_access(company_id));
create policy storm_reinspection_campaigns_deep_write on public.storm_reinspection_campaigns_deep for all using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy hail_wind_evidence_packets_deep_select on public.hail_wind_evidence_packets_deep for select using (private.company_access(company_id) and (job_id is null or private.can_job(company_id, job_id)));
create policy hail_wind_evidence_packets_deep_write on public.hail_wind_evidence_packets_deep for all using (private.is_manager(company_id) or (job_id is not null and private.can_job(company_id, job_id))) with check (private.is_manager(company_id) or (job_id is not null and private.can_job(company_id, job_id)));

create policy storm_roi_snapshots_deep_select on public.storm_roi_snapshots_deep for select using (private.is_manager(company_id));
create policy storm_roi_snapshots_deep_write on public.storm_roi_snapshots_deep for all using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy storm_provider_import_runs_deep_select on public.storm_provider_import_runs_deep for select using (private.is_manager(company_id));
create policy storm_provider_import_runs_deep_write on public.storm_provider_import_runs_deep for all using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy storm_response_activity_events_deep_select on public.storm_response_activity_events_deep for select using (private.company_access(company_id));
create policy storm_response_activity_events_deep_insert on public.storm_response_activity_events_deep for insert with check (private.company_access(company_id));
