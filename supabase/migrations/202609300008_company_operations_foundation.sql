create table if not exists public.knowledge_base_articles (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  title text not null,
  category text not null default 'General',
  body text not null default '',
  source_url text not null default '',
  visibility text not null default 'company' check (visibility in ('company','managers','role_specific')),
  role_scope text not null default '',
  active boolean not null default true,
  created_by uuid not null default auth.uid(),
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,created_by) references public.users(company_id,id)
);

create table if not exists public.training_modules (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  title text not null,
  description text not null default '',
  role_scope text not null default 'all',
  required boolean not null default false,
  active boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,created_by) references public.users(company_id,id)
);

create table if not exists public.training_assignments (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  module_id uuid not null,
  assigned_to uuid not null,
  status text not null default 'assigned' check (status in ('assigned','in_progress','completed','acknowledged')),
  score numeric,
  completed_at timestamptz,
  acknowledged_at timestamptz,
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,module_id) references public.training_modules(company_id,id),
  foreign key(company_id,assigned_to) references public.users(company_id,id)
);

create table if not exists public.company_documents (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  title text not null,
  document_type text not null default 'general',
  storage_path text not null default '',
  related_entity_type text not null default '',
  related_entity_id uuid,
  expires_on date,
  visibility text not null default 'company' check (visibility in ('company','managers','employee_own')),
  uploaded_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,uploaded_by) references public.users(company_id,id)
);

create table if not exists public.vendors (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  name text not null,
  vendor_type text not null default 'supplier' check (vendor_type in ('supplier','subcontractor','dumpster','equipment','permit_service','other')),
  phone text not null default '',
  email text not null default '',
  address text not null default '',
  account_number text not null default '',
  payment_terms text not null default '',
  active boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,created_by) references public.users(company_id,id)
);

create table if not exists public.inventory_items (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  sku text not null default '',
  name text not null,
  category text not null default 'material',
  unit text not null default 'each',
  quantity_on_hand numeric not null default 0,
  reorder_point numeric not null default 0,
  preferred_vendor_id uuid,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,preferred_vendor_id) references public.vendors(company_id,id)
);

create table if not exists public.equipment_assets (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  name text not null,
  asset_type text not null default 'tool' check (asset_type in ('tool','ladder','trailer','magnet','generator','vehicle_equipment','tablet','other')),
  serial_number text not null default '',
  assigned_to uuid,
  status text not null default 'available' check (status in ('available','assigned','in_use','maintenance','lost_damaged','retired')),
  current_location text not null default '',
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,assigned_to) references public.users(company_id,id)
);

create table if not exists public.fleet_vehicles (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  name text not null,
  vin text not null default '',
  license_plate text not null default '',
  assigned_driver uuid,
  mileage integer not null default 0,
  insurance_expires_on date,
  registration_expires_on date,
  status text not null default 'active' check (status in ('active','maintenance','inactive','sold')),
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,assigned_driver) references public.users(company_id,id)
);

create table if not exists public.safety_incidents (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid,
  incident_type text not null default 'safety_concern',
  severity text not null default 'low' check (severity in ('low','medium','high','critical')),
  description text not null default '',
  photos jsonb not null default '[]'::jsonb,
  reported_by uuid not null default auth.uid(),
  status text not null default 'open' check (status in ('open','reviewing','resolved','closed')),
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,job_id) references public.jobs(company_id,id),
  foreign key(company_id,reported_by) references public.users(company_id,id)
);

create table if not exists public.expense_reimbursements (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  user_id uuid not null default auth.uid(),
  job_id uuid,
  category text not null default 'misc',
  amount_cents bigint not null default 0 check (amount_cents >= 0),
  reason text not null default '',
  receipt_path text not null default '',
  status text not null default 'submitted' check (status in ('draft','submitted','approved','rejected','ready_for_payment','paid')),
  approved_by uuid,
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,user_id) references public.users(company_id,id),
  foreign key(company_id,job_id) references public.jobs(company_id,id),
  foreign key(company_id,approved_by) references public.users(company_id,id)
);

create table if not exists public.mileage_entries (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  user_id uuid not null default auth.uid(),
  job_id uuid,
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  start_odometer integer,
  end_odometer integer,
  miles numeric not null default 0,
  status text not null default 'submitted' check (status in ('draft','submitted','approved','rejected','paid')),
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,user_id) references public.users(company_id,id),
  foreign key(company_id,job_id) references public.jobs(company_id,id)
);

create table if not exists public.time_entries (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  user_id uuid not null default auth.uid(),
  job_id uuid,
  clock_in_at timestamptz not null default now(),
  clock_out_at timestamptz,
  break_minutes integer not null default 0,
  status text not null default 'open' check (status in ('open','submitted','approved','rejected')),
  geofence_confirmed boolean not null default false,
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,user_id) references public.users(company_id,id),
  foreign key(company_id,job_id) references public.jobs(company_id,id)
);

create table if not exists public.backup_recovery_events (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  event_type text not null check (event_type in ('backup_completed','backup_failed','restore_requested','restore_previewed','restore_completed','restore_failed')),
  entity_type text not null default '',
  entity_id uuid,
  status text not null default 'recorded',
  details jsonb not null default '{}'::jsonb,
  requested_by uuid,
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,requested_by) references public.users(company_id,id)
);
