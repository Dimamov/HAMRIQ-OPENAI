create table if not exists public.permit_requirement_rules_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  created_by uuid not null default auth.uid(),
  jurisdiction_name text not null,
  permit_type text not null default 'roofing',
  trade_scope text not null default 'residential_roofing',
  rule_status text not null default 'draft' check (rule_status in ('draft','active','inactive','needs_review','archived')),
  requirement_summary text not null default '',
  required_documents jsonb not null default '[]'::jsonb,
  fee_notes text not null default '',
  inspection_required boolean not null default true,
  manager_review_required boolean not null default true,
  source_url text,
  source_checked_at timestamptz,
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.permit_application_packets_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  contact_id uuid references public.contacts(id) on delete set null,
  created_by uuid not null default auth.uid(),
  jurisdiction_name text not null default '',
  permit_type text not null default 'roofing',
  packet_status text not null default 'draft' check (packet_status in ('draft','ready_for_review','approved_to_submit','submitted','accepted','rejected','withdrawn','closed')),
  applicant_name text not null default '',
  property_address text not null default '',
  work_description text not null default '',
  estimated_job_value_cents bigint not null default 0,
  required_documents jsonb not null default '[]'::jsonb,
  submitted_at timestamptz,
  accepted_at timestamptz,
  permit_number text,
  manager_approved_by uuid,
  manager_approved_at timestamptz,
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.permit_document_checklists_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  permit_packet_id uuid references public.permit_application_packets_deep(id) on delete cascade,
  created_by uuid not null default auth.uid(),
  document_name text not null,
  document_status text not null default 'needed' check (document_status in ('needed','uploaded','needs_fix','approved','not_required')),
  file_reference jsonb not null default '{}'::jsonb,
  rejection_reason text not null default '',
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.municipal_inspection_appointments_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  permit_packet_id uuid references public.permit_application_packets_deep(id) on delete set null,
  created_by uuid not null default auth.uid(),
  jurisdiction_name text not null default '',
  inspection_type text not null default 'roofing_final',
  appointment_status text not null default 'requested' check (appointment_status in ('requested','scheduled','confirmed','rescheduled','completed','failed','cancelled')),
  requested_window_start timestamptz,
  scheduled_start timestamptz,
  scheduled_end timestamptz,
  inspector_name text not null default '',
  inspector_phone text not null default '',
  result_summary text not null default '',
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.municipal_response_records_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  permit_packet_id uuid references public.permit_application_packets_deep(id) on delete set null,
  inspection_appointment_id uuid references public.municipal_inspection_appointments_deep(id) on delete set null,
  created_by uuid not null default auth.uid(),
  response_type text not null default 'general' check (response_type in ('general','permit_accepted','permit_rejected','inspection_result','fee_due','document_request','correction_notice')),
  response_status text not null default 'open' check (response_status in ('open','reviewed','action_required','resolved','archived')),
  received_at timestamptz not null default now(),
  message_summary text not null default '',
  raw_response jsonb not null default '{}'::jsonb,
  assigned_to uuid,
  due_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.permit_correction_notices_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  permit_packet_id uuid references public.permit_application_packets_deep(id) on delete set null,
  response_record_id uuid references public.municipal_response_records_deep(id) on delete set null,
  created_by uuid not null default auth.uid(),
  correction_status text not null default 'open' check (correction_status in ('open','assigned','in_progress','ready_for_reinspection','submitted','resolved','disputed','closed')),
  correction_summary text not null default '',
  required_action text not null default '',
  due_at timestamptz,
  assigned_to uuid,
  resolved_by uuid,
  resolved_at timestamptz,
  evidence_links jsonb not null default '[]'::jsonb,
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.permit_status_manager_cards_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  permit_packet_id uuid references public.permit_application_packets_deep(id) on delete set null,
  created_by uuid not null default auth.uid(),
  card_status text not null default 'active' check (card_status in ('active','hidden','resolved','archived')),
  risk_level text not null default 'normal' check (risk_level in ('low','normal','elevated','high','critical')),
  headline text not null default '',
  status_summary text not null default '',
  next_action text not null default '',
  due_at timestamptz,
  assigned_to uuid,
  card_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.permit_workflow_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  permit_packet_id uuid references public.permit_application_packets_deep(id) on delete set null,
  created_by uuid not null default auth.uid(),
  event_type text not null default 'permit_activity',
  event_summary text not null default '',
  event_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_permit_requirement_rules_deep_company on public.permit_requirement_rules_deep(company_id, jurisdiction_name, rule_status);
create index if not exists idx_permit_application_packets_deep_company_job on public.permit_application_packets_deep(company_id, job_id, packet_status);
create index if not exists idx_permit_document_checklists_deep_packet on public.permit_document_checklists_deep(company_id, permit_packet_id, document_status);
create index if not exists idx_municipal_inspection_appointments_deep_job on public.municipal_inspection_appointments_deep(company_id, job_id, appointment_status);
create index if not exists idx_municipal_response_records_deep_packet on public.municipal_response_records_deep(company_id, permit_packet_id, response_status);
create index if not exists idx_permit_correction_notices_deep_job on public.permit_correction_notices_deep(company_id, job_id, correction_status);
create index if not exists idx_permit_status_manager_cards_deep_company on public.permit_status_manager_cards_deep(company_id, card_status, risk_level);
create index if not exists idx_permit_workflow_activity_events_deep_company on public.permit_workflow_activity_events_deep(company_id, created_at desc);

alter table public.permit_requirement_rules_deep enable row level security;
alter table public.permit_application_packets_deep enable row level security;
alter table public.permit_document_checklists_deep enable row level security;
alter table public.municipal_inspection_appointments_deep enable row level security;
alter table public.municipal_response_records_deep enable row level security;
alter table public.permit_correction_notices_deep enable row level security;
alter table public.permit_status_manager_cards_deep enable row level security;
alter table public.permit_workflow_activity_events_deep enable row level security;

revoke all on public.permit_requirement_rules_deep from anon, authenticated;
revoke all on public.permit_application_packets_deep from anon, authenticated;
revoke all on public.permit_document_checklists_deep from anon, authenticated;
revoke all on public.municipal_inspection_appointments_deep from anon, authenticated;
revoke all on public.municipal_response_records_deep from anon, authenticated;
revoke all on public.permit_correction_notices_deep from anon, authenticated;
revoke all on public.permit_status_manager_cards_deep from anon, authenticated;
revoke all on public.permit_workflow_activity_events_deep from anon, authenticated;

grant select, insert, update on public.permit_requirement_rules_deep to authenticated;
grant select, insert, update on public.permit_application_packets_deep to authenticated;
grant select, insert, update on public.permit_document_checklists_deep to authenticated;
grant select, insert, update on public.municipal_inspection_appointments_deep to authenticated;
grant select, insert, update on public.municipal_response_records_deep to authenticated;
grant select, insert, update on public.permit_correction_notices_deep to authenticated;
grant select, insert, update on public.permit_status_manager_cards_deep to authenticated;
grant select, insert on public.permit_workflow_activity_events_deep to authenticated;

create policy permit_requirement_rules_deep_manager_all on public.permit_requirement_rules_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy permit_application_packets_deep_company_all on public.permit_application_packets_deep for all to authenticated using (private.company_access(company_id)) with check (private.company_access(company_id));
create policy permit_document_checklists_deep_company_all on public.permit_document_checklists_deep for all to authenticated using (private.company_access(company_id)) with check (private.company_access(company_id));
create policy municipal_inspection_appointments_deep_company_all on public.municipal_inspection_appointments_deep for all to authenticated using (private.company_access(company_id)) with check (private.company_access(company_id));
create policy municipal_response_records_deep_company_all on public.municipal_response_records_deep for all to authenticated using (private.company_access(company_id)) with check (private.company_access(company_id));
create policy permit_correction_notices_deep_company_all on public.permit_correction_notices_deep for all to authenticated using (private.company_access(company_id)) with check (private.company_access(company_id));
create policy permit_status_manager_cards_deep_manager_all on public.permit_status_manager_cards_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy permit_workflow_activity_events_deep_company_insert_select on public.permit_workflow_activity_events_deep for all to authenticated using (private.company_access(company_id)) with check (private.company_access(company_id));
