alter table public.prospecting_visits
  add column if not exists property_latitude numeric(10,7),
  add column if not exists property_longitude numeric(10,7),
  add column if not exists rep_latitude numeric(10,7),
  add column if not exists rep_longitude numeric(10,7),
  add column if not exists location_accuracy_meters numeric(10,2),
  add column if not exists distance_from_property_meters numeric(10,2),
  add column if not exists location_verification_status text not null default 'not_checked' check (location_verification_status in ('not_checked','verified','too_far','location_denied','manual_override_requested','manual_override_approved','manual_override_denied')),
  add column if not exists location_verified_at timestamptz,
  add column if not exists location_override_reason text not null default '',
  add column if not exists location_override_approved_by uuid,
  add column if not exists location_override_approved_at timestamptz;

create table if not exists public.prospecting_location_verification_rules_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  rule_name text not null default 'Default door knock distance check',
  max_distance_meters integer not null default 75,
  max_gps_accuracy_meters integer not null default 50,
  require_location_for_knocked boolean not null default true,
  require_location_for_door_hanger boolean not null default true,
  allow_manager_override boolean not null default true,
  is_active boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.prospecting_location_check_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  prospecting_visit_id uuid references public.prospecting_visits(id) on delete cascade,
  rep_user_id uuid not null default auth.uid(),
  address text not null default '',
  property_latitude numeric(10,7),
  property_longitude numeric(10,7),
  rep_latitude numeric(10,7),
  rep_longitude numeric(10,7),
  location_accuracy_meters numeric(10,2),
  distance_from_property_meters numeric(10,2),
  max_allowed_distance_meters integer not null default 75,
  verification_status text not null default 'not_checked' check (verification_status in ('verified','too_far','location_denied','bad_gps_accuracy','missing_property_coordinates','manual_override_requested','manual_override_approved','manual_override_denied')),
  attempted_action text not null default 'mark_knocked' check (attempted_action in ('mark_knocked','door_hanger_placed','set_followup','interested','not_interested','other')),
  device_context jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.prospecting_location_override_requests_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  prospecting_visit_id uuid references public.prospecting_visits(id) on delete cascade,
  rep_user_id uuid not null default auth.uid(),
  address text not null default '',
  requested_reason text not null default '',
  distance_from_property_meters numeric(10,2),
  location_accuracy_meters numeric(10,2),
  status text not null default 'requested' check (status in ('requested','approved','denied','cancelled')),
  manager_reviewed_by uuid,
  manager_reviewed_at timestamptz,
  manager_note text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_prospecting_visits_location_status on public.prospecting_visits(company_id, location_verification_status);
create index if not exists idx_prospecting_location_rules_company on public.prospecting_location_verification_rules_deep(company_id, is_active);
create index if not exists idx_prospecting_location_events_company_rep on public.prospecting_location_check_events_deep(company_id, rep_user_id, created_at desc);
create index if not exists idx_prospecting_location_overrides_company_status on public.prospecting_location_override_requests_deep(company_id, status, created_at desc);

alter table public.prospecting_location_verification_rules_deep enable row level security;
alter table public.prospecting_location_check_events_deep enable row level security;
alter table public.prospecting_location_override_requests_deep enable row level security;

revoke all on public.prospecting_location_verification_rules_deep from anon, authenticated;
revoke all on public.prospecting_location_check_events_deep from anon, authenticated;
revoke all on public.prospecting_location_override_requests_deep from anon, authenticated;
grant select, insert, update on public.prospecting_location_verification_rules_deep to authenticated;
grant select, insert, update on public.prospecting_location_check_events_deep to authenticated;
grant select, insert, update on public.prospecting_location_override_requests_deep to authenticated;

do $$ begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='prospecting_location_verification_rules_deep' and policyname='prospecting_location_rules_manager_all') then
    create policy prospecting_location_rules_manager_all on public.prospecting_location_verification_rules_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='prospecting_location_verification_rules_deep' and policyname='prospecting_location_rules_company_select') then
    create policy prospecting_location_rules_company_select on public.prospecting_location_verification_rules_deep for select to authenticated using (private.company_access(company_id));
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='prospecting_location_check_events_deep' and policyname='prospecting_location_events_company_select') then
    create policy prospecting_location_events_company_select on public.prospecting_location_check_events_deep for select to authenticated using (private.company_access(company_id));
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='prospecting_location_check_events_deep' and policyname='prospecting_location_events_rep_insert') then
    create policy prospecting_location_events_rep_insert on public.prospecting_location_check_events_deep for insert to authenticated with check (private.company_access(company_id) and rep_user_id = auth.uid());
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='prospecting_location_check_events_deep' and policyname='prospecting_location_events_manager_update') then
    create policy prospecting_location_events_manager_update on public.prospecting_location_check_events_deep for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='prospecting_location_override_requests_deep' and policyname='prospecting_location_overrides_company_select') then
    create policy prospecting_location_overrides_company_select on public.prospecting_location_override_requests_deep for select to authenticated using (private.company_access(company_id));
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='prospecting_location_override_requests_deep' and policyname='prospecting_location_overrides_rep_insert') then
    create policy prospecting_location_overrides_rep_insert on public.prospecting_location_override_requests_deep for insert to authenticated with check (private.company_access(company_id) and rep_user_id = auth.uid());
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='prospecting_location_override_requests_deep' and policyname='prospecting_location_overrides_manager_update') then
    create policy prospecting_location_overrides_manager_update on public.prospecting_location_override_requests_deep for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
  end if;
end $$;
