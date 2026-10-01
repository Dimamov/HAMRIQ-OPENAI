-- Dashboard customization / widget layout layer
-- Adds drag/drop widgets, hide/restore widgets, role visibility, company defaults, and reset history.

create table if not exists public.dashboard_widget_catalog_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  widget_key text not null,
  widget_name text not null,
  widget_description text not null default '',
  module_area text not null default 'home',
  widget_category text not null default 'general',
  default_width integer not null default 1 check (default_width between 1 and 4),
  default_height integer not null default 1 check (default_height between 1 and 4),
  is_resizable boolean not null default true,
  is_hideable boolean not null default true,
  is_draggable boolean not null default true,
  requires_manager boolean not null default false,
  requires_commercial_enabled boolean not null default false,
  required_role_keys text[] not null default '{}',
  default_config jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, widget_key)
);

create table if not exists public.dashboard_layout_profiles_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  layout_name text not null,
  layout_scope text not null default 'user' check (layout_scope in ('company_default','role_default','user')),
  target_user_id uuid,
  target_role_key text,
  dashboard_area text not null default 'home',
  is_company_default boolean not null default false,
  is_locked_by_manager boolean not null default false,
  is_active boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.dashboard_layout_items_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  layout_profile_id uuid not null references public.dashboard_layout_profiles_deep(id) on delete cascade,
  widget_catalog_id uuid references public.dashboard_widget_catalog_deep(id) on delete set null,
  widget_key text not null,
  position_x integer not null default 0 check (position_x >= 0),
  position_y integer not null default 0 check (position_y >= 0),
  width integer not null default 1 check (width between 1 and 4),
  height integer not null default 1 check (height between 1 and 4),
  sort_order integer not null default 0,
  is_hidden boolean not null default false,
  is_pinned boolean not null default false,
  widget_config jsonb not null default '{}'::jsonb,
  last_moved_by uuid default auth.uid(),
  last_moved_at timestamptz default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(layout_profile_id, widget_key)
);

create table if not exists public.dashboard_hidden_widget_records_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null default auth.uid(),
  dashboard_area text not null default 'home',
  widget_key text not null,
  hidden_reason text not null default '',
  hidden_at timestamptz not null default now(),
  restored_at timestamptz,
  is_hidden boolean not null default true,
  created_at timestamptz not null default now(),
  unique(company_id, user_id, dashboard_area, widget_key)
);

create table if not exists public.dashboard_widget_resize_history_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null default auth.uid(),
  layout_profile_id uuid references public.dashboard_layout_profiles_deep(id) on delete cascade,
  widget_key text not null,
  previous_position jsonb not null default '{}'::jsonb,
  new_position jsonb not null default '{}'::jsonb,
  previous_size jsonb not null default '{}'::jsonb,
  new_size jsonb not null default '{}'::jsonb,
  change_type text not null default 'move' check (change_type in ('move','resize','hide','restore','pin','unpin','reset')),
  created_at timestamptz not null default now()
);

create table if not exists public.dashboard_role_widget_visibility_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  role_key text not null,
  widget_key text not null,
  dashboard_area text not null default 'home',
  is_available boolean not null default true,
  is_default_visible boolean not null default true,
  manager_can_override boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, role_key, dashboard_area, widget_key)
);

create table if not exists public.dashboard_reset_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null default auth.uid(),
  dashboard_area text not null default 'home',
  reset_to_profile_id uuid references public.dashboard_layout_profiles_deep(id) on delete set null,
  reset_scope text not null default 'company_default' check (reset_scope in ('company_default','role_default','system_default','custom_profile')),
  reset_summary jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.dashboard_customization_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null default auth.uid(),
  dashboard_area text not null default 'home',
  event_type text not null default 'layout_changed',
  widget_key text,
  layout_profile_id uuid references public.dashboard_layout_profiles_deep(id) on delete set null,
  event_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_dashboard_widget_catalog_company on public.dashboard_widget_catalog_deep(company_id, module_area, is_active);
create index if not exists idx_dashboard_layout_profiles_company on public.dashboard_layout_profiles_deep(company_id, dashboard_area, layout_scope, is_active);
create index if not exists idx_dashboard_layout_items_profile on public.dashboard_layout_items_deep(layout_profile_id, is_hidden, sort_order);
create index if not exists idx_dashboard_hidden_widgets_user on public.dashboard_hidden_widget_records_deep(company_id, user_id, dashboard_area, is_hidden);
create index if not exists idx_dashboard_role_visibility_company on public.dashboard_role_widget_visibility_deep(company_id, role_key, dashboard_area);

alter table public.dashboard_widget_catalog_deep enable row level security;
alter table public.dashboard_layout_profiles_deep enable row level security;
alter table public.dashboard_layout_items_deep enable row level security;
alter table public.dashboard_hidden_widget_records_deep enable row level security;
alter table public.dashboard_widget_resize_history_deep enable row level security;
alter table public.dashboard_role_widget_visibility_deep enable row level security;
alter table public.dashboard_reset_events_deep enable row level security;
alter table public.dashboard_customization_activity_events_deep enable row level security;

revoke all on public.dashboard_widget_catalog_deep from anon, authenticated;
revoke all on public.dashboard_layout_profiles_deep from anon, authenticated;
revoke all on public.dashboard_layout_items_deep from anon, authenticated;
revoke all on public.dashboard_hidden_widget_records_deep from anon, authenticated;
revoke all on public.dashboard_widget_resize_history_deep from anon, authenticated;
revoke all on public.dashboard_role_widget_visibility_deep from anon, authenticated;
revoke all on public.dashboard_reset_events_deep from anon, authenticated;
revoke all on public.dashboard_customization_activity_events_deep from anon, authenticated;

grant select, insert, update on public.dashboard_widget_catalog_deep to authenticated;
grant select, insert, update on public.dashboard_layout_profiles_deep to authenticated;
grant select, insert, update on public.dashboard_layout_items_deep to authenticated;
grant select, insert, update on public.dashboard_hidden_widget_records_deep to authenticated;
grant select, insert, update on public.dashboard_widget_resize_history_deep to authenticated;
grant select, insert, update on public.dashboard_role_widget_visibility_deep to authenticated;
grant select, insert, update on public.dashboard_reset_events_deep to authenticated;
grant select, insert, update on public.dashboard_customization_activity_events_deep to authenticated;

create policy dashboard_widget_catalog_select on public.dashboard_widget_catalog_deep for select using (private.company_access(company_id));
create policy dashboard_widget_catalog_manage on public.dashboard_widget_catalog_deep for all using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy dashboard_layout_profiles_select on public.dashboard_layout_profiles_deep for select using (private.company_access(company_id) and (layout_scope <> 'user' or target_user_id = auth.uid() or private.is_manager(company_id)));
create policy dashboard_layout_profiles_insert on public.dashboard_layout_profiles_deep for insert with check (private.company_access(company_id) and ((layout_scope = 'user' and coalesce(target_user_id, auth.uid()) = auth.uid()) or private.is_manager(company_id)));
create policy dashboard_layout_profiles_update on public.dashboard_layout_profiles_deep for update using (private.company_access(company_id) and ((layout_scope = 'user' and target_user_id = auth.uid() and is_locked_by_manager = false) or private.is_manager(company_id))) with check (private.company_access(company_id) and ((layout_scope = 'user' and target_user_id = auth.uid() and is_locked_by_manager = false) or private.is_manager(company_id)));

create policy dashboard_layout_items_select on public.dashboard_layout_items_deep for select using (private.company_access(company_id));
create policy dashboard_layout_items_insert on public.dashboard_layout_items_deep for insert with check (private.company_access(company_id));
create policy dashboard_layout_items_update on public.dashboard_layout_items_deep for update using (private.company_access(company_id)) with check (private.company_access(company_id));

create policy dashboard_hidden_widgets_select on public.dashboard_hidden_widget_records_deep for select using (private.company_access(company_id) and (user_id = auth.uid() or private.is_manager(company_id)));
create policy dashboard_hidden_widgets_insert on public.dashboard_hidden_widget_records_deep for insert with check (private.company_access(company_id) and user_id = auth.uid());
create policy dashboard_hidden_widgets_update on public.dashboard_hidden_widget_records_deep for update using (private.company_access(company_id) and (user_id = auth.uid() or private.is_manager(company_id))) with check (private.company_access(company_id) and (user_id = auth.uid() or private.is_manager(company_id)));

create policy dashboard_resize_history_select on public.dashboard_widget_resize_history_deep for select using (private.company_access(company_id) and (user_id = auth.uid() or private.is_manager(company_id)));
create policy dashboard_resize_history_insert on public.dashboard_widget_resize_history_deep for insert with check (private.company_access(company_id) and user_id = auth.uid());

create policy dashboard_role_visibility_select on public.dashboard_role_widget_visibility_deep for select using (private.company_access(company_id));
create policy dashboard_role_visibility_manage on public.dashboard_role_widget_visibility_deep for all using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy dashboard_reset_events_select on public.dashboard_reset_events_deep for select using (private.company_access(company_id) and (user_id = auth.uid() or private.is_manager(company_id)));
create policy dashboard_reset_events_insert on public.dashboard_reset_events_deep for insert with check (private.company_access(company_id) and user_id = auth.uid());

create policy dashboard_customization_events_select on public.dashboard_customization_activity_events_deep for select using (private.company_access(company_id) and (user_id = auth.uid() or private.is_manager(company_id)));
create policy dashboard_customization_events_insert on public.dashboard_customization_activity_events_deep for insert with check (private.company_access(company_id) and user_id = auth.uid());
