-- HAMRIQ material pricing intelligence / supplier quote comparison execution layer
-- Creates supplier price books, quote requests/responses, quote comparison, price-change alerts, substitutions, and activity events.

create table if not exists public.supplier_price_books_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  supplier_name text not null,
  price_book_name text not null,
  effective_date date,
  expiration_date date,
  source_type text not null default 'manual' check (source_type in ('manual','csv_import','supplier_api','email_import','pdf_import','manager_entry')),
  status text not null default 'draft' check (status in ('draft','pending_review','approved','active','expired','archived')),
  currency_code text not null default 'USD',
  line_count integer not null default 0,
  notes text not null default '',
  metadata jsonb not null default '{}'::jsonb,
  approved_by uuid,
  approved_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.supplier_price_book_items_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  price_book_id uuid not null references public.supplier_price_books_deep(id) on delete cascade,
  supplier_sku text,
  internal_item_code text,
  category text not null default 'roofing_material',
  item_name text not null,
  manufacturer text,
  product_line text,
  color text,
  unit_of_measure text not null default 'each',
  unit_cost_cents bigint not null default 0,
  minimum_order_quantity numeric not null default 0,
  lead_time_days integer,
  availability_status text not null default 'unknown' check (availability_status in ('unknown','in_stock','limited','backordered','discontinued','special_order')),
  item_metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.material_quote_requests_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  requested_by uuid not null default auth.uid(),
  request_name text not null,
  request_status text not null default 'draft' check (request_status in ('draft','sent','partial_response','complete','cancelled','awarded','archived')),
  requested_supplier_names text[] not null default '{}'::text[],
  needed_by date,
  delivery_address text,
  delivery_instructions text not null default '',
  line_items jsonb not null default '[]'::jsonb,
  quote_metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.material_supplier_quote_responses_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  quote_request_id uuid not null references public.material_quote_requests_deep(id) on delete cascade,
  supplier_name text not null,
  response_status text not null default 'received' check (response_status in ('received','clarification_needed','accepted','declined','expired','rejected')),
  quoted_total_cents bigint not null default 0,
  freight_cents bigint not null default 0,
  tax_cents bigint not null default 0,
  estimated_delivery_date date,
  quote_document_url text,
  response_lines jsonb not null default '[]'::jsonb,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.supplier_quote_comparison_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  quote_request_id uuid not null references public.material_quote_requests_deep(id) on delete cascade,
  run_status text not null default 'queued' check (run_status in ('queued','running','complete','failed','manager_review_needed')),
  best_total_supplier_name text,
  best_total_cents bigint,
  estimated_savings_cents bigint not null default 0,
  comparison_summary jsonb not null default '{}'::jsonb,
  ai_notes text not null default '',
  requires_manager_review boolean not null default true,
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.material_price_change_alerts_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  supplier_name text not null,
  item_name text not null,
  internal_item_code text,
  old_unit_cost_cents bigint,
  new_unit_cost_cents bigint not null default 0,
  percent_change numeric,
  alert_status text not null default 'open' check (alert_status in ('open','manager_review','approved','rejected','applied','ignored','archived')),
  alert_reason text not null default '',
  related_price_book_item_id uuid references public.supplier_price_book_items_deep(id) on delete set null,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.material_substitution_recommendations_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  original_item_name text not null,
  substitute_item_name text not null,
  substitute_supplier_name text,
  reason text not null default '',
  cost_delta_cents bigint not null default 0,
  availability_status text not null default 'unknown',
  recommendation_status text not null default 'draft' check (recommendation_status in ('draft','rep_review','manager_review','approved','rejected','applied','archived')),
  requires_customer_approval boolean not null default false,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.material_pricing_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  event_type text not null,
  entity_type text not null,
  entity_id uuid,
  event_summary text not null default '',
  event_payload jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create index if not exists idx_supplier_price_books_company_status on public.supplier_price_books_deep(company_id, status);
create index if not exists idx_supplier_price_book_items_company_book on public.supplier_price_book_items_deep(company_id, price_book_id);
create index if not exists idx_material_quote_requests_company_job on public.material_quote_requests_deep(company_id, job_id);
create index if not exists idx_material_quote_responses_company_request on public.material_supplier_quote_responses_deep(company_id, quote_request_id);
create index if not exists idx_supplier_quote_comparison_company_request on public.supplier_quote_comparison_runs_deep(company_id, quote_request_id);
create index if not exists idx_price_change_alerts_company_status on public.material_price_change_alerts_deep(company_id, alert_status);
create index if not exists idx_substitution_recommendations_company_job on public.material_substitution_recommendations_deep(company_id, job_id);
create index if not exists idx_material_pricing_activity_company_job on public.material_pricing_activity_events_deep(company_id, job_id);

alter table public.supplier_price_books_deep enable row level security;
alter table public.supplier_price_book_items_deep enable row level security;
alter table public.material_quote_requests_deep enable row level security;
alter table public.material_supplier_quote_responses_deep enable row level security;
alter table public.supplier_quote_comparison_runs_deep enable row level security;
alter table public.material_price_change_alerts_deep enable row level security;
alter table public.material_substitution_recommendations_deep enable row level security;
alter table public.material_pricing_activity_events_deep enable row level security;

revoke all on public.supplier_price_books_deep from anon, authenticated;
revoke all on public.supplier_price_book_items_deep from anon, authenticated;
revoke all on public.material_quote_requests_deep from anon, authenticated;
revoke all on public.material_supplier_quote_responses_deep from anon, authenticated;
revoke all on public.supplier_quote_comparison_runs_deep from anon, authenticated;
revoke all on public.material_price_change_alerts_deep from anon, authenticated;
revoke all on public.material_substitution_recommendations_deep from anon, authenticated;
revoke all on public.material_pricing_activity_events_deep from anon, authenticated;

grant select, insert, update on public.supplier_price_books_deep to authenticated;
grant select, insert, update on public.supplier_price_book_items_deep to authenticated;
grant select, insert, update on public.material_quote_requests_deep to authenticated;
grant select, insert, update on public.material_supplier_quote_responses_deep to authenticated;
grant select, insert, update on public.supplier_quote_comparison_runs_deep to authenticated;
grant select, insert, update on public.material_price_change_alerts_deep to authenticated;
grant select, insert, update on public.material_substitution_recommendations_deep to authenticated;
grant select, insert on public.material_pricing_activity_events_deep to authenticated;

create policy supplier_price_books_company_select_deep on public.supplier_price_books_deep for select to authenticated using (private.company_access(company_id));
create policy supplier_price_books_manager_write_deep on public.supplier_price_books_deep for insert to authenticated with check (private.is_manager(company_id));
create policy supplier_price_books_manager_update_deep on public.supplier_price_books_deep for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy supplier_price_book_items_company_select_deep on public.supplier_price_book_items_deep for select to authenticated using (private.company_access(company_id));
create policy supplier_price_book_items_manager_write_deep on public.supplier_price_book_items_deep for insert to authenticated with check (private.is_manager(company_id));
create policy supplier_price_book_items_manager_update_deep on public.supplier_price_book_items_deep for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy material_quote_requests_company_select_deep on public.material_quote_requests_deep for select to authenticated using (private.company_access(company_id));
create policy material_quote_requests_company_insert_deep on public.material_quote_requests_deep for insert to authenticated with check (private.company_access(company_id));
create policy material_quote_requests_manager_update_deep on public.material_quote_requests_deep for update to authenticated using (private.is_manager(company_id) or requested_by = auth.uid()) with check (private.company_access(company_id));

create policy material_quote_responses_company_select_deep on public.material_supplier_quote_responses_deep for select to authenticated using (private.company_access(company_id));
create policy material_quote_responses_company_insert_deep on public.material_supplier_quote_responses_deep for insert to authenticated with check (private.company_access(company_id));
create policy material_quote_responses_manager_update_deep on public.material_supplier_quote_responses_deep for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy supplier_quote_comparison_company_select_deep on public.supplier_quote_comparison_runs_deep for select to authenticated using (private.company_access(company_id));
create policy supplier_quote_comparison_company_insert_deep on public.supplier_quote_comparison_runs_deep for insert to authenticated with check (private.company_access(company_id));
create policy supplier_quote_comparison_manager_update_deep on public.supplier_quote_comparison_runs_deep for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy price_change_alerts_company_select_deep on public.material_price_change_alerts_deep for select to authenticated using (private.company_access(company_id));
create policy price_change_alerts_manager_write_deep on public.material_price_change_alerts_deep for insert to authenticated with check (private.is_manager(company_id));
create policy price_change_alerts_manager_update_deep on public.material_price_change_alerts_deep for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy material_substitutions_company_select_deep on public.material_substitution_recommendations_deep for select to authenticated using (private.company_access(company_id));
create policy material_substitutions_company_insert_deep on public.material_substitution_recommendations_deep for insert to authenticated with check (private.company_access(company_id));
create policy material_substitutions_manager_update_deep on public.material_substitution_recommendations_deep for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy material_pricing_activity_company_select_deep on public.material_pricing_activity_events_deep for select to authenticated using (private.company_access(company_id));
create policy material_pricing_activity_company_insert_deep on public.material_pricing_activity_events_deep for insert to authenticated with check (private.company_access(company_id));
