-- HAMRIQ insurance supplement execution layer
-- Adds carrier estimate intake, line-item comparison, supplement package review, adjuster communication, and recovery tracking.

create table if not exists public.carrier_estimate_uploads (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  uploaded_by uuid not null default auth.uid(),
  carrier_name text not null default '',
  adjuster_name text not null default '',
  claim_number text not null default '',
  document_record_id uuid null,
  file_name text not null default '',
  extraction_status text not null default 'pending' check (extraction_status in ('pending','processing','complete','failed','needs_review')),
  extracted_total_cents bigint not null default 0,
  extracted_line_count integer not null default 0,
  extraction_summary jsonb not null default '{}'::jsonb,
  received_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, id)
);

create table if not exists public.carrier_estimate_line_items (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  carrier_estimate_upload_id uuid not null,
  job_id uuid not null,
  source_line_number integer null,
  trade text not null default 'roofing',
  item_code text not null default '',
  description text not null default '',
  quantity numeric(12,2) not null default 0,
  unit text not null default '',
  unit_price_cents bigint not null default 0,
  total_price_cents bigint not null default 0,
  depreciation_cents bigint not null default 0,
  recoverable_depreciation_cents bigint not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint carrier_estimate_line_upload_fk foreign key (company_id, carrier_estimate_upload_id) references public.carrier_estimate_uploads(company_id, id) on delete cascade
);

create table if not exists public.estimate_comparison_runs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  carrier_estimate_upload_id uuid not null,
  hamriq_estimate_id uuid null,
  run_by uuid not null default auth.uid(),
  status text not null default 'draft' check (status in ('draft','ready_for_review','approved','rejected','superseded')),
  carrier_total_cents bigint not null default 0,
  hamriq_total_cents bigint not null default 0,
  missing_total_cents bigint not null default 0,
  underpaid_total_cents bigint not null default 0,
  summary jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, id),
  constraint estimate_comparison_upload_fk foreign key (company_id, carrier_estimate_upload_id) references public.carrier_estimate_uploads(company_id, id) on delete cascade
);

create table if not exists public.estimate_comparison_findings (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  comparison_run_id uuid not null,
  job_id uuid not null,
  finding_type text not null default 'missing_item' check (finding_type in ('missing_item','underpaid_item','quantity_difference','code_difference','documentation_needed','other')),
  severity text not null default 'medium' check (severity in ('low','medium','high','critical')),
  carrier_line_item_id uuid null,
  hamriq_reference jsonb not null default '{}'::jsonb,
  title text not null,
  explanation text not null default '',
  suggested_amount_cents bigint not null default 0,
  evidence_needed jsonb not null default '[]'::jsonb,
  status text not null default 'open' check (status in ('open','accepted','rejected','needs_more_evidence','resolved')),
  manager_note text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint estimate_comparison_findings_run_fk foreign key (company_id, comparison_run_id) references public.estimate_comparison_runs(company_id, id) on delete cascade
);

create table if not exists public.supplement_packages (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  comparison_run_id uuid not null,
  created_by uuid not null default auth.uid(),
  package_number integer not null default 1,
  status text not null default 'draft' check (status in ('draft','review_needed','approved','sent','carrier_responded','accepted','partially_accepted','denied','closed')),
  requested_total_cents bigint not null default 0,
  approved_total_cents bigint not null default 0,
  narrative text not null default '',
  evidence_summary jsonb not null default '{}'::jsonb,
  sent_at timestamptz null,
  carrier_response_due_at timestamptz null,
  closed_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, id),
  constraint supplement_packages_run_fk foreign key (company_id, comparison_run_id) references public.estimate_comparison_runs(company_id, id) on delete cascade
);

create table if not exists public.supplement_package_items (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  supplement_package_id uuid not null,
  comparison_finding_id uuid null,
  job_id uuid not null,
  item_title text not null,
  item_description text not null default '',
  requested_amount_cents bigint not null default 0,
  approved_amount_cents bigint not null default 0,
  status text not null default 'included' check (status in ('included','removed','approved','partially_approved','denied')),
  evidence jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  constraint supplement_items_package_fk foreign key (company_id, supplement_package_id) references public.supplement_packages(company_id, id) on delete cascade
);

create table if not exists public.supplement_review_approvals (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  supplement_package_id uuid not null,
  job_id uuid not null,
  reviewer_id uuid not null default auth.uid(),
  decision text not null check (decision in ('approved','rejected','changes_requested')),
  review_note text not null default '',
  reviewed_at timestamptz not null default now(),
  constraint supplement_review_package_fk foreign key (company_id, supplement_package_id) references public.supplement_packages(company_id, id) on delete cascade
);

create table if not exists public.adjuster_communication_events (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  supplement_package_id uuid null,
  carrier_adjuster_id uuid null,
  direction text not null check (direction in ('outbound','inbound')),
  channel text not null default 'email' check (channel in ('email','sms','phone','portal','other')),
  subject text not null default '',
  summary text not null default '',
  body_preview text not null default '',
  sent_by uuid null,
  received_by uuid null,
  status text not null default 'logged' check (status in ('draft','sent','delivered','failed','received','logged')),
  occurred_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint adjuster_comm_package_fk foreign key (company_id, supplement_package_id) references public.supplement_packages(company_id, id) on delete set null
);

create table if not exists public.supplement_recovery_snapshots (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  supplement_package_id uuid null,
  requested_total_cents bigint not null default 0,
  approved_total_cents bigint not null default 0,
  collected_total_cents bigint not null default 0,
  outstanding_total_cents bigint generated always as (greatest(approved_total_cents - collected_total_cents, 0)) stored,
  snapshot_date date not null default current_date,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  constraint supplement_recovery_package_fk foreign key (company_id, supplement_package_id) references public.supplement_packages(company_id, id) on delete set null
);

-- Indexes, RLS grants, and policies are included in the live Supabase migration.
