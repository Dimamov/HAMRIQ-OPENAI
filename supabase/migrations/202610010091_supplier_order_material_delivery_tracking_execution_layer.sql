-- Supplier order / material delivery tracking execution layer
-- Tracks purchase orders, delivery windows, backorders, supplier confirmations,
-- production impact alerts, and job material readiness.

create table if not exists public.supplier_purchase_orders_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  supplier_name text not null,
  purchase_order_number text,
  order_status text not null default 'draft',
  requested_delivery_date date,
  confirmed_delivery_date date,
  total_amount_cents bigint not null default 0,
  created_by uuid not null default auth.uid(),
  notes text not null default '',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.supplier_purchase_order_items_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  purchase_order_id uuid not null references public.supplier_purchase_orders_deep(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  material_name text not null,
  sku text,
  quantity numeric not null default 0,
  unit text not null default 'each',
  unit_cost_cents bigint not null default 0,
  line_total_cents bigint not null default 0,
  item_status text not null default 'ordered',
  expected_delivery_date date,
  delivered_quantity numeric not null default 0,
  created_by uuid not null default auth.uid(),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.material_delivery_windows_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  purchase_order_id uuid references public.supplier_purchase_orders_deep(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  delivery_status text not null default 'scheduled',
  window_start timestamptz,
  window_end timestamptz,
  delivery_address text,
  driver_contact text,
  supplier_confirmation_code text,
  created_by uuid not null default auth.uid(),
  notes text not null default '',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.material_backorder_records_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  purchase_order_id uuid references public.supplier_purchase_orders_deep(id) on delete cascade,
  purchase_order_item_id uuid references public.supplier_purchase_order_items_deep(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  material_name text not null,
  backorder_status text not null default 'open',
  expected_available_date date,
  affected_quantity numeric not null default 0,
  production_impact_level text not null default 'unknown',
  created_by uuid not null default auth.uid(),
  manager_review_required boolean not null default true,
  notes text not null default '',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.supplier_confirmation_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  purchase_order_id uuid references public.supplier_purchase_orders_deep(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  confirmation_type text not null default 'order',
  confirmation_status text not null default 'received',
  confirmed_by_name text,
  confirmed_at timestamptz,
  confirmation_payload jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.production_delivery_impact_alerts_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  purchase_order_id uuid references public.supplier_purchase_orders_deep(id) on delete cascade,
  alert_type text not null default 'delivery_risk',
  impact_level text not null default 'medium',
  alert_status text not null default 'open',
  production_note text not null default '',
  assigned_to uuid,
  acknowledged_by uuid,
  acknowledged_at timestamptz,
  resolved_at timestamptz,
  created_by uuid not null default auth.uid(),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.job_material_readiness_cards_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  readiness_status text not null default 'not_ready',
  required_items_count integer not null default 0,
  confirmed_items_count integer not null default 0,
  delivered_items_count integer not null default 0,
  missing_items_count integer not null default 0,
  next_delivery_at timestamptz,
  manager_review_required boolean not null default false,
  created_by uuid not null default auth.uid(),
  summary text not null default '',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.material_delivery_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  purchase_order_id uuid references public.supplier_purchase_orders_deep(id) on delete set null,
  event_type text not null,
  event_summary text not null default '',
  event_payload jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

alter table public.supplier_purchase_orders_deep enable row level security;
alter table public.supplier_purchase_order_items_deep enable row level security;
alter table public.material_delivery_windows_deep enable row level security;
alter table public.material_backorder_records_deep enable row level security;
alter table public.supplier_confirmation_events_deep enable row level security;
alter table public.production_delivery_impact_alerts_deep enable row level security;
alter table public.job_material_readiness_cards_deep enable row level security;
alter table public.material_delivery_activity_events_deep enable row level security;

-- Live DB migration also includes indexes, grants, and manager/company RLS policies.