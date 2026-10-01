-- Post-install quality control / punch-list execution layer
-- Adds final inspection, cleanup checks, punch-list tracking, photo verification,
-- homeowner walkthrough records, failed-QC escalation, and manager signoff.

create table if not exists public.post_install_qc_inspections_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  inspection_status text not null default 'draft' check (inspection_status in ('draft','in_progress','passed','failed','manager_review','approved','rework_required')),
  inspected_by uuid not null default auth.uid(),
  inspection_started_at timestamptz,
  inspection_completed_at timestamptz,
  overall_score numeric(5,2),
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.post_install_cleanup_checks_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  qc_inspection_id uuid references public.post_install_qc_inspections_deep(id) on delete cascade,
  check_area text not null default 'general',
  check_status text not null default 'pending' check (check_status in ('pending','passed','failed','not_applicable','recheck_needed')),
  magnet_sweep_completed boolean not null default false,
  gutters_cleaned boolean not null default false,
  yard_cleaned boolean not null default false,
  driveway_cleaned boolean not null default false,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.post_install_punch_list_items_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  qc_inspection_id uuid references public.post_install_qc_inspections_deep(id) on delete cascade,
  item_title text not null,
  item_description text not null default '',
  severity text not null default 'normal' check (severity in ('low','normal','high','critical')),
  item_status text not null default 'open' check (item_status in ('open','assigned','in_progress','fixed','verified','closed','rejected')),
  assigned_to uuid,
  due_at timestamptz,
  fixed_at timestamptz,
  verified_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.post_install_photo_verifications_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  qc_inspection_id uuid references public.post_install_qc_inspections_deep(id) on delete cascade,
  punch_list_item_id uuid references public.post_install_punch_list_items_deep(id) on delete cascade,
  photo_url text not null default '',
  photo_type text not null default 'after' check (photo_type in ('before','after','cleanup','damage','repair','walkthrough','other')),
  verification_status text not null default 'pending' check (verification_status in ('pending','approved','rejected','needs_retake')),
  ai_notes jsonb not null default '{}'::jsonb,
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.homeowner_walkthrough_records_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  qc_inspection_id uuid references public.post_install_qc_inspections_deep(id) on delete cascade,
  walkthrough_status text not null default 'not_started' check (walkthrough_status in ('not_started','scheduled','completed','customer_unavailable','customer_issues_found','signed_off')),
  scheduled_at timestamptz,
  completed_at timestamptz,
  homeowner_feedback text not null default '',
  customer_signature_url text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.failed_qc_escalations_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  qc_inspection_id uuid references public.post_install_qc_inspections_deep(id) on delete cascade,
  escalation_reason text not null default '',
  escalation_status text not null default 'open' check (escalation_status in ('open','manager_review','assigned','resolved','closed')),
  assigned_manager_id uuid,
  resolution_notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.post_install_manager_signoffs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  qc_inspection_id uuid references public.post_install_qc_inspections_deep(id) on delete cascade,
  signoff_status text not null default 'pending' check (signoff_status in ('pending','approved','rejected','rework_required')),
  signed_by uuid,
  signed_at timestamptz,
  signoff_notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.post_install_qc_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  event_type text not null,
  event_summary text not null default '',
  event_payload jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

alter table public.post_install_qc_inspections_deep enable row level security;
alter table public.post_install_cleanup_checks_deep enable row level security;
alter table public.post_install_punch_list_items_deep enable row level security;
alter table public.post_install_photo_verifications_deep enable row level security;
alter table public.homeowner_walkthrough_records_deep enable row level security;
alter table public.failed_qc_escalations_deep enable row level security;
alter table public.post_install_manager_signoffs_deep enable row level security;
alter table public.post_install_qc_activity_events_deep enable row level security;

revoke all on public.post_install_qc_inspections_deep from anon, authenticated;
revoke all on public.post_install_cleanup_checks_deep from anon, authenticated;
revoke all on public.post_install_punch_list_items_deep from anon, authenticated;
revoke all on public.post_install_photo_verifications_deep from anon, authenticated;
revoke all on public.homeowner_walkthrough_records_deep from anon, authenticated;
revoke all on public.failed_qc_escalations_deep from anon, authenticated;
revoke all on public.post_install_manager_signoffs_deep from anon, authenticated;
revoke all on public.post_install_qc_activity_events_deep from anon, authenticated;

grant select, insert, update on public.post_install_qc_inspections_deep to authenticated;
grant select, insert, update on public.post_install_cleanup_checks_deep to authenticated;
grant select, insert, update on public.post_install_punch_list_items_deep to authenticated;
grant select, insert, update on public.post_install_photo_verifications_deep to authenticated;
grant select, insert, update on public.homeowner_walkthrough_records_deep to authenticated;
grant select, insert, update on public.failed_qc_escalations_deep to authenticated;
grant select, insert, update on public.post_install_manager_signoffs_deep to authenticated;
grant select, insert, update on public.post_install_qc_activity_events_deep to authenticated;

create policy post_install_qc_inspections_access on public.post_install_qc_inspections_deep for all to authenticated using (private.can_job(company_id, job_id) or private.is_manager(company_id)) with check (private.can_job(company_id, job_id) or private.is_manager(company_id));
create policy post_install_cleanup_access on public.post_install_cleanup_checks_deep for all to authenticated using (private.can_job(company_id, job_id) or private.is_manager(company_id)) with check (private.can_job(company_id, job_id) or private.is_manager(company_id));
create policy post_install_punch_access on public.post_install_punch_list_items_deep for all to authenticated using (private.can_job(company_id, job_id) or private.is_manager(company_id)) with check (private.can_job(company_id, job_id) or private.is_manager(company_id));
create policy post_install_photo_access on public.post_install_photo_verifications_deep for all to authenticated using (private.can_job(company_id, job_id) or private.is_manager(company_id)) with check (private.can_job(company_id, job_id) or private.is_manager(company_id));
create policy homeowner_walkthrough_access on public.homeowner_walkthrough_records_deep for all to authenticated using (private.can_job(company_id, job_id) or private.is_manager(company_id)) with check (private.can_job(company_id, job_id) or private.is_manager(company_id));
create policy failed_qc_escalations_access on public.failed_qc_escalations_deep for all to authenticated using (private.can_job(company_id, job_id) or private.is_manager(company_id)) with check (private.can_job(company_id, job_id) or private.is_manager(company_id));
create policy post_install_manager_signoffs_access on public.post_install_manager_signoffs_deep for all to authenticated using (private.is_manager(company_id) or private.can_job(company_id, job_id)) with check (private.is_manager(company_id));
create policy post_install_qc_activity_access on public.post_install_qc_activity_events_deep for all to authenticated using (private.company_access(company_id)) with check (private.company_access(company_id));
