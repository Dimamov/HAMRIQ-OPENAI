-- HAMRIQ marketing/referral/reputation deep layer
-- Adds referral rewards, reputation monitoring, NPS/satisfaction, complaint escalation,
-- neighborhood campaigns, and direct-mail fulfillment controls.

create table if not exists public.referral_reward_programs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null,
  reward_type text not null default 'cash',
  reward_amount_cents bigint not null default 0,
  reward_rules jsonb not null default '{}'::jsonb,
  active boolean not null default true,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.referral_reward_events (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  program_id uuid references public.referral_reward_programs(id) on delete set null,
  referral_id uuid references public.referrals(id) on delete set null,
  referring_contact_id uuid,
  referred_contact_id uuid,
  job_id uuid,
  event_type text not null default 'earned',
  reward_amount_cents bigint not null default 0,
  status text not null default 'pending',
  approved_by uuid,
  approved_at timestamptz,
  paid_at timestamptz,
  notes text,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.reputation_monitoring_items (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  source text not null,
  external_review_id text,
  reviewer_name text,
  rating numeric(3,2),
  review_text text,
  sentiment text not null default 'unreviewed',
  response_status text not null default 'not_needed',
  response_draft text,
  manager_review_required boolean not null default false,
  reviewed_by uuid,
  reviewed_at timestamptz,
  source_url text,
  received_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.nps_survey_responses (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  contact_id uuid,
  job_id uuid,
  score integer not null check (score between 0 and 10),
  feedback text,
  survey_source text not null default 'post_completion',
  detractor_followup_status text not null default 'not_needed',
  promoter_referral_status text not null default 'not_requested',
  submitted_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.complaint_escalation_cases (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  complaint_id uuid references public.customer_complaints(id) on delete set null,
  contact_id uuid,
  job_id uuid,
  severity text not null default 'medium',
  status text not null default 'open',
  escalation_reason text not null,
  assigned_manager_id uuid,
  resolution_summary text,
  resolved_at timestamptz,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.neighborhood_campaigns (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null,
  campaign_type text not null default 'jobs_near_you',
  storm_event_id uuid references public.storm_events(id) on delete set null,
  territory_id uuid references public.territories(id) on delete set null,
  target_area jsonb not null default '{}'::jsonb,
  audience_rules jsonb not null default '{}'::jsonb,
  message_template text,
  status text not null default 'draft',
  created_by uuid default auth.uid(),
  launched_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.neighborhood_campaign_recipients (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  campaign_id uuid not null references public.neighborhood_campaigns(id) on delete cascade,
  contact_id uuid,
  property_id uuid references public.properties(id) on delete set null,
  address_text text,
  status text not null default 'queued',
  sent_at timestamptz,
  response_status text not null default 'none',
  created_at timestamptz not null default now()
);

create table if not exists public.direct_mail_fulfillment_jobs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  campaign_id uuid references public.direct_mail_campaigns(id) on delete set null,
  neighborhood_campaign_id uuid references public.neighborhood_campaigns(id) on delete set null,
  provider text not null default 'manual',
  provider_order_id text,
  piece_count integer not null default 0,
  estimated_cost_cents bigint not null default 0,
  final_cost_cents bigint not null default 0,
  status text not null default 'draft',
  manager_approved_by uuid,
  manager_approved_at timestamptz,
  submitted_at timestamptz,
  completed_at timestamptz,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);

-- See live database migration for foreign keys, RLS grants, and policies.
