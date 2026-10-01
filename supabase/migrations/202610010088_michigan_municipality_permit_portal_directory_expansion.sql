-- HAMRIQ migration: Michigan municipality permit portal directory expansion
-- Adds searchable municipality permit profiles, roofing permit requirements,
-- embedded/external online permit links, verification tasks, and source tracking.

create table if not exists public.michigan_municipality_permit_profiles_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  municipality_name text not null,
  municipality_type text not null default 'city' check (municipality_type in ('city','township','village','county','authority','other')),
  county_name text,
  state_code text not null default 'MI',
  roofing_permit_required text not null default 'unknown' check (roofing_permit_required in ('yes','no','conditional','unknown')),
  permit_office_name text,
  permit_office_phone text,
  permit_office_email text,
  permit_office_address text,
  official_website_url text,
  online_permit_portal_url text,
  online_application_available boolean not null default false,
  embeddable_in_app boolean not null default false,
  external_browser_required boolean not null default true,
  portal_login_required boolean not null default false,
  searchable_keywords text[] not null default '{}',
  profile_status text not null default 'draft' check (profile_status in ('draft','needs_verification','verified','stale','archived')),
  verified_at timestamptz,
  verified_by uuid,
  source_notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.municipality_roofing_permit_requirements_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  municipality_profile_id uuid not null references public.michigan_municipality_permit_profiles_deep(id) on delete cascade,
  requirement_title text not null,
  requirement_category text not null default 'general' check (requirement_category in ('general','roofing','tear_off','recover','decking','ice_water','ventilation','final_inspection','fees','documents','license','insurance','other')),
  requirement_text text not null,
  applies_when jsonb not null default '{}'::jsonb,
  required_documents jsonb not null default '[]'::jsonb,
  fee_notes text not null default '',
  inspection_notes text not null default '',
  source_url text,
  source_last_checked_at timestamptz,
  confidence_status text not null default 'needs_verification' check (confidence_status in ('needs_verification','verified','conflicting','stale')),
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.permit_portal_access_links_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  municipality_profile_id uuid not null references public.michigan_municipality_permit_profiles_deep(id) on delete cascade,
  link_label text not null default 'Apply online',
  portal_url text not null,
  access_type text not null default 'external_link' check (access_type in ('embedded_webview','external_link','download_form','email_submission','phone_only','in_person_only')),
  login_required boolean not null default false,
  payment_online_available boolean not null default false,
  document_upload_available boolean not null default false,
  inspection_request_available boolean not null default false,
  notes text not null default '',
  status text not null default 'needs_verification' check (status in ('needs_verification','verified','broken','archived')),
  last_checked_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.permit_requirement_search_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null default auth.uid(),
  search_query text not null,
  search_city text,
  search_county text,
  job_id uuid references public.jobs(id) on delete set null,
  matched_profile_id uuid references public.michigan_municipality_permit_profiles_deep(id) on delete set null,
  result_count integer not null default 0,
  search_status text not null default 'completed' check (search_status in ('started','completed','no_match','failed')),
  created_at timestamptz not null default now()
);

create table if not exists public.permit_requirement_search_results_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  search_run_id uuid not null references public.permit_requirement_search_runs_deep(id) on delete cascade,
  municipality_profile_id uuid references public.michigan_municipality_permit_profiles_deep(id) on delete cascade,
  requirement_id uuid references public.municipality_roofing_permit_requirements_deep(id) on delete set null,
  result_type text not null default 'profile' check (result_type in ('profile','requirement','portal_link','document','warning')),
  result_title text not null,
  result_summary text not null default '',
  match_score numeric(6,3) not null default 0,
  needs_verification boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.permit_portal_verification_tasks_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  municipality_profile_id uuid references public.michigan_municipality_permit_profiles_deep(id) on delete cascade,
  assigned_to uuid,
  task_type text not null default 'verify_requirement' check (task_type in ('verify_requirement','verify_portal_link','verify_fee','verify_contact','verify_inspection_process','refresh_profile')),
  task_status text not null default 'open' check (task_status in ('open','in_progress','verified','needs_manager_review','closed','archived')),
  due_at timestamptz,
  verification_notes text not null default '',
  source_url text,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.permit_portal_source_records_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  municipality_profile_id uuid references public.michigan_municipality_permit_profiles_deep(id) on delete cascade,
  source_type text not null default 'website' check (source_type in ('website','pdf','form','email','phone_call','staff_note','other')),
  source_title text not null,
  source_url text,
  source_date date,
  captured_summary text not null default '',
  reliability_status text not null default 'unverified' check (reliability_status in ('unverified','official','verified','conflicting','stale')),
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.municipality_permit_portal_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  municipality_profile_id uuid references public.michigan_municipality_permit_profiles_deep(id) on delete set null,
  job_id uuid references public.jobs(id) on delete set null,
  actor_user_id uuid not null default auth.uid(),
  event_type text not null default 'portal_event',
  event_summary text not null default '',
  event_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_mi_permit_profiles_company_name on public.michigan_municipality_permit_profiles_deep(company_id, municipality_name);
create index if not exists idx_mi_permit_profiles_company_county on public.michigan_municipality_permit_profiles_deep(company_id, county_name);
create index if not exists idx_mi_permit_requirements_profile on public.municipality_roofing_permit_requirements_deep(company_id, municipality_profile_id);
create index if not exists idx_permit_portal_links_profile on public.permit_portal_access_links_deep(company_id, municipality_profile_id);
create index if not exists idx_permit_search_runs_user on public.permit_requirement_search_runs_deep(company_id, user_id, created_at desc);
create index if not exists idx_permit_verification_tasks_status on public.permit_portal_verification_tasks_deep(company_id, task_status, due_at);
create index if not exists idx_permit_source_records_profile on public.permit_portal_source_records_deep(company_id, municipality_profile_id);
create index if not exists idx_municipality_permit_activity_company on public.municipality_permit_portal_activity_events_deep(company_id, created_at desc);

alter table public.michigan_municipality_permit_profiles_deep enable row level security;
alter table public.municipality_roofing_permit_requirements_deep enable row level security;
alter table public.permit_portal_access_links_deep enable row level security;
alter table public.permit_requirement_search_runs_deep enable row level security;
alter table public.permit_requirement_search_results_deep enable row level security;
alter table public.permit_portal_verification_tasks_deep enable row level security;
alter table public.permit_portal_source_records_deep enable row level security;
alter table public.municipality_permit_portal_activity_events_deep enable row level security;

revoke all on public.michigan_municipality_permit_profiles_deep from anon, authenticated;
revoke all on public.municipality_roofing_permit_requirements_deep from anon, authenticated;
revoke all on public.permit_portal_access_links_deep from anon, authenticated;
revoke all on public.permit_requirement_search_runs_deep from anon, authenticated;
revoke all on public.permit_requirement_search_results_deep from anon, authenticated;
revoke all on public.permit_portal_verification_tasks_deep from anon, authenticated;
revoke all on public.permit_portal_source_records_deep from anon, authenticated;
revoke all on public.municipality_permit_portal_activity_events_deep from anon, authenticated;

grant select, insert, update on public.michigan_municipality_permit_profiles_deep to authenticated;
grant select, insert, update on public.municipality_roofing_permit_requirements_deep to authenticated;
grant select, insert, update on public.permit_portal_access_links_deep to authenticated;
grant select, insert, update on public.permit_requirement_search_runs_deep to authenticated;
grant select, insert, update on public.permit_requirement_search_results_deep to authenticated;
grant select, insert, update on public.permit_portal_verification_tasks_deep to authenticated;
grant select, insert, update on public.permit_portal_source_records_deep to authenticated;
grant select, insert, update on public.municipality_permit_portal_activity_events_deep to authenticated;

create policy mi_permit_profiles_select on public.michigan_municipality_permit_profiles_deep for select to authenticated using (private.company_access(company_id));
create policy mi_permit_profiles_write_manager on public.michigan_municipality_permit_profiles_deep for insert to authenticated with check (private.is_manager(company_id));
create policy mi_permit_profiles_update_manager on public.michigan_municipality_permit_profiles_deep for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy mi_permit_requirements_select on public.municipality_roofing_permit_requirements_deep for select to authenticated using (private.company_access(company_id));
create policy mi_permit_requirements_write_manager on public.municipality_roofing_permit_requirements_deep for insert to authenticated with check (private.is_manager(company_id));
create policy mi_permit_requirements_update_manager on public.municipality_roofing_permit_requirements_deep for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy permit_portal_links_select on public.permit_portal_access_links_deep for select to authenticated using (private.company_access(company_id));
create policy permit_portal_links_write_manager on public.permit_portal_access_links_deep for insert to authenticated with check (private.is_manager(company_id));
create policy permit_portal_links_update_manager on public.permit_portal_access_links_deep for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy permit_search_runs_own_select on public.permit_requirement_search_runs_deep for select to authenticated using (private.company_access(company_id) and (user_id = auth.uid() or private.is_manager(company_id)));
create policy permit_search_runs_own_insert on public.permit_requirement_search_runs_deep for insert to authenticated with check (private.company_access(company_id) and user_id = auth.uid());
create policy permit_search_runs_own_update on public.permit_requirement_search_runs_deep for update to authenticated using (private.company_access(company_id) and (user_id = auth.uid() or private.is_manager(company_id))) with check (private.company_access(company_id));

create policy permit_search_results_select on public.permit_requirement_search_results_deep for select to authenticated using (private.company_access(company_id));
create policy permit_search_results_insert on public.permit_requirement_search_results_deep for insert to authenticated with check (private.company_access(company_id));
create policy permit_search_results_update_manager on public.permit_requirement_search_results_deep for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy permit_verification_tasks_select on public.permit_portal_verification_tasks_deep for select to authenticated using (private.company_access(company_id));
create policy permit_verification_tasks_insert_manager on public.permit_portal_verification_tasks_deep for insert to authenticated with check (private.is_manager(company_id));
create policy permit_verification_tasks_update_manager on public.permit_portal_verification_tasks_deep for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy permit_source_records_select on public.permit_portal_source_records_deep for select to authenticated using (private.company_access(company_id));
create policy permit_source_records_insert_manager on public.permit_portal_source_records_deep for insert to authenticated with check (private.is_manager(company_id));
create policy permit_source_records_update_manager on public.permit_portal_source_records_deep for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy municipality_permit_activity_select on public.municipality_permit_portal_activity_events_deep for select to authenticated using (private.company_access(company_id));
create policy municipality_permit_activity_insert on public.municipality_permit_portal_activity_events_deep for insert to authenticated with check (private.company_access(company_id));
create policy municipality_permit_activity_update_manager on public.municipality_permit_portal_activity_events_deep for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
