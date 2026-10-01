create table if not exists public.portal_invites_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  contact_id uuid references public.contacts(id) on delete set null,
  invited_email text,
  invited_phone text,
  invite_status text not null default 'draft' check (invite_status in ('draft','sent','accepted','expired','revoked')),
  access_token_hash text,
  expires_at timestamptz,
  sent_at timestamptz,
  accepted_at timestamptz,
  revoked_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.portal_document_access_events (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  portal_invite_id uuid references public.portal_invites_deep(id) on delete set null,
  document_record_id uuid references public.document_records(id) on delete set null,
  access_type text not null default 'viewed' check (access_type in ('viewed','downloaded','shared','revoked')),
  homeowner_label text,
  ip_hash text,
  user_agent text,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.portal_status_timeline_views (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  portal_invite_id uuid references public.portal_invites_deep(id) on delete set null,
  stage_name text not null,
  viewed_status text not null default 'viewed' check (viewed_status in ('viewed','acknowledged','question_sent')),
  viewed_at timestamptz not null default now(),
  homeowner_question text,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.portal_selection_approvals (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  product_selection_confirmation_id uuid references public.product_selection_confirmations(id) on delete set null,
  portal_invite_id uuid references public.portal_invites_deep(id) on delete set null,
  approval_status text not null default 'pending' check (approval_status in ('pending','approved','change_requested','revoked')),
  selection_summary jsonb not null default '{}'::jsonb,
  homeowner_notes text,
  approved_at timestamptz,
  change_requested_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.portal_message_threads_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  portal_invite_id uuid references public.portal_invites_deep(id) on delete set null,
  subject text not null default 'Portal message',
  thread_status text not null default 'open' check (thread_status in ('open','waiting_on_customer','waiting_on_company','closed')),
  assigned_to uuid,
  last_message_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.portal_message_entries_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  thread_id uuid not null references public.portal_message_threads_deep(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  sender_type text not null default 'company' check (sender_type in ('company','homeowner','system','hammy')),
  message_body text not null,
  ai_generated boolean not null default false,
  requires_human_review boolean not null default false,
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.portal_completion_signoffs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  completion_certificate_id uuid references public.completion_certificates(id) on delete set null,
  portal_invite_id uuid references public.portal_invites_deep(id) on delete set null,
  signoff_status text not null default 'pending' check (signoff_status in ('pending','signed','declined','needs_follow_up')),
  homeowner_name text,
  homeowner_notes text,
  signature_asset_path text,
  signed_at timestamptz,
  declined_at timestamptz,
  follow_up_required boolean not null default false,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.portal_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  portal_invite_id uuid references public.portal_invites_deep(id) on delete set null,
  event_type text not null,
  event_summary text,
  event_payload jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create index if not exists idx_portal_invites_deep_company_job on public.portal_invites_deep(company_id, job_id);
create index if not exists idx_portal_document_access_company_job on public.portal_document_access_events(company_id, job_id);
create index if not exists idx_portal_status_timeline_company_job on public.portal_status_timeline_views(company_id, job_id);
create index if not exists idx_portal_selection_approvals_company_job on public.portal_selection_approvals(company_id, job_id);
create index if not exists idx_portal_threads_company_job on public.portal_message_threads_deep(company_id, job_id);
create index if not exists idx_portal_entries_thread on public.portal_message_entries_deep(thread_id);
create index if not exists idx_portal_completion_company_job on public.portal_completion_signoffs(company_id, job_id);
create index if not exists idx_portal_activity_company_job on public.portal_activity_events_deep(company_id, job_id);

alter table public.portal_invites_deep enable row level security;
alter table public.portal_document_access_events enable row level security;
alter table public.portal_status_timeline_views enable row level security;
alter table public.portal_selection_approvals enable row level security;
alter table public.portal_message_threads_deep enable row level security;
alter table public.portal_message_entries_deep enable row level security;
alter table public.portal_completion_signoffs enable row level security;
alter table public.portal_activity_events_deep enable row level security;

revoke all on public.portal_invites_deep from anon, authenticated;
revoke all on public.portal_document_access_events from anon, authenticated;
revoke all on public.portal_status_timeline_views from anon, authenticated;
revoke all on public.portal_selection_approvals from anon, authenticated;
revoke all on public.portal_message_threads_deep from anon, authenticated;
revoke all on public.portal_message_entries_deep from anon, authenticated;
revoke all on public.portal_completion_signoffs from anon, authenticated;
revoke all on public.portal_activity_events_deep from anon, authenticated;

grant select, insert, update on public.portal_invites_deep to authenticated;
grant select, insert, update on public.portal_document_access_events to authenticated;
grant select, insert, update on public.portal_status_timeline_views to authenticated;
grant select, insert, update on public.portal_selection_approvals to authenticated;
grant select, insert, update on public.portal_message_threads_deep to authenticated;
grant select, insert, update on public.portal_message_entries_deep to authenticated;
grant select, insert, update on public.portal_completion_signoffs to authenticated;
grant select, insert, update on public.portal_activity_events_deep to authenticated;

drop policy if exists portal_invites_manager_control on public.portal_invites_deep;
create policy portal_invites_manager_control on public.portal_invites_deep for all to authenticated using (private.is_manager(company_id) or (job_id is not null and private.can_job(company_id, job_id))) with check (private.is_manager(company_id) or (job_id is not null and private.can_job(company_id, job_id)));

drop policy if exists portal_document_access_job_control on public.portal_document_access_events;
create policy portal_document_access_job_control on public.portal_document_access_events for all to authenticated using (private.is_manager(company_id) or (job_id is not null and private.can_job(company_id, job_id))) with check (private.is_manager(company_id) or (job_id is not null and private.can_job(company_id, job_id)));

drop policy if exists portal_status_timeline_job_control on public.portal_status_timeline_views;
create policy portal_status_timeline_job_control on public.portal_status_timeline_views for all to authenticated using (private.is_manager(company_id) or (job_id is not null and private.can_job(company_id, job_id))) with check (private.is_manager(company_id) or (job_id is not null and private.can_job(company_id, job_id)));

drop policy if exists portal_selection_approvals_job_control on public.portal_selection_approvals;
create policy portal_selection_approvals_job_control on public.portal_selection_approvals for all to authenticated using (private.is_manager(company_id) or (job_id is not null and private.can_job(company_id, job_id))) with check (private.is_manager(company_id) or (job_id is not null and private.can_job(company_id, job_id)));

drop policy if exists portal_threads_job_control on public.portal_message_threads_deep;
create policy portal_threads_job_control on public.portal_message_threads_deep for all to authenticated using (private.is_manager(company_id) or (job_id is not null and private.can_job(company_id, job_id))) with check (private.is_manager(company_id) or (job_id is not null and private.can_job(company_id, job_id)));

drop policy if exists portal_entries_thread_control on public.portal_message_entries_deep;
create policy portal_entries_thread_control on public.portal_message_entries_deep for all to authenticated using (private.is_manager(company_id) or (job_id is not null and private.can_job(company_id, job_id))) with check (private.is_manager(company_id) or (job_id is not null and private.can_job(company_id, job_id)));

drop policy if exists portal_completion_job_control on public.portal_completion_signoffs;
create policy portal_completion_job_control on public.portal_completion_signoffs for all to authenticated using (private.is_manager(company_id) or (job_id is not null and private.can_job(company_id, job_id))) with check (private.is_manager(company_id) or (job_id is not null and private.can_job(company_id, job_id)));

drop policy if exists portal_activity_job_control on public.portal_activity_events_deep;
create policy portal_activity_job_control on public.portal_activity_events_deep for all to authenticated using (private.is_manager(company_id) or (job_id is not null and private.can_job(company_id, job_id))) with check (private.is_manager(company_id) or (job_id is not null and private.can_job(company_id, job_id)));