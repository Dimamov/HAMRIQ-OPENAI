-- HAMRIQ storm/canvassing intelligence layer
-- Adds storm data provider connection metadata, storm impact scoring, AI neighborhood opportunity scoring,
-- canvassing sessions/heat map rollups, territory conflict warnings, lead distribution rules/recommendations,
-- and lead response SLA escalation tracking.

create table if not exists public.storm_provider_connections (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  provider text not null default 'provider_pending',
  status text not null default 'not_connected',
  subscription_notice text not null default 'Additional subscription required. Contact HAMRIQ for information.',
  config jsonb not null default '{}'::jsonb,
  connected_by uuid default auth.uid(),
  connected_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.storm_impact_scores (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  storm_event_id uuid,
  area_label text not null,
  geometry_json jsonb not null default '{}'::jsonb,
  hail_size_inches numeric(5,2),
  wind_speed_mph numeric(6,2),
  severity_score numeric(6,2) not null default 0,
  confidence_score numeric(6,2) not null default 0,
  provider text,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.neighborhood_opportunity_scores (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  storm_impact_score_id uuid references public.storm_impact_scores(id) on delete set null,
  neighborhood_label text not null,
  geometry_json jsonb not null default '{}'::jsonb,
  opportunity_score numeric(6,2) not null default 0,
  storm_severity_component numeric(6,2) not null default 0,
  existing_customer_component numeric(6,2) not null default 0,
  canvassing_component numeric(6,2) not null default 0,
  close_rate_component numeric(6,2) not null default 0,
  ai_summary text,
  model_version text,
  created_at timestamptz not null default now()
);

create table if not exists public.canvassing_sessions (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  territory_id uuid,
  storm_event_id uuid,
  rep_id uuid not null default auth.uid(),
  session_date date not null default current_date,
  started_at timestamptz,
  ended_at timestamptz,
  status text not null default 'planned',
  start_location jsonb not null default '{}'::jsonb,
  end_location jsonb not null default '{}'::jsonb,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.canvassing_heatmap_rollups (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  territory_id uuid,
  storm_event_id uuid,
  rep_id uuid,
  rollup_date date not null default current_date,
  doors_knocked integer not null default 0,
  contacts_made integer not null default 0,
  appointments_set integer not null default 0,
  inspections_completed integer not null default 0,
  contracts_signed integer not null default 0,
  door_hangers_placed integer not null default 0,
  geometry_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique(company_id, territory_id, storm_event_id, rep_id, rollup_date)
);

create table if not exists public.territory_conflict_warnings (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  rep_id uuid not null default auth.uid(),
  territory_id uuid,
  conflicting_rep_id uuid,
  address text,
  location_json jsonb not null default '{}'::jsonb,
  warning_type text not null default 'outside_assigned_territory',
  status text not null default 'open',
  resolution_note text,
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create table if not exists public.lead_distribution_rules (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null,
  mode text not null default 'recommend_only',
  rule_json jsonb not null default '{}'::jsonb,
  active boolean not null default true,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.lead_distribution_recommendations (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  contact_id uuid,
  job_id uuid,
  recommended_rep_id uuid,
  confidence_score numeric(6,2) not null default 0,
  reasons jsonb not null default '[]'::jsonb,
  status text not null default 'pending_manager_review',
  manager_decision text,
  decided_by uuid,
  decided_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.lead_response_sla_rules (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null default 'Default lead response SLA',
  source text,
  response_minutes integer not null default 15,
  escalation_minutes integer not null default 30,
  active boolean not null default true,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.lead_response_events (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  contact_id uuid,
  job_id uuid,
  assigned_to uuid,
  event_type text not null,
  event_at timestamptz not null default now(),
  minutes_since_created integer,
  status text not null default 'open',
  escalation_level text,
  notes text,
  created_at timestamptz not null default now()
);

create index if not exists storm_provider_connections_company_idx on public.storm_provider_connections(company_id, provider, status);
create index if not exists storm_impact_scores_company_idx on public.storm_impact_scores(company_id, area_label);
create index if not exists neighborhood_opportunity_company_idx on public.neighborhood_opportunity_scores(company_id, neighborhood_label);
create index if not exists canvassing_sessions_company_idx on public.canvassing_sessions(company_id, rep_id, session_date);
create index if not exists canvassing_heatmap_company_idx on public.canvassing_heatmap_rollups(company_id, rollup_date);
create index if not exists territory_conflict_company_idx on public.territory_conflict_warnings(company_id, rep_id, status);
create index if not exists lead_distribution_rules_company_idx on public.lead_distribution_rules(company_id, active);
create index if not exists lead_distribution_recs_company_idx on public.lead_distribution_recommendations(company_id, status);
create index if not exists lead_response_sla_company_idx on public.lead_response_sla_rules(company_id, active);
create index if not exists lead_response_events_company_idx on public.lead_response_events(company_id, event_type, status);

-- RLS enabled live in Supabase with company/manager/job/rep scoped policies.
