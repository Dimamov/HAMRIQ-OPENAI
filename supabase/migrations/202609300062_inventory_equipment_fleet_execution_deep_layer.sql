create table if not exists public.inventory_count_sessions_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  warehouse_name text not null default 'Main',
  count_status text not null default 'draft' check (count_status in ('draft','in_progress','variance_review','approved','void')),
  started_by uuid not null default auth.uid(),
  approved_by uuid,
  started_at timestamptz not null default now(),
  approved_at timestamptz,
  variance_summary jsonb not null default '{}'::jsonb,
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.inventory_count_lines_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  count_session_id uuid not null references public.inventory_count_sessions_deep(id) on delete cascade,
  item_name text not null,
  item_sku text not null default '',
  expected_quantity numeric(12,2) not null default 0,
  counted_quantity numeric(12,2) not null default 0,
  variance_quantity numeric(12,2) not null default 0,
  variance_reason text not null default '',
  requires_manager_review boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.material_reservations_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  item_name text not null,
  item_sku text not null default '',
  reserved_quantity numeric(12,2) not null default 0,
  reservation_status text not null default 'reserved' check (reservation_status in ('reserved','picked','delivered','released','cancelled')),
  needed_on date,
  reserved_by uuid not null default auth.uid(),
  manager_approved_by uuid,
  manager_approved_at timestamptz,
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.tool_checkout_sessions_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  tool_name text not null,
  tool_identifier text not null default '',
  checked_out_to uuid not null,
  checkout_status text not null default 'checked_out' check (checkout_status in ('checked_out','returned','missing','damaged','written_off')),
  checked_out_by uuid not null default auth.uid(),
  checked_out_at timestamptz not null default now(),
  returned_at timestamptz,
  condition_out text not null default '',
  condition_in text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.fleet_vehicle_inspections_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  vehicle_name text not null,
  vehicle_identifier text not null default '',
  inspection_status text not null default 'passed' check (inspection_status in ('passed','needs_attention','out_of_service','review_needed')),
  odometer_reading integer,
  inspection_checklist jsonb not null default '{}'::jsonb,
  defects_found jsonb not null default '[]'::jsonb,
  inspected_by uuid not null default auth.uid(),
  inspected_at timestamptz not null default now(),
  manager_review_required boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.fleet_service_logs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  vehicle_name text not null,
  vehicle_identifier text not null default '',
  service_type text not null default 'maintenance',
  service_status text not null default 'scheduled' check (service_status in ('scheduled','in_progress','completed','cancelled','review_needed')),
  service_vendor text not null default '',
  cost_cents bigint not null default 0,
  odometer_reading integer,
  service_date date,
  next_service_due date,
  approved_by uuid,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.jobsite_delivery_confirmations_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  delivery_status text not null default 'scheduled' check (delivery_status in ('scheduled','in_transit','delivered','partial','rejected','missing_items')),
  supplier_name text not null default '',
  delivered_items jsonb not null default '[]'::jsonb,
  photo_asset_ids jsonb not null default '[]'::jsonb,
  confirmed_by uuid,
  confirmed_at timestamptz,
  manager_review_required boolean not null default false,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.asset_damage_loss_reports_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  asset_type text not null check (asset_type in ('tool','vehicle','equipment','material','other')),
  asset_name text not null,
  report_status text not null default 'reported' check (report_status in ('reported','reviewing','resolved','charged_back','written_off')),
  damage_or_loss_type text not null default 'unknown',
  estimated_cost_cents bigint not null default 0,
  responsible_user_id uuid,
  manager_review_required boolean not null default true,
  resolution_notes text not null default '',
  reported_by uuid not null default auth.uid(),
  reported_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_inventory_count_sessions_deep_company on public.inventory_count_sessions_deep(company_id, count_status);
create index if not exists idx_inventory_count_lines_deep_company_session on public.inventory_count_lines_deep(company_id, count_session_id);
create index if not exists idx_material_reservations_deep_company_job on public.material_reservations_deep(company_id, job_id, reservation_status);
create index if not exists idx_tool_checkout_sessions_deep_company_job on public.tool_checkout_sessions_deep(company_id, job_id, checkout_status);
create index if not exists idx_fleet_vehicle_inspections_deep_company on public.fleet_vehicle_inspections_deep(company_id, inspection_status);
create index if not exists idx_fleet_service_logs_deep_company on public.fleet_service_logs_deep(company_id, service_status);
create index if not exists idx_jobsite_delivery_confirmations_deep_company_job on public.jobsite_delivery_confirmations_deep(company_id, job_id, delivery_status);
create index if not exists idx_asset_damage_loss_reports_deep_company_job on public.asset_damage_loss_reports_deep(company_id, job_id, report_status);

alter table public.inventory_count_sessions_deep enable row level security;
alter table public.inventory_count_lines_deep enable row level security;
alter table public.material_reservations_deep enable row level security;
alter table public.tool_checkout_sessions_deep enable row level security;
alter table public.fleet_vehicle_inspections_deep enable row level security;
alter table public.fleet_service_logs_deep enable row level security;
alter table public.jobsite_delivery_confirmations_deep enable row level security;
alter table public.asset_damage_loss_reports_deep enable row level security;

revoke all on public.inventory_count_sessions_deep from anon, authenticated;
revoke all on public.inventory_count_lines_deep from anon, authenticated;
revoke all on public.material_reservations_deep from anon, authenticated;
revoke all on public.tool_checkout_sessions_deep from anon, authenticated;
revoke all on public.fleet_vehicle_inspections_deep from anon, authenticated;
revoke all on public.fleet_service_logs_deep from anon, authenticated;
revoke all on public.jobsite_delivery_confirmations_deep from anon, authenticated;
revoke all on public.asset_damage_loss_reports_deep from anon, authenticated;

grant select, insert, update on public.inventory_count_sessions_deep to authenticated;
grant select, insert, update on public.inventory_count_lines_deep to authenticated;
grant select, insert, update on public.material_reservations_deep to authenticated;
grant select, insert, update on public.tool_checkout_sessions_deep to authenticated;
grant select, insert, update on public.fleet_vehicle_inspections_deep to authenticated;
grant select, insert, update on public.fleet_service_logs_deep to authenticated;
grant select, insert, update on public.jobsite_delivery_confirmations_deep to authenticated;
grant select, insert, update on public.asset_damage_loss_reports_deep to authenticated;

create policy inventory_count_sessions_deep_select on public.inventory_count_sessions_deep for select using (private.company_access(company_id));
create policy inventory_count_sessions_deep_insert on public.inventory_count_sessions_deep for insert with check (private.is_manager(company_id));
create policy inventory_count_sessions_deep_update on public.inventory_count_sessions_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy inventory_count_lines_deep_select on public.inventory_count_lines_deep for select using (private.company_access(company_id));
create policy inventory_count_lines_deep_insert on public.inventory_count_lines_deep for insert with check (private.is_manager(company_id));
create policy inventory_count_lines_deep_update on public.inventory_count_lines_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy material_reservations_deep_select on public.material_reservations_deep for select using (private.company_access(company_id));
create policy material_reservations_deep_insert on public.material_reservations_deep for insert with check (private.company_access(company_id));
create policy material_reservations_deep_update on public.material_reservations_deep for update using (private.company_access(company_id)) with check (private.company_access(company_id));

create policy tool_checkout_sessions_deep_select on public.tool_checkout_sessions_deep for select using (private.company_access(company_id));
create policy tool_checkout_sessions_deep_insert on public.tool_checkout_sessions_deep for insert with check (private.company_access(company_id));
create policy tool_checkout_sessions_deep_update on public.tool_checkout_sessions_deep for update using (private.company_access(company_id)) with check (private.company_access(company_id));

create policy fleet_vehicle_inspections_deep_select on public.fleet_vehicle_inspections_deep for select using (private.company_access(company_id));
create policy fleet_vehicle_inspections_deep_insert on public.fleet_vehicle_inspections_deep for insert with check (private.company_access(company_id));
create policy fleet_vehicle_inspections_deep_update on public.fleet_vehicle_inspections_deep for update using (private.company_access(company_id)) with check (private.company_access(company_id));

create policy fleet_service_logs_deep_select on public.fleet_service_logs_deep for select using (private.company_access(company_id));
create policy fleet_service_logs_deep_insert on public.fleet_service_logs_deep for insert with check (private.is_manager(company_id));
create policy fleet_service_logs_deep_update on public.fleet_service_logs_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy jobsite_delivery_confirmations_deep_select on public.jobsite_delivery_confirmations_deep for select using (private.company_access(company_id));
create policy jobsite_delivery_confirmations_deep_insert on public.jobsite_delivery_confirmations_deep for insert with check (private.company_access(company_id));
create policy jobsite_delivery_confirmations_deep_update on public.jobsite_delivery_confirmations_deep for update using (private.company_access(company_id)) with check (private.company_access(company_id));

create policy asset_damage_loss_reports_deep_select on public.asset_damage_loss_reports_deep for select using (private.company_access(company_id));
create policy asset_damage_loss_reports_deep_insert on public.asset_damage_loss_reports_deep for insert with check (private.company_access(company_id));
create policy asset_damage_loss_reports_deep_update on public.asset_damage_loss_reports_deep for update using (private.company_access(company_id)) with check (private.company_access(company_id));