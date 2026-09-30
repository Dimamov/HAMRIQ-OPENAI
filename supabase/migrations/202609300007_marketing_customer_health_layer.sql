-- HAMRIQ marketing, customer portal, appointment confirmation, and system health layer.

create table if not exists public.campaigns (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  name text not null,
  campaign_type text not null,
  audience_filter jsonb not null default '{}'::jsonb,
  status text not null default 'draft',
  budget_cents bigint not null default 0,
  spend_cents bigint not null default 0,
  created_by uuid not null default auth.uid(),
  approved_by uuid,
  approved_at timestamptz,
  launched_at timestamptz,
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,created_by) references public.users(company_id,id),
  foreign key(company_id,approved_by) references public.users(company_id,id),
  check(campaign_type in ('email','sms','direct_mail','qr','neighborhood','referral','past_customer','storm')),
  check(status in ('draft','pending_approval','approved','active','paused','completed','cancelled'))
);

create table if not exists public.campaign_events (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  campaign_id uuid not null,
  contact_id uuid,
  job_id uuid,
  event_type text not null,
  value_cents bigint,
  metadata jsonb not null default '{}'::jsonb,
  occurred_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,campaign_id) references public.campaigns(company_id,id),
  foreign key(company_id,contact_id) references public.contacts(company_id,id),
  foreign key(company_id,job_id) references public.jobs(company_id,id)
);
create index if not exists campaign_events_campaign on public.campaign_events(company_id,campaign_id,occurred_at desc);

create table if not exists public.marketing_spend_entries (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  campaign_id uuid,
  source text not null,
  amount_cents bigint not null check(amount_cents >= 0),
  spent_on date not null,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,campaign_id) references public.campaigns(company_id,id),
  foreign key(company_id,created_by) references public.users(company_id,id)
);

create table if not exists public.customer_portal_tokens (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid not null,
  token_hash text not null,
  status text not null default 'active',
  visible_sections jsonb not null default '["appointments","scope","selections","documents","invoices","warranty"]'::jsonb,
  expires_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  unique(company_id,id),
  unique(token_hash),
  foreign key(company_id,job_id) references public.jobs(company_id,id),
  foreign key(company_id,created_by) references public.users(company_id,id),
  check(status in ('active','disabled','expired'))
);

create table if not exists public.customer_status_updates (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid not null,
  trigger_key text not null,
  channel text not null,
  status text not null default 'draft',
  message_body text not null,
  approved_by uuid,
  approved_at timestamptz,
  sent_at timestamptz,
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,job_id) references public.jobs(company_id,id),
  foreign key(company_id,approved_by) references public.users(company_id,id),
  check(channel in ('email','sms','portal')),
  check(status in ('draft','approved','sent','failed','cancelled'))
);

create table if not exists public.appointment_confirmations (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  appointment_id uuid not null references public.appointments(id),
  status text not null default 'pending',
  confirmation_channel text not null default 'sms',
  confirmed_at timestamptz,
  reschedule_requested_at timestamptz,
  created_at timestamptz not null default now(),
  unique(company_id,id),
  check(status in ('pending','confirmed','reschedule_requested','cancelled','no_show')),
  check(confirmation_channel in ('sms','email','portal','phone'))
);

create table if not exists public.system_health_events (
  id uuid primary key default gen_random_uuid(),
  company_id uuid references public.companies(id),
  service_key text not null,
  status text not null,
  impact_summary text not null default '',
  action_label text not null default '',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  check(status in ('operational','degraded','offline','action_required'))
);
create index if not exists system_health_service_time on public.system_health_events(service_key,created_at desc);

alter table public.campaigns enable row level security;
alter table public.campaign_events enable row level security;
alter table public.marketing_spend_entries enable row level security;
alter table public.customer_portal_tokens enable row level security;
alter table public.customer_status_updates enable row level security;
alter table public.appointment_confirmations enable row level security;
alter table public.system_health_events enable row level security;

revoke all on public.campaigns,public.campaign_events,public.marketing_spend_entries,public.customer_portal_tokens,public.customer_status_updates,public.appointment_confirmations,public.system_health_events from anon,authenticated;
grant select,insert,update on public.campaigns,public.campaign_events,public.marketing_spend_entries,public.customer_portal_tokens,public.customer_status_updates,public.appointment_confirmations,public.system_health_events to authenticated;

create policy campaigns_read on public.campaigns for select to authenticated using(private.company_access(company_id));
create policy campaigns_insert on public.campaigns for insert to authenticated with check(private.is_manager(company_id) and created_by=(select auth.uid()));
create policy campaigns_update on public.campaigns for update to authenticated using(private.is_manager(company_id)) with check(private.is_manager(company_id));
create policy campaign_events_read on public.campaign_events for select to authenticated using(private.company_access(company_id));
create policy campaign_events_insert on public.campaign_events for insert to authenticated with check(private.company_access(company_id));
create policy campaign_events_update on public.campaign_events for update to authenticated using(private.is_manager(company_id)) with check(private.is_manager(company_id));
create policy spend_read on public.marketing_spend_entries for select to authenticated using(private.is_manager(company_id));
create policy spend_insert on public.marketing_spend_entries for insert to authenticated with check(private.is_manager(company_id) and created_by=(select auth.uid()));
create policy spend_update on public.marketing_spend_entries for update to authenticated using(private.is_manager(company_id)) with check(private.is_manager(company_id));
create policy portal_tokens_read on public.customer_portal_tokens for select to authenticated using(private.can_job(company_id,job_id));
create policy portal_tokens_insert on public.customer_portal_tokens for insert to authenticated with check(private.can_job(company_id,job_id) and created_by=(select auth.uid()));
create policy portal_tokens_update on public.customer_portal_tokens for update to authenticated using(private.can_job(company_id,job_id)) with check(private.can_job(company_id,job_id));
create policy status_updates_read on public.customer_status_updates for select to authenticated using(private.can_job(company_id,job_id));
create policy status_updates_insert on public.customer_status_updates for insert to authenticated with check(private.can_job(company_id,job_id));
create policy status_updates_update on public.customer_status_updates for update to authenticated using(private.can_job(company_id,job_id)) with check(private.can_job(company_id,job_id));
create policy appointment_confirmations_read on public.appointment_confirmations for select to authenticated using(private.company_access(company_id));
create policy appointment_confirmations_write on public.appointment_confirmations for insert to authenticated with check(private.company_access(company_id));
create policy appointment_confirmations_update on public.appointment_confirmations for update to authenticated using(private.company_access(company_id)) with check(private.company_access(company_id));
create policy system_health_read on public.system_health_events for select to authenticated using(company_id is null or private.is_manager(company_id));
create policy system_health_write on public.system_health_events for insert to authenticated with check(company_id is null or private.is_manager(company_id));
