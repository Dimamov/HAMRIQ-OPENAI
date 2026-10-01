-- HAMRIQ production-control layer
-- Adds crew/subcontractor controls, purchase orders, delivery verification,
-- capacity planning, production day stages, delay management, and property protection docs.

create table if not exists public.crew_portal_access (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  vendor_id uuid references public.vendors(id),
  crew_name text not null default '',
  contact_name text not null default '',
  phone text not null default '',
  email text not null default '',
  active boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.subcontractor_work_orders (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid not null references public.jobs(id),
  crew_access_id uuid references public.crew_portal_access(id),
  scope_summary text not null default '',
  labor_amount_cents bigint not null default 0,
  status text not null default 'draft',
  assigned_date date,
  completed_at timestamptz,
  qc_passed_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.subcontractor_payables (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  work_order_id uuid not null references public.subcontractor_work_orders(id),
  amount_cents bigint not null default 0,
  status text not null default 'pending_qc',
  approved_by uuid references public.users(id),
  approved_at timestamptz,
  paid_at timestamptz,
  notes text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.purchase_orders (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid references public.jobs(id),
  vendor_id uuid references public.vendors(id),
  requested_by uuid not null default auth.uid(),
  approved_by uuid references public.users(id),
  status text not null default 'requested',
  item_summary text not null default '',
  expected_amount_cents bigint not null default 0,
  actual_amount_cents bigint,
  approval_required boolean not null default true,
  approved_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.material_delivery_verifications (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid not null references public.jobs(id),
  material_order_id uuid references public.material_orders(id),
  verified_by uuid not null default auth.uid(),
  status text not null default 'pending',
  address_verified boolean not null default false,
  product_verified boolean not null default false,
  quantity_verified boolean not null default false,
  condition_verified boolean not null default false,
  shortage_or_issue text not null default '',
  photo_ids uuid[] not null default '{}',
  verified_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.production_capacity_plans (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  plan_date date not null,
  crew_capacity integer not null default 0,
  scheduled_jobs integer not null default 0,
  estimated_squares numeric not null default 0,
  weather_risk text not null default '',
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.production_day_stages (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid not null references public.jobs(id),
  stage text not null,
  status text not null default 'pending',
  started_at timestamptz,
  completed_at timestamptz,
  updated_by uuid not null default auth.uid(),
  notes text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.production_delays (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid not null references public.jobs(id),
  delay_type text not null,
  severity text not null default 'normal',
  description text not null default '',
  schedule_impact text not null default '',
  customer_update_draft text not null default '',
  status text not null default 'open',
  owner_id uuid references public.users(id),
  resolved_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.property_protection_records (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid not null references public.jobs(id),
  record_type text not null,
  area text not null,
  photo_ids uuid[] not null default '{}',
  condition_notes text not null default '',
  recorded_by uuid not null default auth.uid(),
  recorded_at timestamptz not null default now()
);

alter table public.crew_portal_access enable row level security;
alter table public.subcontractor_work_orders enable row level security;
alter table public.subcontractor_payables enable row level security;
alter table public.purchase_orders enable row level security;
alter table public.material_delivery_verifications enable row level security;
alter table public.production_capacity_plans enable row level security;
alter table public.production_day_stages enable row level security;
alter table public.production_delays enable row level security;
alter table public.property_protection_records enable row level security;

-- Policies are applied live in smaller migrations to avoid deploy-size/safety limits.