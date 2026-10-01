create table if not exists public.document_expiration_trackers_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  document_record_id uuid references public.document_records(id) on delete set null,
  document_name text not null,
  document_type text not null default 'general',
  owner_user_id uuid,
  expiration_date date,
  renewal_status text not null default 'active' check (renewal_status in ('active','expiring_soon','expired','renewal_requested','renewed','waived','archived')),
  manager_review_required boolean not null default false,
  notes text not null default '',
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.document_renewal_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  document_expiration_tracker_id uuid references public.document_expiration_trackers_deep(id) on delete cascade,
  renewal_type text not null default 'manual' check (renewal_type in ('manual','automatic_reminder','vendor_request','employee_request','manager_request')),
  run_status text not null default 'draft' check (run_status in ('draft','sent','waiting','received','review_needed','approved','rejected','cancelled')),
  due_date date,
  sent_to text not null default '',
  manager_review_required boolean not null default true,
  renewal_payload jsonb not null default '{}'::jsonb,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.license_insurance_tracking_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  vendor_id uuid references public.vendors(id) on delete set null,
  employee_user_id uuid,
  record_category text not null default 'license' check (record_category in ('license','insurance','bond','certification','registration','other')),
  record_name text not null,
  issuing_authority text not null default '',
  policy_or_license_number text not null default '',
  effective_date date,
  expiration_date date,
  status text not null default 'active' check (status in ('active','expiring_soon','expired','suspended','renewal_pending','waived','archived')),
  manager_review_required boolean not null default false,
  file_url text not null default '',
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.employee_document_assignments_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  assigned_user_id uuid not null,
  document_name text not null,
  assignment_type text not null default 'acknowledgment' check (assignment_type in ('acknowledgment','upload_required','signature_required','training_document','policy_document','certification')),
  assignment_status text not null default 'assigned' check (assignment_status in ('assigned','viewed','uploaded','signed','acknowledged','rejected','overdue','cancelled')),
  due_date date,
  completed_at timestamptz,
  manager_review_required boolean not null default false,
  file_url text not null default '',
  response_payload jsonb not null default '{}'::jsonb,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.permit_file_records_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  permit_application_run_id uuid references public.permit_application_runs_deep(id) on delete set null,
  permit_number text not null default '',
  permit_type text not null default 'roofing',
  issuing_municipality text not null default '',
  permit_status text not null default 'draft' check (permit_status in ('draft','submitted','issued','inspection_required','closed','rejected','expired','cancelled')),
  issue_date date,
  expiration_date date,
  file_url text not null default '',
  manager_review_required boolean not null default false,
  permit_payload jsonb not null default '{}'::jsonb,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.compliance_alert_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  alert_source text not null default 'document_center' check (alert_source in ('document_center','license_insurance','permit','employee_document','vendor','system','hammy')),
  severity text not null default 'medium' check (severity in ('low','medium','high','critical')),
  alert_title text not null,
  alert_status text not null default 'open' check (alert_status in ('open','assigned','in_review','resolved','dismissed','snoozed')),
  assigned_user_id uuid,
  due_at timestamptz,
  manager_review_required boolean not null default true,
  alert_payload jsonb not null default '{}'::jsonb,
  resolution_notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.document_access_audit_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  actor_user_id uuid not null default auth.uid(),
  event_type text not null default 'viewed' check (event_type in ('created','viewed','downloaded','uploaded','updated','shared','signed','acknowledged','expired','renewed','deleted','restored')),
  related_table text not null default '',
  related_record_id uuid,
  event_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.vendor_document_requests_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  vendor_id uuid references public.vendors(id) on delete set null,
  request_name text not null,
  request_type text not null default 'insurance' check (request_type in ('insurance','license','w9','agreement','safety_document','other')),
  request_status text not null default 'draft' check (request_status in ('draft','sent','received','review_needed','approved','rejected','expired','cancelled')),
  due_date date,
  sent_to text not null default '',
  manager_review_required boolean not null default true,
  request_payload jsonb not null default '{}'::jsonb,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_document_expiration_trackers_deep_company on public.document_expiration_trackers_deep(company_id, expiration_date);
create index if not exists idx_document_renewal_runs_deep_company on public.document_renewal_runs_deep(company_id, run_status);
create index if not exists idx_license_insurance_tracking_deep_company on public.license_insurance_tracking_deep(company_id, expiration_date);
create index if not exists idx_employee_document_assignments_deep_company on public.employee_document_assignments_deep(company_id, assigned_user_id, assignment_status);
create index if not exists idx_permit_file_records_deep_company on public.permit_file_records_deep(company_id, job_id, permit_status);
create index if not exists idx_compliance_alert_runs_deep_company on public.compliance_alert_runs_deep(company_id, severity, alert_status);
create index if not exists idx_document_access_audit_events_deep_company on public.document_access_audit_events_deep(company_id, created_at desc);
create index if not exists idx_vendor_document_requests_deep_company on public.vendor_document_requests_deep(company_id, request_status);

alter table public.document_expiration_trackers_deep enable row level security;
alter table public.document_renewal_runs_deep enable row level security;
alter table public.license_insurance_tracking_deep enable row level security;
alter table public.employee_document_assignments_deep enable row level security;
alter table public.permit_file_records_deep enable row level security;
alter table public.compliance_alert_runs_deep enable row level security;
alter table public.document_access_audit_events_deep enable row level security;
alter table public.vendor_document_requests_deep enable row level security;

revoke all on public.document_expiration_trackers_deep from anon, authenticated;
revoke all on public.document_renewal_runs_deep from anon, authenticated;
revoke all on public.license_insurance_tracking_deep from anon, authenticated;
revoke all on public.employee_document_assignments_deep from anon, authenticated;
revoke all on public.permit_file_records_deep from anon, authenticated;
revoke all on public.compliance_alert_runs_deep from anon, authenticated;
revoke all on public.document_access_audit_events_deep from anon, authenticated;
revoke all on public.vendor_document_requests_deep from anon, authenticated;

grant select, insert, update on public.document_expiration_trackers_deep to authenticated;
grant select, insert, update on public.document_renewal_runs_deep to authenticated;
grant select, insert, update on public.license_insurance_tracking_deep to authenticated;
grant select, insert, update on public.employee_document_assignments_deep to authenticated;
grant select, insert, update on public.permit_file_records_deep to authenticated;
grant select, insert, update on public.compliance_alert_runs_deep to authenticated;
grant select, insert on public.document_access_audit_events_deep to authenticated;
grant select, insert, update on public.vendor_document_requests_deep to authenticated;

create policy "document_expiration_trackers_deep_company_access" on public.document_expiration_trackers_deep for all to authenticated using (private.company_access(company_id)) with check (private.company_access(company_id));
create policy "document_renewal_runs_deep_manager_access" on public.document_renewal_runs_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy "license_insurance_tracking_deep_manager_access" on public.license_insurance_tracking_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy "employee_document_assignments_deep_company_access" on public.employee_document_assignments_deep for all to authenticated using (private.company_access(company_id) and (assigned_user_id = auth.uid() or private.is_manager(company_id))) with check (private.company_access(company_id) and (assigned_user_id = auth.uid() or private.is_manager(company_id)));
create policy "permit_file_records_deep_job_access" on public.permit_file_records_deep for all to authenticated using (private.company_access(company_id) and (job_id is null or private.can_job(company_id, job_id))) with check (private.company_access(company_id) and (job_id is null or private.can_job(company_id, job_id)));
create policy "compliance_alert_runs_deep_manager_or_assigned" on public.compliance_alert_runs_deep for all to authenticated using (private.company_access(company_id) and (private.is_manager(company_id) or assigned_user_id = auth.uid())) with check (private.company_access(company_id) and (private.is_manager(company_id) or assigned_user_id = auth.uid()));
create policy "document_access_audit_events_deep_company_insert" on public.document_access_audit_events_deep for insert to authenticated with check (private.company_access(company_id));
create policy "document_access_audit_events_deep_company_select" on public.document_access_audit_events_deep for select to authenticated using (private.company_access(company_id));
create policy "vendor_document_requests_deep_manager_access" on public.vendor_document_requests_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
