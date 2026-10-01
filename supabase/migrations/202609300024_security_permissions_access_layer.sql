-- HAMRIQ security / permissions / access-review layer
-- Role builder, permission assignments, login/security policies, trusted devices,
-- session events, and manager access review records.

create table if not exists public.company_roles (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null,
  description text,
  is_system_role boolean not null default false,
  active boolean not null default true,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, name)
);

create table if not exists public.company_permissions (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  permission_key text not null,
  permission_group text not null default 'general',
  description text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique(company_id, permission_key)
);

create table if not exists public.role_permission_assignments (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  role_id uuid not null references public.company_roles(id) on delete cascade,
  permission_id uuid not null references public.company_permissions(id) on delete cascade,
  allowed boolean not null default true,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  unique(company_id, role_id, permission_id)
);

create table if not exists public.user_role_assignments (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null,
  role_id uuid not null references public.company_roles(id) on delete cascade,
  assigned_by uuid default auth.uid(),
  assigned_at timestamptz not null default now(),
  revoked_at timestamptz,
  notes text,
  unique(company_id, user_id, role_id)
);

create table if not exists public.login_security_policies (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  require_mfa boolean not null default false,
  session_timeout_minutes integer not null default 720,
  allow_password_login boolean not null default true,
  allowed_email_domains text[] not null default '{}'::text[],
  ip_allowlist text[] not null default '{}'::text[],
  manager_alert_on_new_device boolean not null default true,
  active boolean not null default true,
  updated_by uuid default auth.uid(),
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique(company_id)
);

create table if not exists public.trusted_devices (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null,
  device_label text,
  device_fingerprint text not null,
  platform text,
  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  trusted_at timestamptz,
  revoked_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  unique(company_id, user_id, device_fingerprint)
);

create table if not exists public.security_session_events (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid,
  event_type text not null,
  device_id uuid references public.trusted_devices(id) on delete set null,
  ip_address text,
  user_agent text,
  risk_level text not null default 'normal',
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.access_review_records (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  review_name text not null,
  target_user_id uuid,
  reviewer_id uuid default auth.uid(),
  status text not null default 'open',
  findings jsonb not null default '[]'::jsonb,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists company_roles_company_idx on public.company_roles(company_id, active);
create index if not exists company_permissions_company_idx on public.company_permissions(company_id, active, permission_group);
create index if not exists user_role_assignments_user_idx on public.user_role_assignments(company_id, user_id, revoked_at);
create index if not exists trusted_devices_user_idx on public.trusted_devices(company_id, user_id, revoked_at);
create index if not exists security_session_events_company_idx on public.security_session_events(company_id, created_at desc);
create index if not exists access_review_records_company_idx on public.access_review_records(company_id, status);

alter table public.company_roles enable row level security;
alter table public.company_permissions enable row level security;
alter table public.role_permission_assignments enable row level security;
alter table public.user_role_assignments enable row level security;
alter table public.login_security_policies enable row level security;
alter table public.trusted_devices enable row level security;
alter table public.security_session_events enable row level security;
alter table public.access_review_records enable row level security;

grant select, insert, update on public.company_roles to authenticated;
grant select, insert, update on public.company_permissions to authenticated;
grant select, insert, update on public.role_permission_assignments to authenticated;
grant select, insert, update on public.user_role_assignments to authenticated;
grant select, insert, update on public.login_security_policies to authenticated;
grant select, insert, update on public.trusted_devices to authenticated;
grant select, insert, update on public.security_session_events to authenticated;
grant select, insert, update on public.access_review_records to authenticated;

-- Policies use the existing HAMRIQ permission helpers: private.is_manager and private.company_access.
