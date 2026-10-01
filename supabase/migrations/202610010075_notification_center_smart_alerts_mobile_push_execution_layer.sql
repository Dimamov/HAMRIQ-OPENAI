create table if not exists public.mobile_push_device_tokens_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null default auth.uid(),
  platform text not null default 'unknown' check (platform in ('ios','android','web','unknown')),
  device_label text not null default '',
  push_token_hash text not null default '',
  is_active boolean not null default true,
  last_seen_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.notification_preference_rules_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null default auth.uid(),
  channel text not null default 'push' check (channel in ('push','sms','email','in_app','voice')),
  category text not null default 'general',
  enabled boolean not null default true,
  quiet_hours_enabled boolean not null default false,
  quiet_hours_start time,
  quiet_hours_end time,
  digest_mode text not null default 'instant' check (digest_mode in ('instant','hourly','daily','manual')),
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.smart_alert_rule_configs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null,
  alert_category text not null default 'general',
  severity text not null default 'normal' check (severity in ('low','normal','high','critical')),
  trigger_conditions jsonb not null default '{}'::jsonb,
  target_roles jsonb not null default '[]'::jsonb,
  target_users jsonb not null default '[]'::jsonb,
  requires_manager_review boolean not null default false,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.smart_alert_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  rule_id uuid references public.smart_alert_rule_configs_deep(id) on delete set null,
  alert_title text not null,
  alert_body text not null default '',
  severity text not null default 'normal' check (severity in ('low','normal','high','critical')),
  status text not null default 'open' check (status in ('open','acknowledged','snoozed','resolved','dismissed')),
  assigned_user_id uuid,
  requires_manager_review boolean not null default false,
  manager_review_status text not null default 'not_required' check (manager_review_status in ('not_required','pending','approved','rejected')),
  payload jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.notification_delivery_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  alert_event_id uuid references public.smart_alert_events_deep(id) on delete cascade,
  recipient_user_id uuid not null,
  channel text not null default 'push' check (channel in ('push','sms','email','in_app','voice')),
  delivery_status text not null default 'queued' check (delivery_status in ('queued','sent','delivered','opened','clicked','failed','suppressed')),
  provider text not null default 'internal',
  provider_message_id text not null default '',
  failure_reason text not null default '',
  sent_at timestamptz,
  delivered_at timestamptz,
  opened_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.notification_read_receipts_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  alert_event_id uuid references public.smart_alert_events_deep(id) on delete cascade,
  user_id uuid not null default auth.uid(),
  read_at timestamptz not null default now(),
  action_taken text not null default 'read' check (action_taken in ('read','acknowledged','snoozed','resolved','dismissed','opened_record')),
  notes text not null default '',
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.manager_escalation_alerts_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  alert_event_id uuid references public.smart_alert_events_deep(id) on delete set null,
  escalation_type text not null default 'general',
  escalation_reason text not null default '',
  status text not null default 'pending' check (status in ('pending','reviewing','resolved','dismissed')),
  assigned_manager_id uuid,
  due_at timestamptz,
  resolved_at timestamptz,
  resolution_notes text not null default '',
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.notification_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  alert_event_id uuid references public.smart_alert_events_deep(id) on delete set null,
  event_type text not null,
  event_summary text not null default '',
  actor_user_id uuid default auth.uid(),
  payload jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_mobile_push_device_tokens_deep_company_user on public.mobile_push_device_tokens_deep(company_id, user_id);
create index if not exists idx_notification_preference_rules_deep_company_user on public.notification_preference_rules_deep(company_id, user_id);
create index if not exists idx_smart_alert_rule_configs_deep_company on public.smart_alert_rule_configs_deep(company_id, is_active);
create index if not exists idx_smart_alert_events_deep_company_status on public.smart_alert_events_deep(company_id, status, severity);
create index if not exists idx_notification_delivery_runs_deep_company_recipient on public.notification_delivery_runs_deep(company_id, recipient_user_id, delivery_status);
create index if not exists idx_notification_read_receipts_deep_company_user on public.notification_read_receipts_deep(company_id, user_id);
create index if not exists idx_manager_escalation_alerts_deep_company_status on public.manager_escalation_alerts_deep(company_id, status);
create index if not exists idx_notification_activity_events_deep_company on public.notification_activity_events_deep(company_id, created_at desc);

alter table public.mobile_push_device_tokens_deep enable row level security;
alter table public.notification_preference_rules_deep enable row level security;
alter table public.smart_alert_rule_configs_deep enable row level security;
alter table public.smart_alert_events_deep enable row level security;
alter table public.notification_delivery_runs_deep enable row level security;
alter table public.notification_read_receipts_deep enable row level security;
alter table public.manager_escalation_alerts_deep enable row level security;
alter table public.notification_activity_events_deep enable row level security;

revoke all on public.mobile_push_device_tokens_deep from anon, authenticated;
revoke all on public.notification_preference_rules_deep from anon, authenticated;
revoke all on public.smart_alert_rule_configs_deep from anon, authenticated;
revoke all on public.smart_alert_events_deep from anon, authenticated;
revoke all on public.notification_delivery_runs_deep from anon, authenticated;
revoke all on public.notification_read_receipts_deep from anon, authenticated;
revoke all on public.manager_escalation_alerts_deep from anon, authenticated;
revoke all on public.notification_activity_events_deep from anon, authenticated;

grant select, insert, update on public.mobile_push_device_tokens_deep to authenticated;
grant select, insert, update on public.notification_preference_rules_deep to authenticated;
grant select, insert, update on public.smart_alert_rule_configs_deep to authenticated;
grant select, insert, update on public.smart_alert_events_deep to authenticated;
grant select, insert, update on public.notification_delivery_runs_deep to authenticated;
grant select, insert, update on public.notification_read_receipts_deep to authenticated;
grant select, insert, update on public.manager_escalation_alerts_deep to authenticated;
grant select, insert, update on public.notification_activity_events_deep to authenticated;

create policy "mobile_push_device_tokens_deep_select" on public.mobile_push_device_tokens_deep for select using (private.company_access(company_id));
create policy "mobile_push_device_tokens_deep_insert" on public.mobile_push_device_tokens_deep for insert with check (private.company_access(company_id) and (user_id = auth.uid() or private.is_manager(company_id)));
create policy "mobile_push_device_tokens_deep_update" on public.mobile_push_device_tokens_deep for update using (private.company_access(company_id) and (user_id = auth.uid() or private.is_manager(company_id))) with check (private.company_access(company_id) and (user_id = auth.uid() or private.is_manager(company_id)));

create policy "notification_preference_rules_deep_select" on public.notification_preference_rules_deep for select using (private.company_access(company_id));
create policy "notification_preference_rules_deep_insert" on public.notification_preference_rules_deep for insert with check (private.company_access(company_id) and (user_id = auth.uid() or private.is_manager(company_id)));
create policy "notification_preference_rules_deep_update" on public.notification_preference_rules_deep for update using (private.company_access(company_id) and (user_id = auth.uid() or private.is_manager(company_id))) with check (private.company_access(company_id) and (user_id = auth.uid() or private.is_manager(company_id)));

create policy "smart_alert_rule_configs_deep_select" on public.smart_alert_rule_configs_deep for select using (private.company_access(company_id));
create policy "smart_alert_rule_configs_deep_insert" on public.smart_alert_rule_configs_deep for insert with check (private.is_manager(company_id));
create policy "smart_alert_rule_configs_deep_update" on public.smart_alert_rule_configs_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy "smart_alert_events_deep_select" on public.smart_alert_events_deep for select using (private.company_access(company_id) or private.can_job(company_id, job_id));
create policy "smart_alert_events_deep_insert" on public.smart_alert_events_deep for insert with check (private.company_access(company_id));
create policy "smart_alert_events_deep_update" on public.smart_alert_events_deep for update using (private.company_access(company_id) or private.is_manager(company_id)) with check (private.company_access(company_id) or private.is_manager(company_id));

create policy "notification_delivery_runs_deep_select" on public.notification_delivery_runs_deep for select using (private.company_access(company_id) and (recipient_user_id = auth.uid() or private.is_manager(company_id)));
create policy "notification_delivery_runs_deep_insert" on public.notification_delivery_runs_deep for insert with check (private.company_access(company_id));
create policy "notification_delivery_runs_deep_update" on public.notification_delivery_runs_deep for update using (private.company_access(company_id) and (recipient_user_id = auth.uid() or private.is_manager(company_id))) with check (private.company_access(company_id));

create policy "notification_read_receipts_deep_select" on public.notification_read_receipts_deep for select using (private.company_access(company_id));
create policy "notification_read_receipts_deep_insert" on public.notification_read_receipts_deep for insert with check (private.company_access(company_id) and (user_id = auth.uid() or private.is_manager(company_id)));
create policy "notification_read_receipts_deep_update" on public.notification_read_receipts_deep for update using (private.company_access(company_id) and (user_id = auth.uid() or private.is_manager(company_id))) with check (private.company_access(company_id));

create policy "manager_escalation_alerts_deep_select" on public.manager_escalation_alerts_deep for select using (private.company_access(company_id));
create policy "manager_escalation_alerts_deep_insert" on public.manager_escalation_alerts_deep for insert with check (private.company_access(company_id));
create policy "manager_escalation_alerts_deep_update" on public.manager_escalation_alerts_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy "notification_activity_events_deep_select" on public.notification_activity_events_deep for select using (private.company_access(company_id));
create policy "notification_activity_events_deep_insert" on public.notification_activity_events_deep for insert with check (private.company_access(company_id));
create policy "notification_activity_events_deep_update" on public.notification_activity_events_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));
