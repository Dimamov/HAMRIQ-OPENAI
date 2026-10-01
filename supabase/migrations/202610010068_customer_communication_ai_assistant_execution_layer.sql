-- HAMRIQ customer communication hub + AI email/text assistant execution layer
-- Adds communication timeline, AI drafts, templates, follow-up sequences, rep-on-the-way, consent/opt-out, and delivery tracking.

create table if not exists public.communication_thread_hub_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid null references public.jobs(id) on delete set null,
  contact_id uuid null references public.contacts(id) on delete set null,
  thread_type text not null default 'customer' check (thread_type in ('customer','adjuster','internal','vendor','crew','portal','other')),
  subject text not null default '',
  status text not null default 'open' check (status in ('open','waiting_on_customer','waiting_on_company','escalated','closed','archived')),
  assigned_user_id uuid null,
  last_message_at timestamptz null,
  last_customer_response_at timestamptz null,
  unread_count integer not null default 0,
  manager_review_required boolean not null default false,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.communication_message_timeline_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  thread_id uuid not null references public.communication_thread_hub_deep(id) on delete cascade,
  job_id uuid null references public.jobs(id) on delete set null,
  contact_id uuid null references public.contacts(id) on delete set null,
  channel text not null check (channel in ('sms','email','call','voicemail','portal','internal_note','system')),
  direction text not null check (direction in ('inbound','outbound','internal','system')),
  sender_user_id uuid null,
  body text not null default '',
  ai_generated boolean not null default false,
  requires_review boolean not null default false,
  delivery_status text not null default 'draft' check (delivery_status in ('draft','queued','sent','delivered','opened','clicked','failed','received','logged')),
  provider_message_id text null,
  attachments jsonb not null default '[]'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.ai_email_text_draft_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  thread_id uuid null references public.communication_thread_hub_deep(id) on delete set null,
  job_id uuid null references public.jobs(id) on delete set null,
  contact_id uuid null references public.contacts(id) on delete set null,
  requested_by uuid not null default auth.uid(),
  draft_type text not null default 'reply' check (draft_type in ('reply','followup','appointment_confirmation','rep_on_the_way','review_request','claim_update','payment_reminder','custom')),
  prompt_summary text not null default '',
  draft_body text not null default '',
  tone text not null default 'professional',
  status text not null default 'drafted' check (status in ('drafted','edited','approved','rejected','sent','discarded')),
  human_review_required boolean not null default true,
  approved_by uuid null,
  approved_at timestamptz null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.communication_template_library_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  template_name text not null,
  category text not null default 'general' check (category in ('general','inspection','estimate','claim','supplement','production','payment','review','service','past_customer','other')),
  channel text not null default 'sms' check (channel in ('sms','email','portal','call_script')),
  subject text not null default '',
  body text not null default '',
  is_active boolean not null default true,
  manager_approved boolean not null default false,
  merge_fields jsonb not null default '[]'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.customer_followup_sequence_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid null references public.jobs(id) on delete cascade,
  contact_id uuid null references public.contacts(id) on delete set null,
  sequence_name text not null,
  sequence_type text not null default 'followup' check (sequence_type in ('lead_nurture','estimate_followup','claim_followup','production_update','payment_reminder','review_request','past_customer','custom')),
  assigned_user_id uuid null,
  current_step integer not null default 0,
  status text not null default 'active' check (status in ('active','paused','completed','cancelled','failed')),
  next_send_at timestamptz null,
  customer_replied_at timestamptz null,
  escalation_required boolean not null default false,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.rep_on_the_way_message_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid null references public.jobs(id) on delete cascade,
  contact_id uuid null references public.contacts(id) on delete set null,
  appointment_id uuid null,
  rep_user_id uuid not null default auth.uid(),
  estimated_arrival_at timestamptz null,
  message_body text not null default '',
  status text not null default 'draft' check (status in ('draft','queued','sent','delivered','failed','cancelled')),
  location_shared boolean not null default false,
  provider_message_id text null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.communication_opt_out_consent_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  contact_id uuid null references public.contacts(id) on delete cascade,
  phone text null,
  email text null,
  channel text not null check (channel in ('sms','email','call','all')),
  consent_status text not null default 'unknown' check (consent_status in ('unknown','opted_in','opted_out','do_not_contact','transactional_only')),
  consent_source text not null default 'manual',
  consent_recorded_at timestamptz not null default now(),
  recorded_by uuid not null default auth.uid(),
  notes text not null default '',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.communication_delivery_tracking_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  message_id uuid null references public.communication_message_timeline_deep(id) on delete cascade,
  channel text not null check (channel in ('sms','email','portal','call')),
  event_type text not null check (event_type in ('queued','sent','delivered','opened','clicked','bounced','failed','replied','unsubscribed')),
  event_at timestamptz not null default now(),
  provider_event_id text null,
  provider_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_comm_thread_company_job on public.communication_thread_hub_deep(company_id, job_id);
create index if not exists idx_comm_thread_assigned on public.communication_thread_hub_deep(company_id, assigned_user_id);
create index if not exists idx_comm_msg_thread on public.communication_message_timeline_deep(company_id, thread_id, created_at desc);
create index if not exists idx_ai_draft_company_job on public.ai_email_text_draft_runs_deep(company_id, job_id);
create index if not exists idx_template_company_category on public.communication_template_library_deep(company_id, category);
create index if not exists idx_sequence_company_next on public.customer_followup_sequence_runs_deep(company_id, next_send_at);
create index if not exists idx_oty_company_rep on public.rep_on_the_way_message_runs_deep(company_id, rep_user_id);
create index if not exists idx_optout_company_contact on public.communication_opt_out_consent_deep(company_id, contact_id);
create index if not exists idx_delivery_company_message on public.communication_delivery_tracking_deep(company_id, message_id);

alter table public.communication_thread_hub_deep enable row level security;
alter table public.communication_message_timeline_deep enable row level security;
alter table public.ai_email_text_draft_runs_deep enable row level security;
alter table public.communication_template_library_deep enable row level security;
alter table public.customer_followup_sequence_runs_deep enable row level security;
alter table public.rep_on_the_way_message_runs_deep enable row level security;
alter table public.communication_opt_out_consent_deep enable row level security;
alter table public.communication_delivery_tracking_deep enable row level security;