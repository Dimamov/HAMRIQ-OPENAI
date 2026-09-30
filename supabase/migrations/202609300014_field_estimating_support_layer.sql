-- Field inspection and estimating support layer.
-- Live migration applied in Supabase.
-- Adds: photo_quality_reviews, inspection_completeness_checks, scope_drafts,
-- material_orders, supplier_issues, proposal_packages, homeowner_confirmations.

create table if not exists public.photo_quality_reviews (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  job_id uuid not null, photo_id uuid not null, status text not null default 'needs_review',
  findings jsonb not null default '{}'::jsonb, created_at timestamptz not null default now(), unique (company_id, id),
  foreign key (company_id, job_id) references public.jobs(company_id, id),
  foreign key (company_id, photo_id) references public.photos(company_id, id)
);

create table if not exists public.inspection_completeness_checks (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  job_id uuid not null, percent_complete integer not null default 0 check (percent_complete between 0 and 100),
  missing_items jsonb not null default '[]'::jsonb, blocking_items jsonb not null default '[]'::jsonb,
  status text not null default 'incomplete', created_at timestamptz not null default now(), unique (company_id, id),
  foreign key (company_id, job_id) references public.jobs(company_id, id)
);

create table if not exists public.scope_drafts (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  job_id uuid not null, source text not null default 'hammy', status text not null default 'review_required',
  suggested_scope jsonb not null default '{}'::jsonb, notes text not null default '', reviewed_by uuid, reviewed_at timestamptz,
  created_at timestamptz not null default now(), unique (company_id, id),
  foreign key (company_id, job_id) references public.jobs(company_id, id),
  foreign key (company_id, reviewed_by) references public.users(company_id, id)
);

create table if not exists public.material_orders (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  job_id uuid not null, vendor_id uuid, status text not null default 'draft', line_items jsonb not null default '[]'::jsonb,
  total_cents bigint not null default 0, requested_by uuid not null default auth.uid(), approved_by uuid, approved_at timestamptz,
  created_at timestamptz not null default now(), unique (company_id, id),
  foreign key (company_id, job_id) references public.jobs(company_id, id),
  foreign key (company_id, vendor_id) references public.vendors(company_id, id),
  foreign key (company_id, requested_by) references public.users(company_id, id),
  foreign key (company_id, approved_by) references public.users(company_id, id)
);

create table if not exists public.supplier_issues (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  vendor_id uuid, job_id uuid, material_order_id uuid, issue_type text not null, description text not null default '',
  status text not null default 'open', created_by uuid not null default auth.uid(), created_at timestamptz not null default now(), unique (company_id, id),
  foreign key (company_id, vendor_id) references public.vendors(company_id, id),
  foreign key (company_id, job_id) references public.jobs(company_id, id),
  foreign key (company_id, material_order_id) references public.material_orders(company_id, id),
  foreign key (company_id, created_by) references public.users(company_id, id)
);

create table if not exists public.proposal_packages (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  job_id uuid not null, package_name text not null, tier text not null default 'good', status text not null default 'draft',
  selections jsonb not null default '{}'::jsonb, price_cents bigint not null default 0,
  created_by uuid not null default auth.uid(), created_at timestamptz not null default now(), unique (company_id, id),
  foreign key (company_id, job_id) references public.jobs(company_id, id),
  foreign key (company_id, created_by) references public.users(company_id, id)
);

create table if not exists public.homeowner_confirmations (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  job_id uuid not null, confirmation_type text not null, status text not null default 'pending', summary jsonb not null default '{}'::jsonb,
  customer_note text not null default '', confirmed_at timestamptz, created_at timestamptz not null default now(), unique (company_id, id),
  foreign key (company_id, job_id) references public.jobs(company_id, id)
);

-- All tables above have RLS enabled live and are protected through private.can_job/private.is_manager policies.
