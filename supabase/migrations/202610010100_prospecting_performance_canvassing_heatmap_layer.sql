-- Prospecting performance / canvassing heatmap layer
-- Adds rep canvassing performance snapshots, heatmap cells, campaign results, scorecards,
-- coaching alerts, and audit events.

create table if not exists public.prospecting_performance_snapshots_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  rep_user_id uuid not null,
  snapshot_period text not null default 'daily' check (snapshot_period in ('daily','weekly','monthly','campaign','custom')),
  period_start date not null,
  period_end date not null,
  doors_knocked integer not null default 0,
  contacts_made integer not null default 0,
  followups_set integer not null default 0,
  leads_created integer not null default 0,
  inspections_booked integer not null default 0,
  contact_rate numeric(7,4) not null default 0,
  lead_conversion_rate numeric(7,4) not null default 0,
  inspection_conversion_rate numeric(7,4) not null default 0,
  door_hangers_placed integer not null default 0,
  avg_distance_from_property_meters numeric(10,2),
  suspicious_activity_count integer not null default 0,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.canvassing_heatmap_cells_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  zone_name text not null default '',
  city text not null default '',
  county text not null default '',
  state text not null default 'MI',
  center_latitude numeric(10,7),
  center_longitude numeric(10,7),
  radius_meters integer not null default 250,
  doors_knocked integer not null default 0,
  contacts_made integer not null default 0,
  leads_created integer not null default 0,
  inspections_booked integer not null default 0,
  jobs_sold integer not null default 0,
  contact_rate numeric(7,4) not null default 0,
  lead_rate numeric(7,4) not null default 0,
  sold_rate numeric(7,4) not null default 0,
  heat_score numeric(10,2) not null default 0,
  last_activity_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.canvassing_campaign_results_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  campaign_name text not null,
  campaign_type text not null default 'neighborhood' check (campaign_type in ('storm_area','neighborhood','event','direct_mail_followup','custom')),
  territory_zone_id uuid,
  storm_event_id uuid,
  started_at timestamptz,
  ended_at timestamptz,
  target_doors integer not null default 0,
  doors_knocked integer not null default 0,
  contacts_made integer not null default 0,
  leads_created integer not null default 0,
  inspections_booked integer not null default 0,
  contracts_signed integer not null default 0,
  revenue_cents bigint not null default 0,
  materialized_results jsonb not null default '{}'::jsonb,
  status text not null default 'active' check (status in ('planned','active','paused','completed','cancelled')),
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.rep_canvassing_scorecards_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  rep_user_id uuid not null,
  scorecard_period text not null default 'weekly' check (scorecard_period in ('daily','weekly','monthly','campaign')),
  period_start date not null,
  period_end date not null,
  rank_position integer,
  doors_knocked integer not null default 0,
  contacts_made integer not null default 0,
  leads_created integer not null default 0,
  inspections_booked integer not null default 0,
  contact_rate numeric(7,4) not null default 0,
  lead_rate numeric(7,4) not null default 0,
  quality_score numeric(10,2) not null default 0,
  location_compliance_score numeric(10,2) not null default 0,
  coaching_needed boolean not null default false,
  coaching_reason text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.canvassing_manager_coaching_alerts_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  rep_user_id uuid not null,
  alert_type text not null default 'performance_drop' check (alert_type in ('performance_drop','low_contact_rate','low_lead_rate','location_compliance','duplicate_knocks','territory_conflict','high_potential_zone','custom')),
  severity text not null default 'medium' check (severity in ('low','medium','high','critical')),
  title text not null,
  details text not null default '',
  metric_snapshot jsonb not null default '{}'::jsonb,
  status text not null default 'open' check (status in ('open','acknowledged','coaching_scheduled','resolved','dismissed')),
  acknowledged_by uuid,
  acknowledged_at timestamptz,
  resolved_by uuid,
  resolved_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.prospecting_heatmap_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  rep_user_id uuid,
  related_record_id uuid,
  related_record_type text not null default '',
  event_type text not null,
  event_summary text not null default '',
  event_data jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create index if not exists idx_pps_company_rep_period on public.prospecting_performance_snapshots_deep(company_id, rep_user_id, period_start, period_end);
create index if not exists idx_chc_company_zone on public.canvassing_heatmap_cells_deep(company_id, zone_name, city);
create index if not exists idx_ccr_company_status on public.canvassing_campaign_results_deep(company_id, status, started_at);
create index if not exists idx_rcs_company_rep_period on public.rep_canvassing_scorecards_deep(company_id, rep_user_id, period_start, period_end);
create index if not exists idx_cmca_company_status on public.canvassing_manager_coaching_alerts_deep(company_id, status, severity);
create index if not exists idx_phae_company_created on public.prospecting_heatmap_activity_events_deep(company_id, created_at desc);

alter table public.prospecting_performance_snapshots_deep enable row level security;
alter table public.canvassing_heatmap_cells_deep enable row level security;
alter table public.canvassing_campaign_results_deep enable row level security;
alter table public.rep_canvassing_scorecards_deep enable row level security;
alter table public.canvassing_manager_coaching_alerts_deep enable row level security;
alter table public.prospecting_heatmap_activity_events_deep enable row level security;

revoke all on public.prospecting_performance_snapshots_deep from anon, authenticated;
revoke all on public.canvassing_heatmap_cells_deep from anon, authenticated;
revoke all on public.canvassing_campaign_results_deep from anon, authenticated;
revoke all on public.rep_canvassing_scorecards_deep from anon, authenticated;
revoke all on public.canvassing_manager_coaching_alerts_deep from anon, authenticated;
revoke all on public.prospecting_heatmap_activity_events_deep from anon, authenticated;

grant select, insert, update on public.prospecting_performance_snapshots_deep to authenticated;
grant select, insert, update on public.canvassing_heatmap_cells_deep to authenticated;
grant select, insert, update on public.canvassing_campaign_results_deep to authenticated;
grant select, insert, update on public.rep_canvassing_scorecards_deep to authenticated;
grant select, insert, update on public.canvassing_manager_coaching_alerts_deep to authenticated;
grant select, insert, update on public.prospecting_heatmap_activity_events_deep to authenticated;

create policy prospecting_performance_snapshots_select on public.prospecting_performance_snapshots_deep for select to authenticated using (private.company_access(company_id));
create policy prospecting_performance_snapshots_insert on public.prospecting_performance_snapshots_deep for insert to authenticated with check (private.company_access(company_id) and (rep_user_id = auth.uid() or private.is_manager(company_id)));
create policy prospecting_performance_snapshots_update on public.prospecting_performance_snapshots_deep for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy canvassing_heatmap_cells_select on public.canvassing_heatmap_cells_deep for select to authenticated using (private.company_access(company_id));
create policy canvassing_heatmap_cells_insert on public.canvassing_heatmap_cells_deep for insert to authenticated with check (private.is_manager(company_id));
create policy canvassing_heatmap_cells_update on public.canvassing_heatmap_cells_deep for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy canvassing_campaign_results_select on public.canvassing_campaign_results_deep for select to authenticated using (private.company_access(company_id));
create policy canvassing_campaign_results_insert on public.canvassing_campaign_results_deep for insert to authenticated with check (private.is_manager(company_id));
create policy canvassing_campaign_results_update on public.canvassing_campaign_results_deep for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy rep_canvassing_scorecards_select on public.rep_canvassing_scorecards_deep for select to authenticated using (private.company_access(company_id));
create policy rep_canvassing_scorecards_insert on public.rep_canvassing_scorecards_deep for insert to authenticated with check (private.is_manager(company_id));
create policy rep_canvassing_scorecards_update on public.rep_canvassing_scorecards_deep for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy canvassing_manager_coaching_alerts_select on public.canvassing_manager_coaching_alerts_deep for select to authenticated using (private.company_access(company_id));
create policy canvassing_manager_coaching_alerts_insert on public.canvassing_manager_coaching_alerts_deep for insert to authenticated with check (private.is_manager(company_id));
create policy canvassing_manager_coaching_alerts_update on public.canvassing_manager_coaching_alerts_deep for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy prospecting_heatmap_activity_events_select on public.prospecting_heatmap_activity_events_deep for select to authenticated using (private.company_access(company_id));
create policy prospecting_heatmap_activity_events_insert on public.prospecting_heatmap_activity_events_deep for insert to authenticated with check (private.company_access(company_id) and (rep_user_id = auth.uid() or private.is_manager(company_id)));
create policy prospecting_heatmap_activity_events_update on public.prospecting_heatmap_activity_events_deep for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));