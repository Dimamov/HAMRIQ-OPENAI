-- HAMRIQ supplement evidence builder / recovery intelligence execution layer
-- Live database migration applied in Supabase. Database is source of truth.

create table if not exists public.supplement_evidence_packets_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  packet_title text not null default 'Supplement Evidence Packet',
  packet_status text not null default 'draft',
  claim_number text,
  carrier_name text,
  adjuster_name text,
  total_requested_cents bigint not null default 0,
  total_approved_cents bigint not null default 0,
  evidence_summary text,
  ai_generated_summary text,
  manager_review_required boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.supplement_missing_line_support_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  evidence_packet_id uuid references public.supplement_evidence_packets_deep(id) on delete cascade,
  line_item_code text,
  line_item_name text not null,
  issue_type text not null default 'missing',
  hamriq_amount_cents bigint not null default 0,
  carrier_amount_cents bigint not null default 0,
  requested_amount_cents bigint not null default 0,
  support_reason text,
  confidence_score numeric(5,2) not null default 0,
  review_status text not null default 'pending_review',
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.supplement_photo_evidence_links_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  evidence_packet_id uuid references public.supplement_evidence_packets_deep(id) on delete cascade,
  support_line_id uuid references public.supplement_missing_line_support_deep(id) on delete cascade,
  photo_record_id uuid,
  photo_url text,
  photo_area text,
  evidence_type text not null default 'damage',
  ai_observation text,
  human_caption text,
  included_in_packet boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.supplement_document_evidence_links_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  evidence_packet_id uuid references public.supplement_evidence_packets_deep(id) on delete cascade,
  support_line_id uuid references public.supplement_missing_line_support_deep(id) on delete cascade,
  document_record_id uuid,
  document_url text,
  document_type text not null default 'carrier_estimate',
  extracted_text_summary text,
  included_in_packet boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.supplement_code_justification_records_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  evidence_packet_id uuid references public.supplement_evidence_packets_deep(id) on delete cascade,
  support_line_id uuid references public.supplement_missing_line_support_deep(id) on delete cascade,
  jurisdiction text,
  code_source text,
  code_section text,
  justification_summary text not null,
  citation_url text,
  verification_status text not null default 'needs_verification',
  verified_by uuid,
  verified_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.supplement_review_approval_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  evidence_packet_id uuid references public.supplement_evidence_packets_deep(id) on delete cascade,
  approval_status text not null default 'pending',
  reviewer_user_id uuid,
  reviewed_at timestamptz,
  approval_notes text,
  send_to_adjuster boolean not null default false,
  send_to_homeowner boolean not null default false,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.supplement_recovery_analytics_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id),
  evidence_packet_id uuid references public.supplement_evidence_packets_deep(id) on delete set null,
  requested_total_cents bigint not null default 0,
  approved_total_cents bigint not null default 0,
  denied_total_cents bigint not null default 0,
  recovery_rate numeric(5,2) not null default 0,
  carrier_response_days integer,
  high_value_items jsonb not null default '[]'::jsonb,
  lessons_learned text,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.supplement_evidence_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id),
  evidence_packet_id uuid references public.supplement_evidence_packets_deep(id) on delete set null,
  event_type text not null,
  event_summary text,
  actor_user_id uuid default auth.uid(),
  event_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.supplement_evidence_packets_deep enable row level security;
alter table public.supplement_missing_line_support_deep enable row level security;
alter table public.supplement_photo_evidence_links_deep enable row level security;
alter table public.supplement_document_evidence_links_deep enable row level security;
alter table public.supplement_code_justification_records_deep enable row level security;
alter table public.supplement_review_approval_runs_deep enable row level security;
alter table public.supplement_recovery_analytics_deep enable row level security;
alter table public.supplement_evidence_activity_events_deep enable row level security;

-- Policies are applied in the live Supabase migration using company-scoped RLS helpers.