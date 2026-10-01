-- HAMRIQ estimating/product catalog layer
-- Adds pricing, estimate templates, manufacturer/product catalogs, color visualizer sessions,
-- job product selections, and estimate accuracy learning.

create table if not exists public.material_price_items (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  supplier_id uuid references public.vendors(id),
  sku text,
  name text not null,
  category text not null default 'roofing',
  unit text not null default 'each',
  unit_cost numeric(12,2) not null default 0,
  waste_factor numeric(6,4) not null default 0,
  active boolean not null default true,
  last_updated_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.labor_price_items (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  trade text not null default 'roofing',
  name text not null,
  unit text not null default 'square',
  unit_cost numeric(12,2) not null default 0,
  active boolean not null default true,
  last_updated_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.estimate_templates (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null,
  job_type text not null default 'residential_roof',
  description text,
  template_json jsonb not null default '{}'::jsonb,
  active boolean not null default true,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.manufacturer_catalog_items (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  manufacturer text not null,
  product_line text not null,
  product_name text not null,
  product_type text not null default 'shingle',
  color_name text,
  color_family text,
  image_url text,
  spec_url text,
  active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.job_product_selections (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  selection_type text not null,
  manufacturer text,
  product_line text,
  product_name text,
  color_name text,
  catalog_item_id uuid references public.manufacturer_catalog_items(id),
  status text not null default 'draft',
  selected_by uuid default auth.uid(),
  selected_at timestamptz not null default now(),
  notes text,
  constraint job_product_selections_job_fk foreign key (company_id, job_id) references public.jobs(company_id, id) on delete cascade
);

create table if not exists public.color_visualizer_sessions (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  contact_id uuid,
  base_photo_url text,
  selected_options jsonb not null default '[]'::jsonb,
  generated_preview_url text,
  status text not null default 'draft',
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint color_visualizer_job_fk foreign key (company_id, job_id) references public.jobs(company_id, id) on delete cascade,
  constraint color_visualizer_contact_fk foreign key (company_id, contact_id) references public.contacts(company_id, id) on delete set null
);

create table if not exists public.estimate_accuracy_reviews (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  estimate_id uuid,
  estimated_material_cost numeric(12,2),
  actual_material_cost numeric(12,2),
  estimated_labor_cost numeric(12,2),
  actual_labor_cost numeric(12,2),
  variance_summary jsonb not null default '{}'::jsonb,
  ai_recommendation text,
  manager_decision text not null default 'pending_review',
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  constraint estimate_accuracy_job_fk foreign key (company_id, job_id) references public.jobs(company_id, id) on delete cascade
);

create index if not exists material_price_items_company_idx on public.material_price_items(company_id, active, category);
create index if not exists labor_price_items_company_idx on public.labor_price_items(company_id, active, trade);
create index if not exists estimate_templates_company_idx on public.estimate_templates(company_id, active, job_type);
create index if not exists manufacturer_catalog_company_idx on public.manufacturer_catalog_items(company_id, manufacturer, product_type, active);
create index if not exists job_product_selections_job_idx on public.job_product_selections(company_id, job_id);
create index if not exists color_visualizer_job_idx on public.color_visualizer_sessions(company_id, job_id);
create index if not exists estimate_accuracy_job_idx on public.estimate_accuracy_reviews(company_id, job_id);

alter table public.material_price_items enable row level security;
alter table public.labor_price_items enable row level security;
alter table public.estimate_templates enable row level security;
alter table public.manufacturer_catalog_items enable row level security;
alter table public.job_product_selections enable row level security;
alter table public.color_visualizer_sessions enable row level security;
alter table public.estimate_accuracy_reviews enable row level security;

grant select, insert, update on public.material_price_items to authenticated;
grant select, insert, update on public.labor_price_items to authenticated;
grant select, insert, update on public.estimate_templates to authenticated;
grant select, insert, update on public.manufacturer_catalog_items to authenticated;
grant select, insert, update on public.job_product_selections to authenticated;
grant select, insert, update on public.color_visualizer_sessions to authenticated;
grant select, insert, update on public.estimate_accuracy_reviews to authenticated;

-- Manager-controlled libraries; job-level selections are allowed for permitted job users.
