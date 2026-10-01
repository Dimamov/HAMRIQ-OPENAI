create table if not exists public.manufacturer_catalog_sync_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  provider_name text not null default 'manual',
  manufacturer_name text not null,
  sync_status text not null default 'pending' check (sync_status in ('pending','running','completed','failed','canceled')),
  item_count integer not null default 0,
  error_message text,
  synced_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.product_color_boards_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  manufacturer_name text not null,
  product_line text not null,
  board_name text not null,
  board_type text not null default 'shingles' check (board_type in ('shingles','drip_edge','gutters','siding','accessories','other')),
  colors jsonb not null default '[]'::jsonb,
  is_active boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.visualizer_house_assets_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  contact_id uuid references public.contacts(id) on delete set null,
  asset_label text not null default 'house photo',
  storage_path text,
  side_of_home text check (side_of_home in ('front','left','right','back','other')),
  quality_status text not null default 'pending' check (quality_status in ('pending','usable','needs_retake','rejected')),
  notes text,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.visualizer_sessions_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  contact_id uuid references public.contacts(id) on delete set null,
  house_asset_id uuid references public.visualizer_house_assets_deep(id) on delete set null,
  session_status text not null default 'draft' check (session_status in ('draft','shared','viewed','favorites_added','approved','expired','archived')),
  shared_with_homeowner boolean not null default false,
  shared_at timestamptz,
  expires_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.visualizer_selection_options_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  visualizer_session_id uuid not null references public.visualizer_sessions_deep(id) on delete cascade,
  color_board_id uuid references public.product_color_boards_deep(id) on delete set null,
  option_label text not null,
  product_category text not null default 'shingles',
  manufacturer_name text,
  product_line text,
  color_name text not null,
  asset_preview_path text,
  is_ai_suggested boolean not null default false,
  ai_reason text,
  requires_human_review boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.homeowner_visualizer_favorites_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  visualizer_session_id uuid not null references public.visualizer_sessions_deep(id) on delete cascade,
  selection_option_id uuid not null references public.visualizer_selection_options_deep(id) on delete cascade,
  homeowner_name text,
  favorite_rank integer,
  notes text,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.visualizer_comparison_sets_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  visualizer_session_id uuid not null references public.visualizer_sessions_deep(id) on delete cascade,
  set_name text not null,
  option_ids uuid[] not null default '{}',
  comparison_notes text,
  viewed_count integer not null default 0,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.final_color_approval_records_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  visualizer_session_id uuid references public.visualizer_sessions_deep(id) on delete set null,
  selected_shingle_color text,
  selected_drip_edge_color text,
  selected_gutter_color text,
  other_selections jsonb not null default '{}'::jsonb,
  approval_status text not null default 'pending' check (approval_status in ('pending','approved','changes_requested','canceled')),
  approved_by_homeowner_name text,
  approved_at timestamptz,
  manager_review_required boolean not null default true,
  manager_reviewed_by uuid,
  manager_reviewed_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists manufacturer_catalog_sync_runs_deep_company_idx on public.manufacturer_catalog_sync_runs_deep(company_id, created_at desc);
create index if not exists product_color_boards_deep_company_idx on public.product_color_boards_deep(company_id, manufacturer_name, product_line);
create index if not exists visualizer_house_assets_deep_job_idx on public.visualizer_house_assets_deep(company_id, job_id);
create index if not exists visualizer_sessions_deep_job_idx on public.visualizer_sessions_deep(company_id, job_id, session_status);
create index if not exists visualizer_selection_options_deep_session_idx on public.visualizer_selection_options_deep(company_id, visualizer_session_id);
create index if not exists homeowner_visualizer_favorites_deep_session_idx on public.homeowner_visualizer_favorites_deep(company_id, visualizer_session_id);
create index if not exists visualizer_comparison_sets_deep_session_idx on public.visualizer_comparison_sets_deep(company_id, visualizer_session_id);
create index if not exists final_color_approval_records_deep_job_idx on public.final_color_approval_records_deep(company_id, job_id, approval_status);

alter table public.manufacturer_catalog_sync_runs_deep enable row level security;
alter table public.product_color_boards_deep enable row level security;
alter table public.visualizer_house_assets_deep enable row level security;
alter table public.visualizer_sessions_deep enable row level security;
alter table public.visualizer_selection_options_deep enable row level security;
alter table public.homeowner_visualizer_favorites_deep enable row level security;
alter table public.visualizer_comparison_sets_deep enable row level security;
alter table public.final_color_approval_records_deep enable row level security;

revoke all on public.manufacturer_catalog_sync_runs_deep from anon, authenticated;
revoke all on public.product_color_boards_deep from anon, authenticated;
revoke all on public.visualizer_house_assets_deep from anon, authenticated;
revoke all on public.visualizer_sessions_deep from anon, authenticated;
revoke all on public.visualizer_selection_options_deep from anon, authenticated;
revoke all on public.homeowner_visualizer_favorites_deep from anon, authenticated;
revoke all on public.visualizer_comparison_sets_deep from anon, authenticated;
revoke all on public.final_color_approval_records_deep from anon, authenticated;

grant select, insert, update on public.manufacturer_catalog_sync_runs_deep to authenticated;
grant select, insert, update on public.product_color_boards_deep to authenticated;
grant select, insert, update on public.visualizer_house_assets_deep to authenticated;
grant select, insert, update on public.visualizer_sessions_deep to authenticated;
grant select, insert, update on public.visualizer_selection_options_deep to authenticated;
grant select, insert, update on public.homeowner_visualizer_favorites_deep to authenticated;
grant select, insert, update on public.visualizer_comparison_sets_deep to authenticated;
grant select, insert, update on public.final_color_approval_records_deep to authenticated;

drop policy if exists manufacturer_catalog_sync_runs_deep_manager on public.manufacturer_catalog_sync_runs_deep;
create policy manufacturer_catalog_sync_runs_deep_manager on public.manufacturer_catalog_sync_runs_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

drop policy if exists product_color_boards_deep_company_select on public.product_color_boards_deep;
create policy product_color_boards_deep_company_select on public.product_color_boards_deep for select to authenticated using (private.company_access(company_id));
drop policy if exists product_color_boards_deep_manager_write on public.product_color_boards_deep;
create policy product_color_boards_deep_manager_write on public.product_color_boards_deep for insert to authenticated with check (private.is_manager(company_id));
drop policy if exists product_color_boards_deep_manager_update on public.product_color_boards_deep;
create policy product_color_boards_deep_manager_update on public.product_color_boards_deep for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

drop policy if exists visualizer_house_assets_deep_job_select on public.visualizer_house_assets_deep;
create policy visualizer_house_assets_deep_job_select on public.visualizer_house_assets_deep for select to authenticated using (private.company_access(company_id) and (job_id is null or private.can_job(company_id, job_id)));
drop policy if exists visualizer_house_assets_deep_job_insert on public.visualizer_house_assets_deep;
create policy visualizer_house_assets_deep_job_insert on public.visualizer_house_assets_deep for insert to authenticated with check (private.company_access(company_id) and (job_id is null or private.can_job(company_id, job_id)));
drop policy if exists visualizer_house_assets_deep_job_update on public.visualizer_house_assets_deep;
create policy visualizer_house_assets_deep_job_update on public.visualizer_house_assets_deep for update to authenticated using (private.company_access(company_id) and (job_id is null or private.can_job(company_id, job_id))) with check (private.company_access(company_id) and (job_id is null or private.can_job(company_id, job_id)));

drop policy if exists visualizer_sessions_deep_job_access on public.visualizer_sessions_deep;
create policy visualizer_sessions_deep_job_access on public.visualizer_sessions_deep for all to authenticated using (private.company_access(company_id) and (job_id is null or private.can_job(company_id, job_id))) with check (private.company_access(company_id) and (job_id is null or private.can_job(company_id, job_id)));

drop policy if exists visualizer_selection_options_deep_company_access on public.visualizer_selection_options_deep;
create policy visualizer_selection_options_deep_company_access on public.visualizer_selection_options_deep for all to authenticated using (private.company_access(company_id)) with check (private.company_access(company_id));

drop policy if exists homeowner_visualizer_favorites_deep_company_access on public.homeowner_visualizer_favorites_deep;
create policy homeowner_visualizer_favorites_deep_company_access on public.homeowner_visualizer_favorites_deep for all to authenticated using (private.company_access(company_id)) with check (private.company_access(company_id));

drop policy if exists visualizer_comparison_sets_deep_company_access on public.visualizer_comparison_sets_deep;
create policy visualizer_comparison_sets_deep_company_access on public.visualizer_comparison_sets_deep for all to authenticated using (private.company_access(company_id)) with check (private.company_access(company_id));

drop policy if exists final_color_approval_records_deep_job_select on public.final_color_approval_records_deep;
create policy final_color_approval_records_deep_job_select on public.final_color_approval_records_deep for select to authenticated using (private.company_access(company_id) and (job_id is null or private.can_job(company_id, job_id)));
drop policy if exists final_color_approval_records_deep_job_insert on public.final_color_approval_records_deep;
create policy final_color_approval_records_deep_job_insert on public.final_color_approval_records_deep for insert to authenticated with check (private.company_access(company_id) and (job_id is null or private.can_job(company_id, job_id)));
drop policy if exists final_color_approval_records_deep_manager_update on public.final_color_approval_records_deep;
create policy final_color_approval_records_deep_manager_update on public.final_color_approval_records_deep for update to authenticated using (private.is_manager(company_id) or (private.company_access(company_id) and (job_id is null or private.can_job(company_id, job_id)))) with check (private.is_manager(company_id) or (private.company_access(company_id) and (job_id is null or private.can_job(company_id, job_id))));
