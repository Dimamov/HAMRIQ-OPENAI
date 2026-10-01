-- HAMRIQ proposal / estimate presentation layer
-- Supports good-better-best proposal packaging, homeowner views, product confirmations,
-- estimate approvals, and pricing override audits.

create table if not exists public.proposal_packages_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid references public.jobs(id),
  contact_id uuid references public.contacts(id),
  title text not null default 'Roofing Proposal',
  package_status text not null default 'draft' check (package_status in ('draft','sent','viewed','approved','rejected','expired','archived')),
  good_option_cents bigint not null default 0,
  better_option_cents bigint not null default 0,
  best_option_cents bigint not null default 0,
  recommended_tier text not null default 'better' check (recommended_tier in ('good','better','best')),
  ai_summary text not null default '',
  expires_at timestamptz,
  sent_at timestamptz,
  approved_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.proposal_sections (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  proposal_package_id uuid not null references public.proposal_packages_deep(id) on delete cascade,
  section_order integer not null default 0,
  section_type text not null default 'scope',
  heading text not null default '',
  body text not null default '',
  is_locked boolean not null default false,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.proposal_option_items (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  proposal_package_id uuid not null references public.proposal_packages_deep(id) on delete cascade,
  tier text not null check (tier in ('good','better','best')),
  item_order integer not null default 0,
  item_name text not null,
  item_description text not null default '',
  included boolean not null default true,
  amount_cents bigint not null default 0,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.homeowner_proposal_views (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  proposal_package_id uuid not null references public.proposal_packages_deep(id) on delete cascade,
  job_id uuid references public.jobs(id),
  contact_id uuid references public.contacts(id),
  viewed_at timestamptz not null default now(),
  viewer_name text not null default '',
  view_source text not null default 'link',
  duration_seconds integer not null default 0,
  selected_tier text check (selected_tier in ('good','better','best')),
  device_context jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.estimate_approval_requests (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid references public.jobs(id),
  proposal_package_id uuid references public.proposal_packages_deep(id),
  requested_by uuid not null default auth.uid(),
  assigned_manager_id uuid,
  approval_status text not null default 'pending',
  requested_amount_cents bigint not null default 0,
  approved_amount_cents bigint,
  reason text not null default '',
  manager_notes text not null default '',
  decided_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.product_selection_confirmations (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid references public.jobs(id),
  proposal_package_id uuid references public.proposal_packages_deep(id),
  selection_type text not null default 'shingle_color',
  selected_value text not null default '',
  confirmed_by_name text not null default '',
  confirmed_at timestamptz,
  confirmation_source text not null default 'rep',
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.pricing_override_audits (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid references public.jobs(id),
  proposal_package_id uuid references public.proposal_packages_deep(id),
  override_type text not null default 'discount',
  original_amount_cents bigint not null default 0,
  new_amount_cents bigint not null default 0,
  reason text not null default '',
  requires_manager_approval boolean not null default true,
  approval_status text not null default 'pending',
  created_by uuid not null default auth.uid(),
  approved_by uuid,
  approved_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_proposal_packages_deep_company_job on public.proposal_packages_deep(company_id, job_id);
create index if not exists idx_proposal_sections_package on public.proposal_sections(company_id, proposal_package_id);
create index if not exists idx_proposal_option_items_package on public.proposal_option_items(company_id, proposal_package_id, tier);
create index if not exists idx_homeowner_proposal_views_package on public.homeowner_proposal_views(company_id, proposal_package_id);
create index if not exists idx_estimate_approval_requests_job on public.estimate_approval_requests(company_id, job_id, approval_status);
create index if not exists idx_product_selection_confirmations_job on public.product_selection_confirmations(company_id, job_id);
create index if not exists idx_pricing_override_audits_job on public.pricing_override_audits(company_id, job_id, approval_status);

alter table public.proposal_packages_deep enable row level security;
alter table public.proposal_sections enable row level security;
alter table public.proposal_option_items enable row level security;
alter table public.homeowner_proposal_views enable row level security;
alter table public.estimate_approval_requests enable row level security;
alter table public.product_selection_confirmations enable row level security;
alter table public.pricing_override_audits enable row level security;

revoke all on public.proposal_packages_deep from anon, authenticated;
revoke all on public.proposal_sections from anon, authenticated;
revoke all on public.proposal_option_items from anon, authenticated;
revoke all on public.homeowner_proposal_views from anon, authenticated;
revoke all on public.estimate_approval_requests from anon, authenticated;
revoke all on public.product_selection_confirmations from anon, authenticated;
revoke all on public.pricing_override_audits from anon, authenticated;

grant select, insert, update on public.proposal_packages_deep to authenticated;
grant select, insert, update on public.proposal_sections to authenticated;
grant select, insert, update on public.proposal_option_items to authenticated;
grant select, insert, update on public.homeowner_proposal_views to authenticated;
grant select, insert, update on public.estimate_approval_requests to authenticated;
grant select, insert, update on public.product_selection_confirmations to authenticated;
grant select, insert, update on public.pricing_override_audits to authenticated;

-- Live project policies are job/company scoped through private.company_access, private.can_job, and private.is_manager.
