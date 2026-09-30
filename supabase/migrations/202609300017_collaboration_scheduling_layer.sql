-- HAMRIQ collaboration and scheduling layer
-- Adds company calendar, time off, availability, team chat, announcements,
-- stop-work alerts, push device registrations, and in-app help walkthroughs.

create table if not exists public.calendar_events (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid,
  contact_id uuid,
  owner_id uuid not null default auth.uid(),
  title text not null check (length(trim(title)) > 0),
  event_type text not null default 'other',
  starts_at timestamptz not null,
  ends_at timestamptz,
  location text not null default '',
  notes text not null default '',
  status text not null default 'scheduled',
  external_calendar_id text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  unique(company_id,id)
);

create table if not exists public.time_off_requests (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  user_id uuid not null default auth.uid(),
  starts_on date not null,
  ends_on date not null,
  reason text not null default '',
  status text not null default 'pending',
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  unique(company_id,id)
);

create table if not exists public.availability_rules (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  user_id uuid not null,
  weekday integer not null,
  start_time time not null,
  end_time time not null,
  active boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  unique(company_id,id)
);

create table if not exists public.team_chat_threads (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid,
  thread_type text not null default 'job',
  title text not null,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  unique(company_id,id)
);

create table if not exists public.team_chat_messages (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  thread_id uuid not null,
  author_id uuid not null default auth.uid(),
  body text not null,
  hammy_summary boolean not null default false,
  created_at timestamptz not null default now(),
  unique(company_id,id)
);

create table if not exists public.company_announcements (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  title text not null,
  body text not null,
  target_role text not null default 'all',
  requires_ack boolean not null default false,
  active boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  unique(company_id,id)
);

create table if not exists public.announcement_acknowledgments (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  announcement_id uuid not null,
  user_id uuid not null default auth.uid(),
  acknowledged_at timestamptz not null default now(),
  unique(company_id,announcement_id,user_id)
);

create table if not exists public.stop_work_alerts (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid,
  scope text not null default 'job',
  severity text not null default 'urgent',
  message text not null,
  status text not null default 'active',
  issued_by uuid not null default auth.uid(),
  cleared_by uuid,
  cleared_at timestamptz,
  created_at timestamptz not null default now(),
  unique(company_id,id)
);

create table if not exists public.stop_work_acknowledgments (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  alert_id uuid not null,
  user_id uuid not null default auth.uid(),
  acknowledged_at timestamptz not null default now(),
  unique(company_id,alert_id,user_id)
);

create table if not exists public.push_device_registrations (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  user_id uuid not null default auth.uid(),
  platform text not null,
  token_hash text not null,
  active boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique(company_id,user_id,token_hash)
);

create table if not exists public.help_walkthroughs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  page_key text not null,
  title text not null,
  steps jsonb not null default '[]',
  active boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  unique(company_id,page_key)
);

-- Live project migration includes foreign keys, RLS grants, and policies.
-- This source file intentionally captures the reproducible schema layer without
-- provider secrets or push tokens. The live database has all listed tables RLS-enabled.