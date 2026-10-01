create table if not exists public.login_security_policy_configs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  policy_name text not null,
  status text not null default 'draft' check (status in ('draft','active','disabled','archived')),
  require_mfa boolean not null default false,
  allow_trusted_devices boolean not null default true,
  max_failed_attempts integer not null default 5,
  lockout_minutes integer not null default 30,
  session_timeout_minutes integer not null default 720,
  password_min_length integer not null default 12,
  password_requirements jsonb not null default '{}'::jsonb,
  applies_to_roles jsonb not null default '[]'::jsonb,
  manager_review_required boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.trusted_device_records_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null,
  device_label text not null default 'Unnamed device',
  device_fingerprint_hash text,
  platform text,
  browser text,
  trust_status text not null default 'pending' check (trust_status in ('pending','trusted','revoked','expired','blocked')),
  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz,
  expires_at timestamptz,
  approved_by uuid,
  revoked_by uuid,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.mfa_enrollment_records_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null,
  factor_type text not null default 'totp' check (factor_type in ('totp','sms','email','passkey','backup_code','other')),
  enrollment_status text not null default 'pending' check (enrollment_status in ('pending','active','disabled','revoked','reset_required')),
  enrolled_at timestamptz,
  last_verified_at timestamptz,
  reset_requested_at timestamptz,
  reset_approved_by uuid,
  manager_review_required boolean not null default false,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.login_attempt_risk_checks_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid,
  attempted_email text,
  attempt_status text not null default 'observed' check (attempt_status in ('observed','allowed','challenged','blocked','locked_out','manager_review')),
  risk_level text not null default 'low' check (risk_level in ('low','medium','high','critical')),
  risk_reasons jsonb not null default '[]'::jsonb,
  ip_hash text,
  approximate_location text,
  device_id uuid,
  requires_manager_review boolean not null default false,
  reviewed_by uuid,
  reviewed_at timestamptz,
  review_notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.session_security_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null,
  session_label text,
  event_type text not null default 'session_started' check (event_type in ('session_started','session_extended','session_expired','session_revoked','token_refresh','permission_changed','suspicious_activity','forced_logout')),
  risk_level text not null default 'low' check (risk_level in ('low','medium','high','critical')),
  event_context jsonb not null default '{}'::jsonb,
  action_taken text not null default 'logged',
  manager_review_required boolean not null default false,
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.account_lockout_records_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid,
  attempted_email text,
  lockout_reason text not null default 'failed_login_attempts',
  status text not null default 'active' check (status in ('active','released','expired','manager_review','blocked')),
  failed_attempt_count integer not null default 0,
  locked_at timestamptz not null default now(),
  unlock_after timestamptz,
  released_by uuid,
  released_at timestamptz,
  release_notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.security_review_queue_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  subject_user_id uuid,
  source_table text not null,
  source_record_id uuid,
  review_type text not null default 'security_review' check (review_type in ('security_review','login_risk','device_trust','mfa_reset','lockout_release','session_revocation','policy_change')),
  priority text not null default 'normal' check (priority in ('low','normal','high','urgent')),
  status text not null default 'open' check (status in ('open','in_review','approved','denied','resolved','dismissed')),
  summary text not null default '',
  recommended_action text not null default '',
  assigned_manager_id uuid,
  resolved_by uuid,
  resolved_at timestamptz,
  resolution_notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.security_login_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  actor_user_id uuid not null default auth.uid(),
  target_user_id uuid,
  event_type text not null,
  event_summary text not null default '',
  source_table text,
  source_record_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create index if not exists idx_login_security_policy_configs_company_status on public.login_security_policy_configs_deep(company_id,status);
create index if not exists idx_trusted_device_records_company_user on public.trusted_device_records_deep(company_id,user_id,trust_status);
create index if not exists idx_mfa_enrollment_records_company_user on public.mfa_enrollment_records_deep(company_id,user_id,enrollment_status);
create index if not exists idx_login_attempt_risk_checks_company_risk on public.login_attempt_risk_checks_deep(company_id,risk_level,attempt_status);
create index if not exists idx_session_security_events_company_user on public.session_security_events_deep(company_id,user_id,event_type);
create index if not exists idx_account_lockout_records_company_status on public.account_lockout_records_deep(company_id,status);
create index if not exists idx_security_review_queue_company_status on public.security_review_queue_deep(company_id,status,priority);
create index if not exists idx_security_login_activity_events_company_created on public.security_login_activity_events_deep(company_id,created_at desc);

alter table public.login_security_policy_configs_deep enable row level security;
alter table public.trusted_device_records_deep enable row level security;
alter table public.mfa_enrollment_records_deep enable row level security;
alter table public.login_attempt_risk_checks_deep enable row level security;
alter table public.session_security_events_deep enable row level security;
alter table public.account_lockout_records_deep enable row level security;
alter table public.security_review_queue_deep enable row level security;
alter table public.security_login_activity_events_deep enable row level security;

revoke all on public.login_security_policy_configs_deep from anon, authenticated;
revoke all on public.trusted_device_records_deep from anon, authenticated;
revoke all on public.mfa_enrollment_records_deep from anon, authenticated;
revoke all on public.login_attempt_risk_checks_deep from anon, authenticated;
revoke all on public.session_security_events_deep from anon, authenticated;
revoke all on public.account_lockout_records_deep from anon, authenticated;
revoke all on public.security_review_queue_deep from anon, authenticated;
revoke all on public.security_login_activity_events_deep from anon, authenticated;

grant select, insert, update on public.login_security_policy_configs_deep to authenticated;
grant select, insert, update on public.trusted_device_records_deep to authenticated;
grant select, insert, update on public.mfa_enrollment_records_deep to authenticated;
grant select, insert, update on public.login_attempt_risk_checks_deep to authenticated;
grant select, insert, update on public.session_security_events_deep to authenticated;
grant select, insert, update on public.account_lockout_records_deep to authenticated;
grant select, insert, update on public.security_review_queue_deep to authenticated;
grant select, insert, update on public.security_login_activity_events_deep to authenticated;

create policy login_security_policy_configs_manager_all on public.login_security_policy_configs_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy login_security_policy_configs_company_read on public.login_security_policy_configs_deep for select to authenticated using (private.company_access(company_id));
create policy trusted_device_records_manager_all on public.trusted_device_records_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy trusted_device_records_user_own on public.trusted_device_records_deep for all to authenticated using (private.company_access(company_id) and user_id = auth.uid()) with check (private.company_access(company_id) and user_id = auth.uid());
create policy mfa_enrollment_records_manager_all on public.mfa_enrollment_records_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy mfa_enrollment_records_user_own on public.mfa_enrollment_records_deep for all to authenticated using (private.company_access(company_id) and user_id = auth.uid()) with check (private.company_access(company_id) and user_id = auth.uid());
create policy login_attempt_risk_checks_manager_all on public.login_attempt_risk_checks_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy login_attempt_risk_checks_company_insert on public.login_attempt_risk_checks_deep for insert to authenticated with check (private.company_access(company_id));
create policy session_security_events_manager_all on public.session_security_events_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy session_security_events_user_own on public.session_security_events_deep for all to authenticated using (private.company_access(company_id) and user_id = auth.uid()) with check (private.company_access(company_id) and user_id = auth.uid());
create policy account_lockout_records_manager_all on public.account_lockout_records_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy account_lockout_records_company_insert on public.account_lockout_records_deep for insert to authenticated with check (private.company_access(company_id));
create policy security_review_queue_manager_all on public.security_review_queue_deep for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy security_review_queue_company_insert on public.security_review_queue_deep for insert to authenticated with check (private.company_access(company_id));
create policy security_login_activity_events_manager_read on public.security_login_activity_events_deep for select to authenticated using (private.is_manager(company_id));
create policy security_login_activity_events_company_insert on public.security_login_activity_events_deep for insert to authenticated with check (private.company_access(company_id));
