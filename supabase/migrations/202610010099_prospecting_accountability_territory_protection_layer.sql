-- Prospecting accountability / territory protection layer
-- Adds duplicate knock prevention, territory assignment, no-soliciting flags,
-- conflict alerts, and manager audit visibility.

create table if not exists public.prospecting_territory_zones_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  territory_name text not null,
  territory_type text not null default 'custom' check (territory_type in ('custom','storm_area','neighborhood','zip_code','city','rep_route')),
  assigned_rep_user_id uuid,
  manager_owner_user_id uuid,
  status text not null default 'active' check (status in ('active','paused','archived')),
  boundary_geojson jsonb not null default '{}'::jsonb,
  zip_codes text[] not null default '{}',
  city_names text[] not null default '{}',
  notes text not null default '',
  starts_at timestamptz,
  ends_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.prospecting_address_registry_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  normalized_address text not null,
  display_address text not null,
  property_latitude numeric(10,7),
  property_longitude numeric(10,7),
  territory_zone_id uuid references public.prospecting_territory_zones_deep(id) on delete set null,
  current_owner_user_id uuid,
  do_not_knock boolean not null default false,
  no_soliciting boolean not null default false,
  no_soliciting_source text not null default '',
  last_knocked_at timestamptz,
  last_knocked_by uuid,
  last_outcome text not null default '',
  next_allowed_knock_at timestamptz,
  duplicate_window_days integer not null default 30,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, normalized_address)
);

create table if not exists public.prospecting_duplicate_knock_checks_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  prospecting_visit_id uuid references public.prospecting_visits(id) on delete cascade,
  address_registry_id uuid references public.prospecting_address_registry_deep(id) on delete set null,
  rep_user_id uuid not null default auth.uid(),
  normalized_address text not null default '',
  requested_outcome text not null default '',
  check_status text not null default 'pending' check (check_status in ('pending','allowed','warning','blocked','override_requested','override_approved','override_denied')),
  duplicate_detected boolean not null default false,
  previous_knock_at timestamptz,
  previous_knock_by uuid,
  days_since_previous_knock integer,
  next_allowed_knock_at timestamptz,
  block_reason text not null default '',
  manager_override_required boolean not null default false,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.prospecting_no_soliciting_flags_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  address_registry_id uuid references public.prospecting_address_registry_deep(id) on delete cascade,
  display_address text not null,
  flag_type text not null default 'no_soliciting' check (flag_type in ('no_soliciting','do_not_knock','customer_requested','hoa_restricted','municipal_restricted','manager_blocked')),
  flag_status text not null default 'active' check (flag_status in ('active','inactive','review_needed')),
  source text not null default '',
  source_photo_url text not null default '',
  rep_notes text not null default '',
  manager_notes text not null default '',
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.prospecting_territory_conflict_alerts_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  territory_zone_id uuid references public.prospecting_territory_zones_deep(id) on delete set null,
  prospecting_visit_id uuid references public.prospecting_visits(id) on delete cascade,
  address_registry_id uuid references public.prospecting_address_registry_deep(id) on delete set null,
  rep_user_id uuid not null default auth.uid(),
  assigned_owner_user_id uuid,
  alert_type text not null default 'outside_assigned_territory' check (alert_type in ('outside_assigned_territory','rep_overlap','duplicate_knock','no_soliciting','do_not_knock','stale_route','manager_review')),
  alert_status text not null default 'open' check (alert_status in ('open','acknowledged','resolved','dismissed')),
  severity text not null default 'medium' check (severity in ('low','medium','high','critical')),
  message text not null default '',
  resolved_by uuid,
  resolved_at timestamptz,
  resolution_note text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.prospecting_activity_audit_cards_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  rep_user_id uuid,
  audit_period_start date not null default current_date,
  audit_period_end date not null default current_date,
  total_knocks integer not null default 0,
  gps_verified_knocks integer not null default 0,
  duplicate_warnings integer not null default 0,
  blocked_attempts integer not null default 0,
  override_requests integer not null default 0,
  no_soliciting_flags integer not null default 0,
  suspicious_pattern_score numeric(5,2) not null default 0,
  audit_status text not null default 'normal' check (audit_status in ('normal','watch','review_needed','manager_escalated')),
  manager_notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.prospecting_accountability_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  prospecting_visit_id uuid references public.prospecting_visits(id) on delete set null,
  address_registry_id uuid references public.prospecting_address_registry_deep(id) on delete set null,
  actor_user_id uuid not null default auth.uid(),
  event_type text not null,
  event_summary text not null default '',
  event_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.prospecting_visits add column if not exists address_registry_id uuid references public.prospecting_address_registry_deep(id) on delete set null;
alter table public.prospecting_visits add column if not exists duplicate_knock_status text not null default 'not_checked';
alter table public.prospecting_visits add column if not exists territory_zone_id uuid references public.prospecting_territory_zones_deep(id) on delete set null;
alter table public.prospecting_visits add column if not exists territory_check_status text not null default 'not_checked';
alter table public.prospecting_visits add column if not exists no_soliciting_status text not null default 'not_checked';

create index if not exists prospecting_territory_zones_company_status_idx on public.prospecting_territory_zones_deep(company_id,status);
create index if not exists prospecting_address_registry_company_address_idx on public.prospecting_address_registry_deep(company_id,normalized_address);
create index if not exists prospecting_duplicate_checks_company_rep_idx on public.prospecting_duplicate_knock_checks_deep(company_id,rep_user_id,created_at desc);
create index if not exists prospecting_no_soliciting_company_status_idx on public.prospecting_no_soliciting_flags_deep(company_id,flag_status);
create index if not exists prospecting_conflicts_company_status_idx on public.prospecting_territory_conflict_alerts_deep(company_id,alert_status,severity);
create index if not exists prospecting_audit_cards_company_rep_idx on public.prospecting_activity_audit_cards_deep(company_id,rep_user_id,audit_period_start);
create index if not exists prospecting_accountability_events_company_idx on public.prospecting_accountability_activity_events_deep(company_id,created_at desc);

alter table public.prospecting_territory_zones_deep enable row level security;
alter table public.prospecting_address_registry_deep enable row level security;
alter table public.prospecting_duplicate_knock_checks_deep enable row level security;
alter table public.prospecting_no_soliciting_flags_deep enable row level security;
alter table public.prospecting_territory_conflict_alerts_deep enable row level security;
alter table public.prospecting_activity_audit_cards_deep enable row level security;
alter table public.prospecting_accountability_activity_events_deep enable row level security;

revoke all on public.prospecting_territory_zones_deep from anon, authenticated;
revoke all on public.prospecting_address_registry_deep from anon, authenticated;
revoke all on public.prospecting_duplicate_knock_checks_deep from anon, authenticated;
revoke all on public.prospecting_no_soliciting_flags_deep from anon, authenticated;
revoke all on public.prospecting_territory_conflict_alerts_deep from anon, authenticated;
revoke all on public.prospecting_activity_audit_cards_deep from anon, authenticated;
revoke all on public.prospecting_accountability_activity_events_deep from anon, authenticated;

grant select, insert, update on public.prospecting_territory_zones_deep to authenticated;
grant select, insert, update on public.prospecting_address_registry_deep to authenticated;
grant select, insert, update on public.prospecting_duplicate_knock_checks_deep to authenticated;
grant select, insert, update on public.prospecting_no_soliciting_flags_deep to authenticated;
grant select, insert, update on public.prospecting_territory_conflict_alerts_deep to authenticated;
grant select, insert, update on public.prospecting_activity_audit_cards_deep to authenticated;
grant select, insert, update on public.prospecting_accountability_activity_events_deep to authenticated;

create policy prospecting_territory_zones_manager_all on public.prospecting_territory_zones_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy prospecting_territory_zones_company_read on public.prospecting_territory_zones_deep for select to authenticated using (private.company_access(company_id));
create policy prospecting_address_registry_manager_all on public.prospecting_address_registry_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy prospecting_address_registry_company_read on public.prospecting_address_registry_deep for select to authenticated using (private.company_access(company_id));
create policy prospecting_address_registry_rep_insert on public.prospecting_address_registry_deep for insert to authenticated with check (private.company_access(company_id) and created_by = auth.uid());
create policy prospecting_duplicate_checks_manager_all on public.prospecting_duplicate_knock_checks_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy prospecting_duplicate_checks_rep_own on public.prospecting_duplicate_knock_checks_deep for all to authenticated using (private.company_access(company_id) and rep_user_id = auth.uid()) with check (private.company_access(company_id) and rep_user_id = auth.uid());
create policy prospecting_no_soliciting_manager_all on public.prospecting_no_soliciting_flags_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy prospecting_no_soliciting_company_read on public.prospecting_no_soliciting_flags_deep for select to authenticated using (private.company_access(company_id));
create policy prospecting_no_soliciting_rep_insert on public.prospecting_no_soliciting_flags_deep for insert to authenticated with check (private.company_access(company_id) and created_by = auth.uid());
create policy prospecting_conflict_alerts_manager_all on public.prospecting_territory_conflict_alerts_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy prospecting_conflict_alerts_rep_own_read on public.prospecting_territory_conflict_alerts_deep for select to authenticated using (private.company_access(company_id) and (rep_user_id = auth.uid() or private.is_manager(company_id)));
create policy prospecting_conflict_alerts_rep_insert on public.prospecting_territory_conflict_alerts_deep for insert to authenticated with check (private.company_access(company_id) and rep_user_id = auth.uid());
create policy prospecting_audit_cards_manager_all on public.prospecting_activity_audit_cards_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy prospecting_audit_cards_rep_own_read on public.prospecting_activity_audit_cards_deep for select to authenticated using (private.company_access(company_id) and (rep_user_id = auth.uid() or private.is_manager(company_id)));
create policy prospecting_accountability_events_manager_all on public.prospecting_accountability_activity_events_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy prospecting_accountability_events_rep_insert on public.prospecting_accountability_activity_events_deep for insert to authenticated with check (private.company_access(company_id) and actor_user_id = auth.uid());
create policy prospecting_accountability_events_company_read on public.prospecting_accountability_activity_events_deep for select to authenticated using (private.company_access(company_id));
