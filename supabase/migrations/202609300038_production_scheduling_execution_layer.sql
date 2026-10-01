-- HAMRIQ production scheduling execution layer
-- Adds crews, production schedule execution, delivery/dumpster scheduling, weather holds, manager move approvals, and install-day homeowner updates.

create table if not exists public.crews (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  crew_name text not null,
  crew_type text not null default 'roofing',
  foreman_user_id uuid,
  phone text,
  is_subcontractor boolean not null default false,
  active boolean not null default true,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, id)
);

create table if not exists public.crew_members (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  crew_id uuid not null,
  member_user_id uuid,
  display_name text not null,
  role text not null default 'installer',
  phone text,
  active boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, id),
  foreign key (company_id, crew_id) references public.crews(company_id, id) on delete cascade
);

create table if not exists public.production_schedule_items_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  crew_id uuid,
  schedule_type text not null default 'install',
  status text not null default 'planned',
  start_at timestamptz not null,
  end_at timestamptz,
  address_snapshot text not null default '',
  weather_risk_level text not null default 'unknown',
  manager_approval_required boolean not null default false,
  approved_by uuid,
  approved_at timestamptz,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, id),
  foreign key (company_id, crew_id) references public.crews(company_id, id) on delete set null,
  foreign key (company_id, job_id) references public.jobs(company_id, id) on delete cascade
);

create table if not exists public.production_move_approval_requests (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  schedule_item_id uuid not null,
  job_id uuid not null,
  requested_start_at timestamptz not null,
  requested_end_at timestamptz,
  reason text not null,
  weather_related boolean not null default false,
  status text not null default 'pending',
  reviewed_by uuid,
  reviewed_at timestamptz,
  review_notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, id),
  foreign key (company_id, schedule_item_id) references public.production_schedule_items_deep(company_id, id) on delete cascade,
  foreign key (company_id, job_id) references public.jobs(company_id, id) on delete cascade
);

create table if not exists public.material_delivery_schedules (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  supplier_name text not null default '',
  delivery_type text not null default 'materials',
  scheduled_at timestamptz not null,
  confirmed_at timestamptz,
  delivered_at timestamptz,
  status text not null default 'scheduled',
  contact_name text not null default '',
  contact_phone text not null default '',
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, id),
  foreign key (company_id, job_id) references public.jobs(company_id, id) on delete cascade
);

create table if not exists public.dumpster_schedule_events (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  vendor_name text not null default '',
  event_type text not null default 'dropoff',
  scheduled_at timestamptz not null,
  completed_at timestamptz,
  status text not null default 'scheduled',
  placement_notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, id),
  foreign key (company_id, job_id) references public.jobs(company_id, id) on delete cascade
);

create table if not exists public.weather_schedule_risk_events (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  schedule_item_id uuid,
  risk_level text not null,
  risk_type text not null default 'forecast',
  forecast_summary text not null default '',
  recommended_action text not null default 'review',
  manager_review_required boolean not null default true,
  resolved boolean not null default false,
  resolved_by uuid,
  resolved_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  unique(company_id, id),
  foreign key (company_id, job_id) references public.jobs(company_id, id) on delete cascade,
  foreign key (company_id, schedule_item_id) references public.production_schedule_items_deep(company_id, id) on delete set null
);

create table if not exists public.install_day_homeowner_updates (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  schedule_item_id uuid,
  update_type text not null default 'status',
  message_body text not null,
  delivery_channel text not null default 'sms',
  delivery_status text not null default 'draft',
  sent_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  unique(company_id, id),
  foreign key (company_id, job_id) references public.jobs(company_id, id) on delete cascade,
  foreign key (company_id, schedule_item_id) references public.production_schedule_items_deep(company_id, id) on delete set null
);

alter table public.crews enable row level security;
alter table public.crew_members enable row level security;
alter table public.production_schedule_items_deep enable row level security;
alter table public.production_move_approval_requests enable row level security;
alter table public.material_delivery_schedules enable row level security;
alter table public.dumpster_schedule_events enable row level security;
alter table public.weather_schedule_risk_events enable row level security;
alter table public.install_day_homeowner_updates enable row level security;

-- Live project policies use private.company_access, private.can_job, and private.is_manager helpers.
