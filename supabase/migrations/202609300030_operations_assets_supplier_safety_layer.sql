-- HAMRIQ operations assets / supplier / safety layer
-- Adds inventory transactions, equipment checkouts, fleet service logs,
-- toolbox talks, safety corrective actions, vendor scorecards, and supplier performance events.

create table if not exists public.inventory_transactions (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  inventory_item_id uuid references public.inventory_items(id) on delete set null,
  job_id uuid,
  transaction_type text not null default 'adjustment',
  quantity numeric(12,2) not null default 0,
  unit_cost numeric(12,2),
  reason text,
  performed_by uuid default auth.uid(),
  transaction_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.equipment_checkouts (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  equipment_asset_id uuid references public.equipment_assets(id) on delete set null,
  assigned_to uuid not null default auth.uid(),
  job_id uuid,
  checkout_at timestamptz not null default now(),
  expected_return_at timestamptz,
  returned_at timestamptz,
  condition_out text,
  condition_in text,
  status text not null default 'checked_out',
  notes text,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.fleet_service_logs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  fleet_vehicle_id uuid references public.fleet_vehicles(id) on delete set null,
  service_type text not null default 'maintenance',
  odometer integer,
  service_date date not null default current_date,
  vendor_id uuid references public.vendors(id) on delete set null,
  cost numeric(12,2) not null default 0,
  next_service_due_date date,
  next_service_due_odometer integer,
  notes text,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.toolbox_talks (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  title text not null,
  topic text not null default 'general_safety',
  content text not null default '',
  required boolean not null default true,
  active boolean not null default true,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.toolbox_talk_acknowledgments (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  toolbox_talk_id uuid not null references public.toolbox_talks(id) on delete cascade,
  user_id uuid not null default auth.uid(),
  acknowledged_at timestamptz not null default now(),
  signature_text text,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.safety_corrective_actions (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  safety_incident_id uuid references public.safety_incidents(id) on delete cascade,
  job_id uuid,
  action_required text not null,
  assigned_to uuid,
  due_date date,
  status text not null default 'open',
  completed_at timestamptz,
  completion_notes text,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.vendor_scorecards (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  vendor_id uuid references public.vendors(id) on delete cascade,
  score_period daterange,
  on_time_score numeric(5,2),
  quality_score numeric(5,2),
  communication_score numeric(5,2),
  price_score numeric(5,2),
  overall_notes text,
  manager_decision text not null default 'monitor',
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.supplier_performance_events (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  vendor_id uuid references public.vendors(id) on delete set null,
  purchase_order_id uuid references public.purchase_orders(id) on delete set null,
  job_id uuid,
  event_type text not null default 'delivery_update',
  severity text not null default 'info',
  event_summary text not null,
  impact_notes text,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);

alter table public.inventory_transactions enable row level security;
alter table public.equipment_checkouts enable row level security;
alter table public.fleet_service_logs enable row level security;
alter table public.toolbox_talks enable row level security;
alter table public.toolbox_talk_acknowledgments enable row level security;
alter table public.safety_corrective_actions enable row level security;
alter table public.vendor_scorecards enable row level security;
alter table public.supplier_performance_events enable row level security;

-- Live project includes indexes, grants, and RLS policies for manager/company/user scoped access.