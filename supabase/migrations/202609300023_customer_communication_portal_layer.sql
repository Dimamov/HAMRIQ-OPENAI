-- HAMRIQ customer communication and portal layer
-- Adds customer communication hub, AI message drafts, customer portal sessions/events,
-- self-scheduling links, rep on-the-way events, no-show risk controls, and capture events.

create table if not exists public.customer_communication_threads (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  contact_id uuid,
  job_id uuid,
  channel text not null default 'sms',
  subject text,
  status text not null default 'open',
  assigned_to uuid,
  last_message_at timestamptz,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.customer_communication_messages (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  thread_id uuid not null references public.customer_communication_threads(id) on delete cascade,
  contact_id uuid,
  job_id uuid,
  direction text not null default 'outbound',
  channel text not null default 'sms',
  from_address text,
  to_address text,
  body text not null default '',
  delivery_status text not null default 'draft',
  provider_message_id text,
  sent_by uuid default auth.uid(),
  sent_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.ai_message_drafts (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  thread_id uuid references public.customer_communication_threads(id) on delete set null,
  contact_id uuid,
  job_id uuid,
  draft_type text not null default 'sms',
  prompt_context jsonb not null default '{}'::jsonb,
  draft_body text not null default '',
  tone text not null default 'professional',
  status text not null default 'drafted',
  approved_by uuid,
  approved_at timestamptz,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.customer_portal_sessions (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  contact_id uuid,
  job_id uuid,
  portal_token_id uuid references public.customer_portal_tokens(id) on delete set null,
  session_status text not null default 'active',
  last_seen_at timestamptz,
  device_summary text,
  created_at timestamptz not null default now(),
  expires_at timestamptz
);

create table if not exists public.customer_portal_events (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  session_id uuid references public.customer_portal_sessions(id) on delete set null,
  contact_id uuid,
  job_id uuid,
  event_type text not null,
  event_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.self_scheduling_links (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  contact_id uuid,
  job_id uuid,
  appointment_type text not null default 'inspection',
  token text not null,
  available_windows jsonb not null default '[]'::jsonb,
  status text not null default 'active',
  selected_start timestamptz,
  selected_end timestamptz,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  expires_at timestamptz,
  constraint self_scheduling_company_token_unique unique(company_id, token)
);

create table if not exists public.rep_on_the_way_events (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid,
  contact_id uuid,
  rep_id uuid not null default auth.uid(),
  eta_minutes integer,
  message_body text,
  status text not null default 'queued',
  sent_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.appointment_no_show_risk_events (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  appointment_id uuid,
  job_id uuid,
  contact_id uuid,
  risk_level text not null default 'normal',
  signals jsonb not null default '{}'::jsonb,
  suggested_action text,
  action_taken text,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.lead_capture_events (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  capture_source text not null default 'website',
  form_id uuid references public.lead_capture_forms(id) on delete set null,
  qr_code_id uuid references public.qr_codes(id) on delete set null,
  contact_id uuid,
  job_id uuid,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'received',
  processed_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists customer_comm_threads_company_idx on public.customer_communication_threads(company_id, status, last_message_at desc);
create index if not exists customer_comm_messages_thread_idx on public.customer_communication_messages(company_id, thread_id, created_at desc);
create index if not exists ai_message_drafts_job_idx on public.ai_message_drafts(company_id, job_id, status);
create index if not exists customer_portal_sessions_job_idx on public.customer_portal_sessions(company_id, job_id, session_status);
create index if not exists customer_portal_events_job_idx on public.customer_portal_events(company_id, job_id, created_at desc);
create index if not exists self_scheduling_links_job_idx on public.self_scheduling_links(company_id, job_id, status);
create index if not exists rep_on_the_way_job_idx on public.rep_on_the_way_events(company_id, job_id, created_at desc);
create index if not exists no_show_risk_job_idx on public.appointment_no_show_risk_events(company_id, job_id, risk_level);
create index if not exists lead_capture_events_company_idx on public.lead_capture_events(company_id, capture_source, status, created_at desc);

-- RLS is company and permitted-job scoped. Public token processing will be handled by edge functions/service role.
do $$ declare t text; begin
  foreach t in array array[
    'customer_communication_threads','customer_communication_messages','ai_message_drafts',
    'customer_portal_sessions','customer_portal_events','self_scheduling_links',
    'rep_on_the_way_events','appointment_no_show_risk_events','lead_capture_events'
  ] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on public.%I from anon, authenticated', t);
    execute format('grant select, insert, update on public.%I to authenticated', t);
  end loop;
end $$;

-- Policies use private.company_access, private.can_job, and private.is_manager helpers.
