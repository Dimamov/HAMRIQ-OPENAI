-- HAMRIQ warranty/service retention execution layer
-- Adds warranty registration, callback triage, service work orders,
-- recurring maintenance execution, renewal campaigns, and past-customer reactivation.

create table if not exists public.warranty_registration_records_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  contact_id uuid references public.contacts(id) on delete set null,
  warranty_type text not null default 'workmanship' check (warranty_type in ('workmanship','manufacturer','extended','maintenance','other')),
  warranty_number text,
  status text not null default 'active' check (status in ('draft','active','pending_registration','expired','void','cancelled')),
  effective_date date,
  expiration_date date,
  registration_payload jsonb not null default '{}'::jsonb,
  documents jsonb not null default '[]'::jsonb,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.callback_triage_records_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  contact_id uuid references public.contacts(id) on delete set null,
  source text not null default 'homeowner' check (source in ('homeowner','rep','crew','manager','portal','hammy','other')),
  issue_category text not null default 'unknown',
  severity text not null default 'normal' check (severity in ('low','normal','urgent','emergency')),
  status text not null default 'new' check (status in ('new','reviewing','scheduled','resolved','rejected','follow_up_needed')),
  homeowner_description text,
  ai_summary text,
  ai_requires_human_review boolean not null default true,
  assigned_to uuid,
  due_at timestamptz,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.service_work_orders_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  callback_triage_id uuid references public.callback_triage_records_deep(id) on delete set null,
  service_ticket_id uuid references public.service_tickets(id) on delete set null,
  assigned_to uuid,
  status text not null default 'open' check (status in ('open','scheduled','in_progress','waiting_parts','completed','cancelled')),
  scheduled_start timestamptz,
  scheduled_end timestamptz,
  work_scope text,
  materials_needed jsonb not null default '[]'::jsonb,
  photos_required boolean not null default true,
  completion_notes text,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.service_work_order_activity_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  work_order_id uuid not null references public.service_work_orders_deep(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  activity_type text not null default 'note' check (activity_type in ('note','status_change','photo_added','part_ordered','arrival','departure','completion','customer_update')),
  details jsonb not null default '{}'::jsonb,
  note text,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.recurring_maintenance_schedules_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  property_id uuid references public.properties(id) on delete set null,
  contact_id uuid references public.contacts(id) on delete set null,
  job_id uuid references public.jobs(id) on delete set null,
  schedule_name text not null,
  cadence text not null default 'annual' check (cadence in ('monthly','quarterly','semi_annual','annual','custom')),
  status text not null default 'active' check (status in ('draft','active','paused','cancelled','expired')),
  next_due_date date,
  checklist jsonb not null default '[]'::jsonb,
  contract_details jsonb not null default '{}'::jsonb,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.maintenance_visit_execution_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  maintenance_schedule_id uuid references public.recurring_maintenance_schedules_deep(id) on delete set null,
  service_work_order_id uuid references public.service_work_orders_deep(id) on delete set null,
  job_id uuid references public.jobs(id) on delete set null,
  status text not null default 'planned' check (status in ('planned','scheduled','in_progress','completed','missed','cancelled')),
  visit_date date,
  technician_id uuid,
  findings jsonb not null default '[]'::jsonb,
  recommended_repairs jsonb not null default '[]'::jsonb,
  customer_report_status text not null default 'not_sent' check (customer_report_status in ('not_sent','drafted','sent','acknowledged')),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.service_renewal_campaigns_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  campaign_name text not null,
  audience_type text not null default 'past_customers' check (audience_type in ('past_customers','maintenance_customers','warranty_expiring','service_customers','custom')),
  status text not null default 'draft' check (status in ('draft','scheduled','active','paused','completed','cancelled')),
  start_date date,
  end_date date,
  message_template jsonb not null default '{}'::jsonb,
  ai_generated boolean not null default false,
  ai_requires_human_review boolean not null default true,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.past_customer_reactivation_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  campaign_id uuid references public.service_renewal_campaigns_deep(id) on delete set null,
  contact_id uuid references public.contacts(id) on delete set null,
  prior_job_id uuid references public.jobs(id) on delete set null,
  status text not null default 'queued' check (status in ('queued','sent','responded','appointment_booked','not_interested','do_not_contact','won','lost')),
  suggested_offer text,
  last_contacted_at timestamptz,
  next_follow_up_at timestamptz,
  outcome_notes text,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists warranty_registration_records_deep_company_job_idx on public.warranty_registration_records_deep(company_id, job_id);
create index if not exists callback_triage_records_deep_company_status_idx on public.callback_triage_records_deep(company_id, status, severity);
create index if not exists service_work_orders_deep_company_status_idx on public.service_work_orders_deep(company_id, status, scheduled_start);
create index if not exists service_work_order_activity_deep_work_order_idx on public.service_work_order_activity_deep(company_id, work_order_id);
create index if not exists recurring_maintenance_schedules_deep_company_due_idx on public.recurring_maintenance_schedules_deep(company_id, status, next_due_date);
create index if not exists maintenance_visit_execution_deep_company_status_idx on public.maintenance_visit_execution_deep(company_id, status, visit_date);
create index if not exists service_renewal_campaigns_deep_company_status_idx on public.service_renewal_campaigns_deep(company_id, status);
create index if not exists past_customer_reactivation_runs_deep_company_status_idx on public.past_customer_reactivation_runs_deep(company_id, status, next_follow_up_at);

alter table public.warranty_registration_records_deep enable row level security;
alter table public.callback_triage_records_deep enable row level security;
alter table public.service_work_orders_deep enable row level security;
alter table public.service_work_order_activity_deep enable row level security;
alter table public.recurring_maintenance_schedules_deep enable row level security;
alter table public.maintenance_visit_execution_deep enable row level security;
alter table public.service_renewal_campaigns_deep enable row level security;
alter table public.past_customer_reactivation_runs_deep enable row level security;

revoke all on public.warranty_registration_records_deep from anon, authenticated;
revoke all on public.callback_triage_records_deep from anon, authenticated;
revoke all on public.service_work_orders_deep from anon, authenticated;
revoke all on public.service_work_order_activity_deep from anon, authenticated;
revoke all on public.recurring_maintenance_schedules_deep from anon, authenticated;
revoke all on public.maintenance_visit_execution_deep from anon, authenticated;
revoke all on public.service_renewal_campaigns_deep from anon, authenticated;
revoke all on public.past_customer_reactivation_runs_deep from anon, authenticated;

grant select, insert, update on public.warranty_registration_records_deep to authenticated;
grant select, insert, update on public.callback_triage_records_deep to authenticated;
grant select, insert, update on public.service_work_orders_deep to authenticated;
grant select, insert, update on public.service_work_order_activity_deep to authenticated;
grant select, insert, update on public.recurring_maintenance_schedules_deep to authenticated;
grant select, insert, update on public.maintenance_visit_execution_deep to authenticated;
grant select, insert, update on public.service_renewal_campaigns_deep to authenticated;
grant select, insert, update on public.past_customer_reactivation_runs_deep to authenticated;

create policy warranty_registration_records_deep_company_access on public.warranty_registration_records_deep for all to authenticated using (private.company_access(company_id)) with check (private.company_access(company_id));
create policy callback_triage_records_deep_company_access on public.callback_triage_records_deep for all to authenticated using (private.company_access(company_id)) with check (private.company_access(company_id));
create policy service_work_orders_deep_company_access on public.service_work_orders_deep for all to authenticated using (private.company_access(company_id)) with check (private.company_access(company_id));
create policy service_work_order_activity_deep_company_access on public.service_work_order_activity_deep for all to authenticated using (private.company_access(company_id)) with check (private.company_access(company_id));
create policy recurring_maintenance_schedules_deep_manager_access on public.recurring_maintenance_schedules_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy maintenance_visit_execution_deep_company_access on public.maintenance_visit_execution_deep for all to authenticated using (private.company_access(company_id)) with check (private.company_access(company_id));
create policy service_renewal_campaigns_deep_manager_access on public.service_renewal_campaigns_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy past_customer_reactivation_runs_deep_manager_access on public.past_customer_reactivation_runs_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
