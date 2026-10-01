create table if not exists public.material_receiving_sessions_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  purchase_order_id uuid references public.supplier_purchase_orders_deep(id) on delete set null,
  delivery_window_id uuid references public.material_delivery_windows_deep(id) on delete set null,
  received_by uuid not null default auth.uid(),
  receiving_status text not null default 'draft' check (receiving_status in ('draft','received_partial','received_complete','shortage_found','damage_found','disputed','manager_review','closed')),
  received_at timestamptz,
  supplier_name text,
  driver_name text,
  delivery_ticket_number text,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.material_received_line_checks_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  receiving_session_id uuid not null references public.material_receiving_sessions_deep(id) on delete cascade,
  purchase_order_item_id uuid references public.supplier_purchase_order_items_deep(id) on delete set null,
  material_name text not null,
  sku text,
  ordered_quantity numeric(12,2) not null default 0,
  received_quantity numeric(12,2) not null default 0,
  damaged_quantity numeric(12,2) not null default 0,
  missing_quantity numeric(12,2) generated always as (greatest(ordered_quantity - received_quantity, 0)) stored,
  unit text not null default 'each',
  line_status text not null default 'unchecked' check (line_status in ('unchecked','matched','short','over','damaged','substituted','manager_review','resolved')),
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.material_delivery_photo_records_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  receiving_session_id uuid not null references public.material_receiving_sessions_deep(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  photo_url text not null default '',
  photo_type text not null default 'delivery_overview' check (photo_type in ('delivery_overview','pallet','bundle','shingle','accessory','damage','shortage','ticket','staging_area','other')),
  ai_quality_status text not null default 'not_checked' check (ai_quality_status in ('not_checked','clear','blurry','missing_context','needs_retake')),
  ai_detected_items jsonb not null default '[]'::jsonb,
  caption text not null default '',
  uploaded_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.material_damage_shortage_reports_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  receiving_session_id uuid not null references public.material_receiving_sessions_deep(id) on delete cascade,
  received_line_check_id uuid references public.material_received_line_checks_deep(id) on delete set null,
  report_type text not null check (report_type in ('damage','shortage','wrong_item','late_delivery','overage','other')),
  severity text not null default 'medium' check (severity in ('low','medium','high','critical')),
  description text not null default '',
  estimated_cost_impact_cents bigint not null default 0,
  production_impact text not null default 'none' check (production_impact in ('none','minor_delay','major_delay','cannot_start','cannot_finish')),
  manager_review_status text not null default 'pending' check (manager_review_status in ('pending','reviewed','resolved','supplier_dispute','credit_requested','closed')),
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.supplier_delivery_dispute_cases_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  receiving_session_id uuid references public.material_receiving_sessions_deep(id) on delete set null,
  damage_shortage_report_id uuid references public.material_damage_shortage_reports_deep(id) on delete set null,
  supplier_name text not null default '',
  dispute_status text not null default 'open' check (dispute_status in ('open','submitted_to_supplier','waiting_supplier','credit_offered','replacement_scheduled','denied','resolved','closed')),
  requested_resolution text not null default 'credit_or_replacement' check (requested_resolution in ('credit','replacement','credit_or_replacement','price_adjustment','other')),
  requested_credit_cents bigint not null default 0,
  supplier_reference_number text,
  due_at timestamptz,
  resolved_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.production_material_handoff_records_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  receiving_session_id uuid references public.material_receiving_sessions_deep(id) on delete set null,
  handoff_status text not null default 'not_ready' check (handoff_status in ('not_ready','ready_with_exceptions','ready','blocked','handed_off','accepted_by_production')),
  readiness_summary text not null default '',
  exceptions jsonb not null default '[]'::jsonb,
  production_acknowledged_by uuid,
  production_acknowledged_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.material_receiving_manager_review_queue_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  receiving_session_id uuid references public.material_receiving_sessions_deep(id) on delete set null,
  review_type text not null check (review_type in ('shortage','damage','wrong_item','late_delivery','production_blocker','supplier_dispute','credit_review','other')),
  priority text not null default 'medium' check (priority in ('low','medium','high','urgent')),
  status text not null default 'open' check (status in ('open','in_review','approved','rejected','resolved','closed')),
  assigned_manager_id uuid,
  decision_notes text not null default '',
  resolved_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.material_receiving_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  receiving_session_id uuid references public.material_receiving_sessions_deep(id) on delete set null,
  event_type text not null,
  event_summary text not null default '',
  event_payload jsonb not null default '{}'::jsonb,
  actor_user_id uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create index if not exists idx_material_receiving_sessions_company_job on public.material_receiving_sessions_deep(company_id, job_id);
create index if not exists idx_material_received_line_checks_session on public.material_received_line_checks_deep(company_id, receiving_session_id);
create index if not exists idx_material_delivery_photo_records_session on public.material_delivery_photo_records_deep(company_id, receiving_session_id);
create index if not exists idx_material_damage_shortage_reports_job on public.material_damage_shortage_reports_deep(company_id, job_id);
create index if not exists idx_supplier_delivery_dispute_cases_job on public.supplier_delivery_dispute_cases_deep(company_id, job_id);
create index if not exists idx_production_material_handoff_records_job on public.production_material_handoff_records_deep(company_id, job_id);
create index if not exists idx_material_receiving_manager_review_queue_company on public.material_receiving_manager_review_queue_deep(company_id, status);
create index if not exists idx_material_receiving_activity_events_job on public.material_receiving_activity_events_deep(company_id, job_id, created_at desc);

alter table public.material_receiving_sessions_deep enable row level security;
alter table public.material_received_line_checks_deep enable row level security;
alter table public.material_delivery_photo_records_deep enable row level security;
alter table public.material_damage_shortage_reports_deep enable row level security;
alter table public.supplier_delivery_dispute_cases_deep enable row level security;
alter table public.production_material_handoff_records_deep enable row level security;
alter table public.material_receiving_manager_review_queue_deep enable row level security;
alter table public.material_receiving_activity_events_deep enable row level security;

revoke all on public.material_receiving_sessions_deep from anon, authenticated;
revoke all on public.material_received_line_checks_deep from anon, authenticated;
revoke all on public.material_delivery_photo_records_deep from anon, authenticated;
revoke all on public.material_damage_shortage_reports_deep from anon, authenticated;
revoke all on public.supplier_delivery_dispute_cases_deep from anon, authenticated;
revoke all on public.production_material_handoff_records_deep from anon, authenticated;
revoke all on public.material_receiving_manager_review_queue_deep from anon, authenticated;
revoke all on public.material_receiving_activity_events_deep from anon, authenticated;

grant select, insert, update on public.material_receiving_sessions_deep to authenticated;
grant select, insert, update on public.material_received_line_checks_deep to authenticated;
grant select, insert, update on public.material_delivery_photo_records_deep to authenticated;
grant select, insert, update on public.material_damage_shortage_reports_deep to authenticated;
grant select, insert, update on public.supplier_delivery_dispute_cases_deep to authenticated;
grant select, insert, update on public.production_material_handoff_records_deep to authenticated;
grant select, insert, update on public.material_receiving_manager_review_queue_deep to authenticated;
grant select, insert, update on public.material_receiving_activity_events_deep to authenticated;

create policy material_receiving_sessions_select on public.material_receiving_sessions_deep for select to authenticated using (private.company_access(company_id));
create policy material_receiving_sessions_insert on public.material_receiving_sessions_deep for insert to authenticated with check (private.company_access(company_id));
create policy material_receiving_sessions_update on public.material_receiving_sessions_deep for update to authenticated using (private.company_access(company_id)) with check (private.company_access(company_id));

create policy material_received_line_checks_select on public.material_received_line_checks_deep for select to authenticated using (private.company_access(company_id));
create policy material_received_line_checks_insert on public.material_received_line_checks_deep for insert to authenticated with check (private.company_access(company_id));
create policy material_received_line_checks_update on public.material_received_line_checks_deep for update to authenticated using (private.company_access(company_id)) with check (private.company_access(company_id));

create policy material_delivery_photo_records_select on public.material_delivery_photo_records_deep for select to authenticated using (private.company_access(company_id));
create policy material_delivery_photo_records_insert on public.material_delivery_photo_records_deep for insert to authenticated with check (private.company_access(company_id));
create policy material_delivery_photo_records_update on public.material_delivery_photo_records_deep for update to authenticated using (private.company_access(company_id)) with check (private.company_access(company_id));

create policy material_damage_shortage_reports_select on public.material_damage_shortage_reports_deep for select to authenticated using (private.company_access(company_id));
create policy material_damage_shortage_reports_insert on public.material_damage_shortage_reports_deep for insert to authenticated with check (private.company_access(company_id));
create policy material_damage_shortage_reports_update on public.material_damage_shortage_reports_deep for update to authenticated using (private.company_access(company_id)) with check (private.company_access(company_id));

create policy supplier_delivery_dispute_cases_select on public.supplier_delivery_dispute_cases_deep for select to authenticated using (private.company_access(company_id));
create policy supplier_delivery_dispute_cases_insert on public.supplier_delivery_dispute_cases_deep for insert to authenticated with check (private.is_manager(company_id));
create policy supplier_delivery_dispute_cases_update on public.supplier_delivery_dispute_cases_deep for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy production_material_handoff_records_select on public.production_material_handoff_records_deep for select to authenticated using (private.company_access(company_id));
create policy production_material_handoff_records_insert on public.production_material_handoff_records_deep for insert to authenticated with check (private.company_access(company_id));
create policy production_material_handoff_records_update on public.production_material_handoff_records_deep for update to authenticated using (private.company_access(company_id)) with check (private.company_access(company_id));

create policy material_receiving_manager_review_queue_select on public.material_receiving_manager_review_queue_deep for select to authenticated using (private.company_access(company_id));
create policy material_receiving_manager_review_queue_insert on public.material_receiving_manager_review_queue_deep for insert to authenticated with check (private.company_access(company_id));
create policy material_receiving_manager_review_queue_update on public.material_receiving_manager_review_queue_deep for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy material_receiving_activity_events_select on public.material_receiving_activity_events_deep for select to authenticated using (private.company_access(company_id));
create policy material_receiving_activity_events_insert on public.material_receiving_activity_events_deep for insert to authenticated with check (private.company_access(company_id));
create policy material_receiving_activity_events_update on public.material_receiving_activity_events_deep for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
