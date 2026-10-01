create table if not exists public.permission_catalog_entries_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  permission_key text not null,
  permission_group text not null default 'general',
  display_name text not null,
  description text not null default '',
  risk_level text not null default 'standard' check (risk_level in ('low','standard','high','critical')),
  requires_manager_review boolean not null default false,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, permission_key)
);

create table if not exists public.custom_role_profiles_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  role_name text not null,
  role_type text not null default 'custom' check (role_type in ('system','manager','rep','production','office','custom')),
  description text not null default '',
  default_dashboard_profile_id uuid,
  can_be_assigned_by_manager boolean not null default true,
  is_company_default boolean not null default false,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, role_name)
);

create table if not exists public.role_permission_grants_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  role_profile_id uuid not null references public.custom_role_profiles_deep(id) on delete cascade,
  permission_catalog_entry_id uuid references public.permission_catalog_entries_deep(id) on delete set null,
  permission_key text not null,
  access_level text not null default 'view' check (access_level in ('none','view','create','edit','approve','admin')),
  grant_scope text not null default 'company' check (grant_scope in ('own','assigned','team','branch','company')),
  requires_approval boolean not null default false,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_role_memberships_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null,
  role_profile_id uuid not null references public.custom_role_profiles_deep(id) on delete cascade,
  membership_status text not null default 'active' check (membership_status in ('pending','active','suspended','removed')),
  assigned_by uuid not null default auth.uid(),
  starts_at timestamptz not null default now(),
  ends_at timestamptz,
  notes text not null default '',
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.field_level_visibility_rules_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  role_profile_id uuid references public.custom_role_profiles_deep(id) on delete cascade,
  target_module text not null,
  target_table text not null default '',
  target_field text not null,
  visibility_level text not null default 'visible' check (visibility_level in ('hidden','masked','readonly','visible','editable')),
  applies_to_scope text not null default 'role' check (applies_to_scope in ('role','user','company')),
  requires_manager_review boolean not null default false,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.record_access_exception_grants_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  target_user_id uuid not null,
  target_record_type text not null,
  target_record_id uuid,
  access_level text not null default 'view' check (access_level in ('view','edit','approve','admin')),
  reason text not null default '',
  expires_at timestamptz,
  approval_status text not null default 'pending' check (approval_status in ('pending','approved','denied','revoked','expired')),
  approved_by uuid,
  approved_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.permission_change_approval_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  requested_by uuid not null default auth.uid(),
  request_type text not null default 'role_change' check (request_type in ('role_change','permission_grant','permission_revoke','field_visibility','access_exception')),
  target_user_id uuid,
  target_role_profile_id uuid references public.custom_role_profiles_deep(id) on delete set null,
  approval_status text not null default 'pending' check (approval_status in ('pending','approved','denied','cancelled','applied')),
  before_snapshot jsonb not null default '{}'::jsonb,
  requested_changes jsonb not null default '{}'::jsonb,
  manager_review_notes text not null default '',
  reviewed_by uuid,
  reviewed_at timestamptz,
  applied_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.security_permission_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  actor_user_id uuid not null default auth.uid(),
  event_type text not null,
  target_type text not null default '',
  target_id uuid,
  summary text not null default '',
  risk_level text not null default 'standard' check (risk_level in ('low','standard','high','critical')),
  event_payload jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create index if not exists permission_catalog_entries_deep_company_idx on public.permission_catalog_entries_deep(company_id, permission_group, is_active);
create index if not exists custom_role_profiles_deep_company_idx on public.custom_role_profiles_deep(company_id, role_type, is_active);
create index if not exists role_permission_grants_deep_company_role_idx on public.role_permission_grants_deep(company_id, role_profile_id, is_active);
create index if not exists user_role_memberships_deep_company_user_idx on public.user_role_memberships_deep(company_id, user_id, membership_status);
create index if not exists field_level_visibility_rules_deep_company_module_idx on public.field_level_visibility_rules_deep(company_id, target_module, target_field, is_active);
create index if not exists record_access_exception_grants_deep_company_user_idx on public.record_access_exception_grants_deep(company_id, target_user_id, approval_status);
create index if not exists permission_change_approval_runs_deep_company_status_idx on public.permission_change_approval_runs_deep(company_id, approval_status, request_type);
create index if not exists security_permission_activity_events_deep_company_created_idx on public.security_permission_activity_events_deep(company_id, created_at desc);

alter table public.permission_catalog_entries_deep enable row level security;
alter table public.custom_role_profiles_deep enable row level security;
alter table public.role_permission_grants_deep enable row level security;
alter table public.user_role_memberships_deep enable row level security;
alter table public.field_level_visibility_rules_deep enable row level security;
alter table public.record_access_exception_grants_deep enable row level security;
alter table public.permission_change_approval_runs_deep enable row level security;
alter table public.security_permission_activity_events_deep enable row level security;

revoke all on public.permission_catalog_entries_deep from anon, authenticated;
revoke all on public.custom_role_profiles_deep from anon, authenticated;
revoke all on public.role_permission_grants_deep from anon, authenticated;
revoke all on public.user_role_memberships_deep from anon, authenticated;
revoke all on public.field_level_visibility_rules_deep from anon, authenticated;
revoke all on public.record_access_exception_grants_deep from anon, authenticated;
revoke all on public.permission_change_approval_runs_deep from anon, authenticated;
revoke all on public.security_permission_activity_events_deep from anon, authenticated;

grant select, insert, update on public.permission_catalog_entries_deep to authenticated;
grant select, insert, update on public.custom_role_profiles_deep to authenticated;
grant select, insert, update on public.role_permission_grants_deep to authenticated;
grant select, insert, update on public.user_role_memberships_deep to authenticated;
grant select, insert, update on public.field_level_visibility_rules_deep to authenticated;
grant select, insert, update on public.record_access_exception_grants_deep to authenticated;
grant select, insert, update on public.permission_change_approval_runs_deep to authenticated;
grant select, insert on public.security_permission_activity_events_deep to authenticated;

create policy permission_catalog_entries_deep_select on public.permission_catalog_entries_deep for select using (private.company_access(company_id));
create policy permission_catalog_entries_deep_manager_insert on public.permission_catalog_entries_deep for insert with check (private.is_manager(company_id));
create policy permission_catalog_entries_deep_manager_update on public.permission_catalog_entries_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy custom_role_profiles_deep_select on public.custom_role_profiles_deep for select using (private.company_access(company_id));
create policy custom_role_profiles_deep_manager_insert on public.custom_role_profiles_deep for insert with check (private.is_manager(company_id));
create policy custom_role_profiles_deep_manager_update on public.custom_role_profiles_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy role_permission_grants_deep_select on public.role_permission_grants_deep for select using (private.company_access(company_id));
create policy role_permission_grants_deep_manager_insert on public.role_permission_grants_deep for insert with check (private.is_manager(company_id));
create policy role_permission_grants_deep_manager_update on public.role_permission_grants_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy user_role_memberships_deep_select on public.user_role_memberships_deep for select using (private.company_access(company_id) or user_id = auth.uid());
create policy user_role_memberships_deep_manager_insert on public.user_role_memberships_deep for insert with check (private.is_manager(company_id));
create policy user_role_memberships_deep_manager_update on public.user_role_memberships_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy field_level_visibility_rules_deep_select on public.field_level_visibility_rules_deep for select using (private.company_access(company_id));
create policy field_level_visibility_rules_deep_manager_insert on public.field_level_visibility_rules_deep for insert with check (private.is_manager(company_id));
create policy field_level_visibility_rules_deep_manager_update on public.field_level_visibility_rules_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy record_access_exception_grants_deep_select on public.record_access_exception_grants_deep for select using (private.company_access(company_id) or target_user_id = auth.uid());
create policy record_access_exception_grants_deep_company_insert on public.record_access_exception_grants_deep for insert with check (private.company_access(company_id));
create policy record_access_exception_grants_deep_manager_update on public.record_access_exception_grants_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy permission_change_approval_runs_deep_select on public.permission_change_approval_runs_deep for select using (private.company_access(company_id) or requested_by = auth.uid() or target_user_id = auth.uid());
create policy permission_change_approval_runs_deep_company_insert on public.permission_change_approval_runs_deep for insert with check (private.company_access(company_id));
create policy permission_change_approval_runs_deep_manager_update on public.permission_change_approval_runs_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy security_permission_activity_events_deep_select on public.security_permission_activity_events_deep for select using (private.company_access(company_id));
create policy security_permission_activity_events_deep_company_insert on public.security_permission_activity_events_deep for insert with check (private.company_access(company_id));
