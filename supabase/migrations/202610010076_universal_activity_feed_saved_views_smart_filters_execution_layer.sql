-- Universal activity feed / saved views / smart filters execution layer
-- Adds configurable activity streams, saved views, smart filters, labels, and visibility controls.

create table if not exists public.universal_activity_feed_items_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  actor_user_id uuid default auth.uid(),
  assigned_user_id uuid,
  feed_scope text not null default 'company' check (feed_scope in ('company','job','customer','rep','manager','production','finance','system')),
  event_type text not null,
  event_title text not null,
  event_summary text not null default '',
  source_module text not null default 'general',
  priority text not null default 'normal' check (priority in ('low','normal','high','critical')),
  is_pinned boolean not null default false,
  requires_manager_review boolean not null default false,
  metadata jsonb not null default '{}'::jsonb,
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.activity_feed_subscriptions_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null default auth.uid(),
  stream_key text not null,
  stream_label text not null,
  source_modules jsonb not null default '[]'::jsonb,
  priority_filter text not null default 'all' check (priority_filter in ('all','normal_and_above','high_and_critical','critical_only')),
  delivery_channels jsonb not null default '["in_app"]'::jsonb,
  is_enabled boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, user_id, stream_key)
);

create table if not exists public.saved_view_profiles_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  owner_user_id uuid not null default auth.uid(),
  view_name text not null,
  view_scope text not null default 'personal' check (view_scope in ('personal','role','company')),
  target_module text not null,
  layout_mode text not null default 'list' check (layout_mode in ('list','board','calendar','map','dashboard','table')),
  sort_config jsonb not null default '{}'::jsonb,
  filter_config jsonb not null default '{}'::jsonb,
  visible_columns jsonb not null default '[]'::jsonb,
  is_default boolean not null default false,
  is_active boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.smart_filter_rules_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  saved_view_id uuid references public.saved_view_profiles_deep(id) on delete cascade,
  rule_name text not null,
  target_module text not null,
  filter_logic jsonb not null default '{}'::jsonb,
  ai_assisted boolean not null default false,
  requires_manager_review boolean not null default false,
  status text not null default 'draft' check (status in ('draft','active','paused','archived')),
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.record_tag_labels_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  label_name text not null,
  label_key text not null,
  label_description text not null default '',
  target_modules jsonb not null default '[]'::jsonb,
  is_system_label boolean not null default false,
  is_active boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, label_key)
);

create table if not exists public.record_tag_assignments_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  tag_label_id uuid not null references public.record_tag_labels_deep(id) on delete cascade,
  target_module text not null,
  target_record_id uuid not null,
  assigned_by uuid not null default auth.uid(),
  assigned_to_user_id uuid,
  note text not null default '',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique(company_id, tag_label_id, target_module, target_record_id)
);

create table if not exists public.bulk_action_visibility_rules_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  action_key text not null,
  action_label text not null,
  target_module text not null,
  role_visibility jsonb not null default '[]'::jsonb,
  requires_manager_approval boolean not null default true,
  is_enabled boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, action_key, target_module)
);

create table if not exists public.activity_stream_dashboard_cards_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  dashboard_key text not null,
  card_title text not null,
  source_stream_key text not null,
  target_role text not null default 'all',
  max_items integer not null default 10 check (max_items between 1 and 100),
  priority_filter text not null default 'all' check (priority_filter in ('all','normal_and_above','high_and_critical','critical_only')),
  is_enabled boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, dashboard_key, source_stream_key, target_role)
);

create index if not exists idx_universal_activity_feed_items_deep_company_occurred on public.universal_activity_feed_items_deep(company_id, occurred_at desc);
create index if not exists idx_universal_activity_feed_items_deep_job on public.universal_activity_feed_items_deep(company_id, job_id);
create index if not exists idx_activity_feed_subscriptions_deep_user on public.activity_feed_subscriptions_deep(company_id, user_id);
create index if not exists idx_saved_view_profiles_deep_owner on public.saved_view_profiles_deep(company_id, owner_user_id, target_module);
create index if not exists idx_smart_filter_rules_deep_company_module on public.smart_filter_rules_deep(company_id, target_module);
create index if not exists idx_record_tag_assignments_deep_target on public.record_tag_assignments_deep(company_id, target_module, target_record_id);
create index if not exists idx_bulk_action_visibility_rules_deep_module on public.bulk_action_visibility_rules_deep(company_id, target_module);
create index if not exists idx_activity_stream_dashboard_cards_deep_company on public.activity_stream_dashboard_cards_deep(company_id, dashboard_key);

alter table public.universal_activity_feed_items_deep enable row level security;
alter table public.activity_feed_subscriptions_deep enable row level security;
alter table public.saved_view_profiles_deep enable row level security;
alter table public.smart_filter_rules_deep enable row level security;
alter table public.record_tag_labels_deep enable row level security;
alter table public.record_tag_assignments_deep enable row level security;
alter table public.bulk_action_visibility_rules_deep enable row level security;
alter table public.activity_stream_dashboard_cards_deep enable row level security;

revoke all on public.universal_activity_feed_items_deep from anon, authenticated;
revoke all on public.activity_feed_subscriptions_deep from anon, authenticated;
revoke all on public.saved_view_profiles_deep from anon, authenticated;
revoke all on public.smart_filter_rules_deep from anon, authenticated;
revoke all on public.record_tag_labels_deep from anon, authenticated;
revoke all on public.record_tag_assignments_deep from anon, authenticated;
revoke all on public.bulk_action_visibility_rules_deep from anon, authenticated;
revoke all on public.activity_stream_dashboard_cards_deep from anon, authenticated;

grant select, insert, update on public.universal_activity_feed_items_deep to authenticated;
grant select, insert, update on public.activity_feed_subscriptions_deep to authenticated;
grant select, insert, update on public.saved_view_profiles_deep to authenticated;
grant select, insert, update on public.smart_filter_rules_deep to authenticated;
grant select, insert, update on public.record_tag_labels_deep to authenticated;
grant select, insert, update on public.record_tag_assignments_deep to authenticated;
grant select, insert, update on public.bulk_action_visibility_rules_deep to authenticated;
grant select, insert, update on public.activity_stream_dashboard_cards_deep to authenticated;

-- RLS policies are applied in the live migration to allow company-scoped access,
-- personal saved-view control, manager-only company/role defaults, and manager-reviewed AI filters/actions.
