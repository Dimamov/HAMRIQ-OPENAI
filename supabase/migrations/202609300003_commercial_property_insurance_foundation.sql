-- HAMRIQ approved commercial, property, and insurance foundation.
-- Applied live to Supabase project baxgnpnfpzashcgiibwg.

alter table public.contacts add column if not exists account_type text not null default 'Residential';
alter table public.jobs add column if not exists property_id uuid;
alter table public.jobs add column if not exists workflow_type text not null default 'Residential';
alter table public.jobs add column if not exists readiness_status text not null default 'Not Ready';
alter table public.jobs add column if not exists readiness_blockers jsonb not null default '[]'::jsonb;

create table if not exists public.properties (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  contact_id uuid not null,
  name text not null default '',
  address text not null,
  city text not null default '',
  state text not null default 'MI',
  zip text not null default '',
  property_type text not null default 'Residential',
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,contact_id) references public.contacts(company_id,id),
  foreign key(created_by) references public.users(id)
);

create table if not exists public.roof_assets (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  property_id uuid not null,
  label text not null,
  roof_system text not null default '',
  installed_on date,
  approximate_age_years integer,
  warranty text not null default '',
  condition text not null default 'Unknown',
  planned_replacement_year integer,
  notes text not null default '',
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,property_id) references public.properties(company_id,id)
);

create table if not exists public.maintenance_agreements (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  property_id uuid not null,
  name text not null,
  cadence text not null default 'Annual',
  scope jsonb not null default '[]'::jsonb,
  status text not null default 'active',
  starts_on date,
  renews_on date,
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,property_id) references public.properties(company_id,id)
);

create table if not exists public.commercial_bids (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  property_id uuid,
  contact_id uuid not null,
  title text not null,
  status text not null default 'invited',
  bid_due_at timestamptz,
  estimator_id uuid,
  plans_path text not null default '',
  specs_path text not null default '',
  addenda jsonb not null default '[]'::jsonb,
  notes text not null default '',
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,contact_id) references public.contacts(company_id,id),
  foreign key(company_id,property_id) references public.properties(company_id,id),
  foreign key(estimator_id) references public.users(id)
);

create table if not exists public.carrier_adjusters (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  carrier text not null,
  adjuster_name text not null default '',
  adjuster_email text not null default '',
  adjuster_phone text not null default '',
  preferred_contact text not null default '',
  notes text not null default '',
  created_at timestamptz not null default now(),
  unique(company_id,id)
);

alter table public.claims add column if not exists carrier_adjuster_id uuid;
alter table public.claims add column if not exists claim_timeline jsonb not null default '[]'::jsonb;
alter table public.claims add column if not exists expected_carrier_funds_cents bigint not null default 0;
alter table public.claims add column if not exists received_carrier_funds_cents bigint not null default 0;
alter table public.claims add column if not exists outstanding_depreciation_cents bigint not null default 0;
alter table public.claims add column if not exists outstanding_supplement_cents bigint not null default 0;

create table if not exists public.insurance_document_extractions (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  claim_id uuid not null,
  document_path text not null,
  extracted_values jsonb not null default '{}'::jsonb,
  status text not null default 'needs_review',
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,claim_id) references public.claims(company_id,id),
  foreign key(reviewed_by) references public.users(id)
);

create table if not exists public.carrier_payments (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  claim_id uuid not null,
  amount_cents bigint not null check (amount_cents >= 0),
  payment_type text not null default 'carrier',
  received_on date not null default current_date,
  reference text not null default '',
  notes text not null default '',
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,claim_id) references public.claims(company_id,id)
);
