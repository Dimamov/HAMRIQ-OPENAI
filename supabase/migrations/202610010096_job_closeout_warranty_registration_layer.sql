-- HAMRIQ job closeout / warranty registration layer
-- Adds closeout packets, warranty registration, final docs, lien waivers,
-- homeowner closeout delivery, manager approvals, follow-up tasks, and audit events.

create table if not exists public.job_closeout_packets_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  packet_status text not null default 'draft',
  closeout_summary text not null default '',
  required_items jsonb not null default '[]'::jsonb,
  completed_items jsonb not null default '[]'::jsonb,
  missing_items jsonb not null default '[]'::jsonb,
  delivered_to_homeowner boolean not null default false,
  delivered_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.warranty_registration_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  closeout_packet_id uuid references public.job_closeout_packets_deep(id) on delete set null,
  manufacturer text not null default '',
  warranty_type text not null default 'manufacturer',
  registration_status text not null default 'not_started',
  registration_number text not null default '',
  submitted_at timestamptz,
  confirmed_at timestamptz,
  rejection_reason text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.final_job_document_records_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  closeout_packet_id uuid references public.job_closeout_packets_deep(id) on delete set null,
  document_type text not null default 'other',
  document_title text not null default '',
  storage_path text not null default '',
  shared_with_homeowner boolean not null default false,
  verified_by_manager boolean not null default false,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.lien_waiver_tracking_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  party_type text not null default 'supplier',
  party_name text not null default '',
  waiver_status text not null default 'needed',
  requested_at timestamptz,
  received_at timestamptz,
  verified_at timestamptz,
  issue_notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.homeowner_closeout_delivery_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  closeout_packet_id uuid references public.job_closeout_packets_deep(id) on delete set null,
  delivery_channel text not null default 'portal',
  delivery_status text not null default 'pending',
  sent_at timestamptz,
  viewed_at timestamptz,
  acknowledged_at timestamptz,
  homeowner_notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.manager_closeout_approval_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  closeout_packet_id uuid references public.job_closeout_packets_deep(id) on delete set null,
  approval_status text not null default 'pending',
  approval_notes text not null default '',
  approved_by uuid,
  approved_at timestamptz,
  rejection_reason text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.closeout_followup_tasks_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  task_type text not null default 'general',
  task_status text not null default 'open',
  due_at timestamptz,
  assigned_user_id uuid,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.job_closeout_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  closeout_packet_id uuid references public.job_closeout_packets_deep(id) on delete set null,
  event_type text not null default 'activity',
  event_summary text not null default '',
  event_payload jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create index if not exists idx_job_closeout_packets_deep_company_job on public.job_closeout_packets_deep(company_id, job_id);
create index if not exists idx_warranty_registration_runs_deep_company_job on public.warranty_registration_runs_deep(company_id, job_id);
create index if not exists idx_final_job_document_records_deep_company_job on public.final_job_document_records_deep(company_id, job_id);
create index if not exists idx_lien_waiver_tracking_deep_company_job on public.lien_waiver_tracking_deep(company_id, job_id);
create index if not exists idx_homeowner_closeout_delivery_deep_company_job on public.homeowner_closeout_delivery_deep(company_id, job_id);
create index if not exists idx_manager_closeout_approval_runs_deep_company_job on public.manager_closeout_approval_runs_deep(company_id, job_id);
create index if not exists idx_closeout_followup_tasks_deep_company_job on public.closeout_followup_tasks_deep(company_id, job_id);
create index if not exists idx_job_closeout_activity_events_deep_company_job on public.job_closeout_activity_events_deep(company_id, job_id);

alter table public.job_closeout_packets_deep enable row level security;
alter table public.warranty_registration_runs_deep enable row level security;
alter table public.final_job_document_records_deep enable row level security;
alter table public.lien_waiver_tracking_deep enable row level security;
alter table public.homeowner_closeout_delivery_deep enable row level security;
alter table public.manager_closeout_approval_runs_deep enable row level security;
alter table public.closeout_followup_tasks_deep enable row level security;
alter table public.job_closeout_activity_events_deep enable row level security;

grant select, insert, update on public.job_closeout_packets_deep to authenticated;
grant select, insert, update on public.warranty_registration_runs_deep to authenticated;
grant select, insert, update on public.final_job_document_records_deep to authenticated;
grant select, insert, update on public.lien_waiver_tracking_deep to authenticated;
grant select, insert, update on public.homeowner_closeout_delivery_deep to authenticated;
grant select, insert, update on public.manager_closeout_approval_runs_deep to authenticated;
grant select, insert, update on public.closeout_followup_tasks_deep to authenticated;
grant select, insert on public.job_closeout_activity_events_deep to authenticated;

-- Live database migration includes full manager/job-scoped RLS policies using private.company_access, private.can_job, and private.is_manager.
