-- Approved HAMRIQ workflow expansion applied 2026-09-30
-- Core approved items: lead sources, door hanger, AI training notice,
-- measurement provider controls, external review gating, production notes,
-- rep routes, review sites, and measurement order approvals.

alter table public.contacts add column if not exists lead_source text not null default 'Unknown';
alter table public.prospecting_visits add column if not exists door_hanger_placed boolean not null default false;
alter table public.companies add column if not exists ai_training_enabled boolean not null default false;
alter table public.companies add column if not exists ai_training_notice text not null default 'HAMRIQ uses company data to improve AI recommendations. This requires AI training, and more data offers better results.';
alter table public.companies add column if not exists additional_measurement_subscription_notice text not null default 'Additional subscription required. Contact HAMRIQ for information.';
alter table public.companies add column if not exists measurement_provider text not null default 'HAMRIQ';
alter table public.companies add column if not exists manager_approve_all_measurements boolean not null default false;
alter table public.jobs add column if not exists status_note text not null default '';
alter table public.production_plans add column if not exists installation_notes text not null default '';
alter table public.reviews add column if not exists external_request_status text not null default 'not_requested';

create table if not exists public.routes (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  name text not null,
  assigned_to uuid not null,
  route_date date not null,
  status text not null default 'planned',
  optimization_mode text not null default 'shortest_time',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  unique (company_id, id),
  foreign key (company_id, assigned_to) references public.users(company_id, id),
  foreign key (company_id, created_by) references public.users(company_id, id)
);

create table if not exists public.route_stops (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  route_id uuid not null,
  job_id uuid,
  prospecting_visit_id uuid references public.prospecting_visits(id),
  stop_order integer not null,
  address text not null,
  latitude double precision,
  longitude double precision,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  unique (company_id, id),
  foreign key (company_id, route_id) references public.routes(company_id, id),
  foreign key (company_id, job_id) references public.jobs(company_id, id)
);

create table if not exists public.review_sites (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  name text not null,
  review_url text not null,
  active boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  unique (company_id, id),
  foreign key (company_id, created_by) references public.users(company_id, id)
);

create table if not exists public.measurement_orders (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid not null,
  provider text not null,
  status text not null default 'pending_approval',
  requested_by uuid not null default auth.uid(),
  approved_by uuid,
  approved_at timestamptz,
  provider_reference text,
  created_at timestamptz not null default now(),
  unique (company_id, id),
  foreign key (company_id, job_id) references public.jobs(company_id, id),
  foreign key (company_id, requested_by) references public.users(company_id, id),
  foreign key (company_id, approved_by) references public.users(company_id, id)
);

create index if not exists routes_assigned_date on public.routes(company_id, assigned_to, route_date);
create index if not exists route_stops_order on public.route_stops(company_id, route_id, stop_order);
create index if not exists review_sites_company on public.review_sites(company_id);
create index if not exists measurement_orders_job on public.measurement_orders(company_id, job_id);

alter table public.routes enable row level security;
alter table public.route_stops enable row level security;
alter table public.review_sites enable row level security;
alter table public.measurement_orders enable row level security;

revoke all on public.routes, public.route_stops, public.review_sites, public.measurement_orders from anon, authenticated;
grant select, insert, update on public.routes, public.route_stops, public.review_sites, public.measurement_orders to authenticated;

create policy routes_read on public.routes for select to authenticated using (private.company_access(company_id) and (private.is_manager(company_id) or assigned_to = (select auth.uid())));
create policy routes_insert on public.routes for insert to authenticated with check (private.company_access(company_id) and (private.is_manager(company_id) or assigned_to = (select auth.uid())) and created_by = (select auth.uid()));
create policy routes_update on public.routes for update to authenticated using (private.company_access(company_id) and (private.is_manager(company_id) or assigned_to = (select auth.uid()))) with check (private.company_access(company_id) and (private.is_manager(company_id) or assigned_to = (select auth.uid())));

create policy route_stops_read on public.route_stops for select to authenticated using (private.company_access(company_id) and exists (select 1 from public.routes r where r.company_id = route_stops.company_id and r.id = route_stops.route_id and (private.is_manager(r.company_id) or r.assigned_to = (select auth.uid()))));
create policy route_stops_insert on public.route_stops for insert to authenticated with check (private.company_access(company_id) and exists (select 1 from public.routes r where r.company_id = route_stops.company_id and r.id = route_stops.route_id and (private.is_manager(r.company_id) or r.assigned_to = (select auth.uid()))));
create policy route_stops_update on public.route_stops for update to authenticated using (private.company_access(company_id) and exists (select 1 from public.routes r where r.company_id = route_stops.company_id and r.id = route_stops.route_id and (private.is_manager(r.company_id) or r.assigned_to = (select auth.uid())))) with check (private.company_access(company_id) and exists (select 1 from public.routes r where r.company_id = route_stops.company_id and r.id = route_stops.route_id and (private.is_manager(r.company_id) or r.assigned_to = (select auth.uid()))));

create policy review_sites_read on public.review_sites for select to authenticated using (private.company_access(company_id));
create policy review_sites_insert on public.review_sites for insert to authenticated with check (private.is_manager(company_id) and created_by = (select auth.uid()));
create policy review_sites_update on public.review_sites for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy measurement_orders_read on public.measurement_orders for select to authenticated using (private.can_job(company_id, job_id));
create policy measurement_orders_insert on public.measurement_orders for insert to authenticated with check (private.can_job(company_id, job_id) and requested_by = (select auth.uid()));
create policy measurement_orders_update on public.measurement_orders for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
