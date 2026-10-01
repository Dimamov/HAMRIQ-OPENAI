create table if not exists public.call_consent_records (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid,
  contact_id uuid,
  call_direction text not null default 'outbound' check (call_direction in ('inbound','outbound')),
  phone_number text not null default '',
  consent_status text not null default 'not_requested' check (consent_status in ('not_requested','granted','declined','revoked')),
  consent_language text not null default '',
  consent_captured_at timestamptz,
  consent_revoked_at timestamptz,
  captured_by uuid default auth.uid(),
  legal_notice text not null default 'Call recording and AI summary features require proper customer consent and compliance with applicable laws.',
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.call_recording_assets (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid,
  contact_id uuid,
  consent_record_id uuid,
  phone_call_log_id uuid,
  storage_path text not null default '',
  recording_status text not null default 'pending' check (recording_status in ('pending','recording','available','failed','deleted')),
  duration_seconds integer not null default 0,
  transcript_status text not null default 'not_started' check (transcript_status in ('not_started','queued','complete','failed')),
  transcript_text text not null default '',
  failure_reason text not null default '',
  recorded_by uuid default auth.uid(),
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ai_call_summary_records (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid,
  call_recording_asset_id uuid,
  summary_status text not null default 'draft' check (summary_status in ('draft','review_needed','approved','rejected')),
  summary_text text not null default '',
  customer_commitments jsonb not null default '[]'::jsonb,
  rep_commitments jsonb not null default '[]'::jsonb,
  detected_objections jsonb not null default '[]'::jsonb,
  recommended_next_steps jsonb not null default '[]'::jsonb,
  requires_human_review boolean not null default true,
  reviewed_by uuid,
  reviewed_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.outbound_message_send_logs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid,
  contact_id uuid,
  template_id uuid,
  channel text not null default 'sms' check (channel in ('sms','email','voice','push')),
  recipient text not null default '',
  subject text not null default '',
  body_preview text not null default '',
  send_status text not null default 'draft' check (send_status in ('draft','queued','sent','failed','canceled','blocked')),
  blocked_reason text not null default '',
  provider_message_id text not null default '',
  sent_by uuid default auth.uid(),
  sent_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.message_delivery_events (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  outbound_message_id uuid,
  provider_message_id text not null default '',
  delivery_status text not null default 'unknown' check (delivery_status in ('unknown','queued','sent','delivered','opened','clicked','bounced','failed','unsubscribed','replied')),
  event_time timestamptz not null default now(),
  raw_payload jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.communication_opt_outs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  contact_id uuid,
  channel text not null default 'sms' check (channel in ('sms','email','voice','push','all')),
  destination text not null default '',
  opt_out_status text not null default 'active' check (opt_out_status in ('active','revoked')),
  source text not null default 'manual',
  reason text not null default '',
  opted_out_at timestamptz not null default now(),
  revoked_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.appointment_confirmation_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid,
  appointment_id uuid,
  contact_id uuid,
  confirmation_type text not null default 'inspection' check (confirmation_type in ('inspection','adjuster','contract_review','production','service','other')),
  scheduled_for timestamptz,
  confirmation_status text not null default 'pending' check (confirmation_status in ('pending','sent','confirmed','rescheduled','canceled','no_response','failed')),
  response_text text not null default '',
  no_show_risk_score numeric(5,2),
  next_attempt_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.self_scheduling_booking_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid,
  contact_id uuid,
  scheduling_link_id uuid,
  booking_status text not null default 'started' check (booking_status in ('started','selected_time','booked','rescheduled','canceled','expired')),
  selected_start_time timestamptz,
  selected_end_time timestamptz,
  timezone text not null default 'America/Detroit',
  customer_notes text not null default '',
  booking_source text not null default 'customer_portal',
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists call_consent_records_company_job_idx on public.call_consent_records(company_id, job_id);
create index if not exists call_recording_assets_company_job_idx on public.call_recording_assets(company_id, job_id);
create index if not exists ai_call_summary_records_company_job_idx on public.ai_call_summary_records(company_id, job_id);
create index if not exists outbound_message_send_logs_company_job_idx on public.outbound_message_send_logs(company_id, job_id);
create index if not exists message_delivery_events_company_message_idx on public.message_delivery_events(company_id, outbound_message_id);
create index if not exists communication_opt_outs_company_contact_idx on public.communication_opt_outs(company_id, contact_id);
create index if not exists appointment_confirmation_runs_deep_company_job_idx on public.appointment_confirmation_runs_deep(company_id, job_id);
create index if not exists self_scheduling_booking_events_deep_company_job_idx on public.self_scheduling_booking_events_deep(company_id, job_id);

alter table public.call_consent_records enable row level security;
alter table public.call_recording_assets enable row level security;
alter table public.ai_call_summary_records enable row level security;
alter table public.outbound_message_send_logs enable row level security;
alter table public.message_delivery_events enable row level security;
alter table public.communication_opt_outs enable row level security;
alter table public.appointment_confirmation_runs_deep enable row level security;
alter table public.self_scheduling_booking_events_deep enable row level security;

revoke all on public.call_consent_records from anon, authenticated;
revoke all on public.call_recording_assets from anon, authenticated;
revoke all on public.ai_call_summary_records from anon, authenticated;
revoke all on public.outbound_message_send_logs from anon, authenticated;
revoke all on public.message_delivery_events from anon, authenticated;
revoke all on public.communication_opt_outs from anon, authenticated;
revoke all on public.appointment_confirmation_runs_deep from anon, authenticated;
revoke all on public.self_scheduling_booking_events_deep from anon, authenticated;

grant select, insert, update on public.call_consent_records to authenticated;
grant select, insert, update on public.call_recording_assets to authenticated;
grant select, insert, update on public.ai_call_summary_records to authenticated;
grant select, insert, update on public.outbound_message_send_logs to authenticated;
grant select, insert, update on public.message_delivery_events to authenticated;
grant select, insert, update on public.communication_opt_outs to authenticated;
grant select, insert, update on public.appointment_confirmation_runs_deep to authenticated;
grant select, insert, update on public.self_scheduling_booking_events_deep to authenticated;

drop policy if exists call_consent_records_company_access on public.call_consent_records;
create policy call_consent_records_company_access on public.call_consent_records
  for all to authenticated
  using (private.company_access(company_id) and (job_id is null or private.can_job(company_id, job_id)))
  with check (private.company_access(company_id) and (job_id is null or private.can_job(company_id, job_id)));

drop policy if exists call_recording_assets_company_access on public.call_recording_assets;
create policy call_recording_assets_company_access on public.call_recording_assets
  for all to authenticated
  using (private.company_access(company_id) and (job_id is null or private.can_job(company_id, job_id)))
  with check (private.company_access(company_id) and (job_id is null or private.can_job(company_id, job_id)));

drop policy if exists ai_call_summary_records_company_access on public.ai_call_summary_records;
create policy ai_call_summary_records_company_access on public.ai_call_summary_records
  for all to authenticated
  using (private.company_access(company_id) and (job_id is null or private.can_job(company_id, job_id)))
  with check (private.company_access(company_id) and (job_id is null or private.can_job(company_id, job_id)));

drop policy if exists outbound_message_send_logs_company_access on public.outbound_message_send_logs;
create policy outbound_message_send_logs_company_access on public.outbound_message_send_logs
  for all to authenticated
  using (private.company_access(company_id) and (job_id is null or private.can_job(company_id, job_id)))
  with check (private.company_access(company_id) and (job_id is null or private.can_job(company_id, job_id)));

drop policy if exists message_delivery_events_company_access on public.message_delivery_events;
create policy message_delivery_events_company_access on public.message_delivery_events
  for all to authenticated
  using (private.company_access(company_id))
  with check (private.company_access(company_id));

drop policy if exists communication_opt_outs_company_access on public.communication_opt_outs;
create policy communication_opt_outs_company_access on public.communication_opt_outs
  for all to authenticated
  using (private.company_access(company_id))
  with check (private.company_access(company_id));

drop policy if exists appointment_confirmation_runs_deep_company_access on public.appointment_confirmation_runs_deep;
create policy appointment_confirmation_runs_deep_company_access on public.appointment_confirmation_runs_deep
  for all to authenticated
  using (private.company_access(company_id) and (job_id is null or private.can_job(company_id, job_id)))
  with check (private.company_access(company_id) and (job_id is null or private.can_job(company_id, job_id)));

drop policy if exists self_scheduling_booking_events_deep_company_access on public.self_scheduling_booking_events_deep;
create policy self_scheduling_booking_events_deep_company_access on public.self_scheduling_booking_events_deep
  for all to authenticated
  using (private.company_access(company_id) and (job_id is null or private.can_job(company_id, job_id)))
  with check (private.company_access(company_id) and (job_id is null or private.can_job(company_id, job_id)));
