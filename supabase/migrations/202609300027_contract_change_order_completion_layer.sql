-- HAMRIQ contract/change-order/completion layer
-- Adds build contracts, locked template language, e-sign requests, change orders, contract versions, and completion certificates.

create table if not exists public.contract_templates (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null,
  contract_type text not null default 'build_contract',
  version_number integer not null default 1,
  legal_language text not null default '',
  scope_language text not null default '',
  locked boolean not null default true,
  active boolean not null default true,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.job_contracts (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  contact_id uuid,
  template_id uuid references public.contract_templates(id),
  contract_type text not null default 'build_contract',
  status text not null default 'draft',
  contract_number text,
  subtotal_cents bigint not null default 0,
  tax_cents bigint not null default 0,
  total_cents bigint not null default 0,
  scope_snapshot jsonb not null default '{}'::jsonb,
  product_selections_snapshot jsonb not null default '{}'::jsonb,
  legal_language_snapshot text not null default '',
  scope_language_snapshot text not null default '',
  locked_for_rep_edit boolean not null default true,
  sent_at timestamptz,
  signed_at timestamptz,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint job_contracts_job_fk foreign key (company_id, job_id) references public.jobs(company_id, id) on delete cascade,
  constraint job_contracts_contact_fk foreign key (company_id, contact_id) references public.contacts(company_id, id) on delete set null
);

create table if not exists public.contract_versions (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  contract_id uuid not null references public.job_contracts(id) on delete cascade,
  job_id uuid not null,
  version_number integer not null,
  change_summary text not null default '',
  contract_snapshot jsonb not null default '{}'::jsonb,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  constraint contract_versions_job_fk foreign key (company_id, job_id) references public.jobs(company_id, id) on delete cascade
);

create table if not exists public.esign_requests (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  contact_id uuid,
  contract_id uuid references public.job_contracts(id) on delete cascade,
  change_order_id uuid,
  request_type text not null default 'contract',
  signer_name text not null default '',
  signer_email text,
  signer_phone text,
  status text not null default 'draft',
  legal_disclaimer text not null default 'Electronic signature record. Review company legal requirements before use.',
  sent_at timestamptz,
  signed_at timestamptz,
  audit_payload jsonb not null default '{}'::jsonb,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  constraint esign_requests_job_fk foreign key (company_id, job_id) references public.jobs(company_id, id) on delete cascade,
  constraint esign_requests_contact_fk foreign key (company_id, contact_id) references public.contacts(company_id, id) on delete set null
);

create table if not exists public.change_orders (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  contract_id uuid references public.job_contracts(id) on delete set null,
  change_order_number text,
  status text not null default 'draft',
  reason text not null default '',
  added_work text not null default '',
  removed_work text not null default '',
  price_delta_cents bigint not null default 0,
  photos jsonb not null default '[]'::jsonb,
  documents jsonb not null default '[]'::jsonb,
  homeowner_signed_at timestamptz,
  manager_approved_by uuid,
  manager_approved_at timestamptz,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint change_orders_job_fk foreign key (company_id, job_id) references public.jobs(company_id, id) on delete cascade
);

create table if not exists public.completion_certificates (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  contract_id uuid references public.job_contracts(id) on delete set null,
  status text not null default 'draft',
  completion_date date,
  final_walkthrough_by uuid,
  customer_acknowledged_at timestamptz,
  certificate_payload jsonb not null default '{}'::jsonb,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint completion_certificates_job_fk foreign key (company_id, job_id) references public.jobs(company_id, id) on delete cascade
);

create index if not exists contract_templates_company_idx on public.contract_templates(company_id, active, contract_type);
create index if not exists job_contracts_job_idx on public.job_contracts(company_id, job_id, status);
create index if not exists contract_versions_contract_idx on public.contract_versions(company_id, contract_id, version_number);
create index if not exists esign_requests_job_idx on public.esign_requests(company_id, job_id, status);
create index if not exists change_orders_job_idx on public.change_orders(company_id, job_id, status);
create index if not exists completion_certificates_job_idx on public.completion_certificates(company_id, job_id, status);

alter table public.contract_templates enable row level security;
alter table public.job_contracts enable row level security;
alter table public.contract_versions enable row level security;
alter table public.esign_requests enable row level security;
alter table public.change_orders enable row level security;
alter table public.completion_certificates enable row level security;

grant select, insert, update on public.contract_templates to authenticated;
grant select, insert, update on public.job_contracts to authenticated;
grant select, insert, update on public.contract_versions to authenticated;
grant select, insert, update on public.esign_requests to authenticated;
grant select, insert, update on public.change_orders to authenticated;
grant select, insert, update on public.completion_certificates to authenticated;

-- RLS policies: templates are manager-controlled; job-linked records follow job access.
