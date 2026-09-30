-- HAMRIQ operations control layer
-- Implements task engine, manager approval center, activity feed, saved views,
-- tags / smart labels, notifications, and notification preferences.

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid,
  contact_id uuid,
  title text not null,
  description text not null default '',
  priority text not null default 'normal',
  status text not null default 'open',
  assigned_to uuid not null,
  created_by uuid not null default auth.uid(),
  due_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,job_id) references public.jobs(company_id,id),
  foreign key(company_id,contact_id) references public.contacts(company_id,id),
  foreign key(company_id,assigned_to) references public.users(company_id,id),
  foreign key(company_id,created_by) references public.users(company_id,id),
  check(priority in ('low','normal','high','urgent')),
  check(status in ('open','in_progress','blocked','completed','cancelled'))
);
create index if not exists tasks_assigned_due on public.tasks(company_id,assigned_to,due_at) where completed_at is null;

create table if not exists public.approval_requests (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid,
  request_type text not null,
  title text not null,
  details jsonb not null default '{}'::jsonb,
  dollar_impact_cents bigint,
  status text not null default 'pending',
  requested_by uuid not null default auth.uid(),
  decided_by uuid,
  decided_at timestamptz,
  decision_note text not null default '',
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,job_id) references public.jobs(company_id,id),
  foreign key(company_id,requested_by) references public.users(company_id,id),
  foreign key(company_id,decided_by) references public.users(company_id,id),
  check(status in ('pending','approved','rejected','sent_back','cancelled'))
);
create index if not exists approvals_status on public.approval_requests(company_id,status,created_at desc);

create table if not exists public.activity_feed (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  actor_id uuid,
  job_id uuid,
  contact_id uuid,
  activity_type text not null,
  title text not null,
  body text not null default '',
  urgency text not null default 'normal',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,actor_id) references public.users(company_id,id),
  foreign key(company_id,job_id) references public.jobs(company_id,id),
  foreign key(company_id,contact_id) references public.contacts(company_id,id),
  check(urgency in ('low','normal','high','critical'))
);
create index if not exists activity_company_time on public.activity_feed(company_id,created_at desc);

create table if not exists public.saved_views (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  owner_id uuid,
  name text not null,
  scope text not null default 'personal',
  surface text not null,
  filters jsonb not null default '{}'::jsonb,
  is_smart boolean not null default false,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,owner_id) references public.users(company_id,id),
  foreign key(company_id,created_by) references public.users(company_id,id),
  check(scope in ('personal','team','company'))
);

create table if not exists public.tags (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  name text not null,
  color text not null default '#64748b',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  unique(company_id,id),
  unique(company_id,name),
  foreign key(company_id,created_by) references public.users(company_id,id)
);

create table if not exists public.record_tags (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  tag_id uuid not null,
  entity_type text not null,
  entity_id uuid not null,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  unique(company_id,tag_id,entity_type,entity_id),
  foreign key(company_id,tag_id) references public.tags(company_id,id),
  foreign key(company_id,created_by) references public.users(company_id,id),
  check(entity_type in ('contact','job','claim','property','route'))
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  user_id uuid not null,
  title text not null,
  body text not null default '',
  category text not null,
  priority text not null default 'normal',
  deep_link text not null default '',
  read_at timestamptz,
  created_at timestamptz not null default now(),
  unique(company_id,id),
  foreign key(company_id,user_id) references public.users(company_id,id),
  check(priority in ('low','normal','high','critical'))
);
create index if not exists notifications_user_unread on public.notifications(company_id,user_id,created_at desc) where read_at is null;

create table if not exists public.notification_preferences (
  company_id uuid not null references public.companies(id),
  user_id uuid not null,
  category text not null,
  enabled boolean not null default true,
  push_enabled boolean not null default true,
  email_enabled boolean not null default false,
  quiet_hours jsonb not null default '{}'::jsonb,
  primary key(company_id,user_id,category),
  foreign key(company_id,user_id) references public.users(company_id,id)
);

alter table public.tasks enable row level security;
alter table public.approval_requests enable row level security;
alter table public.activity_feed enable row level security;
alter table public.saved_views enable row level security;
alter table public.tags enable row level security;
alter table public.record_tags enable row level security;
alter table public.notifications enable row level security;
alter table public.notification_preferences enable row level security;

revoke all on public.tasks,public.approval_requests,public.activity_feed,public.saved_views,public.tags,public.record_tags,public.notifications,public.notification_preferences from anon,authenticated;
grant select,insert,update on public.tasks,public.approval_requests,public.activity_feed,public.saved_views,public.tags,public.record_tags,public.notifications,public.notification_preferences to authenticated;

create policy tasks_read on public.tasks for select to authenticated using (private.company_access(company_id) and (private.is_manager(company_id) or assigned_to=(select auth.uid()) or created_by=(select auth.uid())));
create policy tasks_insert on public.tasks for insert to authenticated with check (private.company_access(company_id) and (private.is_manager(company_id) or assigned_to=(select auth.uid()) or created_by=(select auth.uid())) and created_by=(select auth.uid()));
create policy tasks_update on public.tasks for update to authenticated using (private.company_access(company_id) and (private.is_manager(company_id) or assigned_to=(select auth.uid()) or created_by=(select auth.uid()))) with check (private.company_access(company_id) and (private.is_manager(company_id) or assigned_to=(select auth.uid()) or created_by=(select auth.uid())));

create policy approvals_read on public.approval_requests for select to authenticated using (private.company_access(company_id) and (private.is_manager(company_id) or requested_by=(select auth.uid())));
create policy approvals_insert on public.approval_requests for insert to authenticated with check (private.company_access(company_id) and requested_by=(select auth.uid())) ;
create policy approvals_update on public.approval_requests for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy activity_read on public.activity_feed for select to authenticated using (private.company_access(company_id) and (private.is_manager(company_id) or actor_id=(select auth.uid()) or (job_id is not null and private.can_job(company_id,job_id)) or (contact_id is not null and private.can_contact(company_id,contact_id))));
create policy activity_insert on public.activity_feed for insert to authenticated with check (private.company_access(company_id));

create policy saved_views_read on public.saved_views for select to authenticated using (private.company_access(company_id) and (scope='company' or private.is_manager(company_id) or owner_id=(select auth.uid()) or created_by=(select auth.uid())));
create policy saved_views_write on public.saved_views for insert to authenticated with check (private.company_access(company_id) and created_by=(select auth.uid()) and (scope='personal' or private.is_manager(company_id)));
create policy saved_views_update on public.saved_views for update to authenticated using (private.company_access(company_id) and (private.is_manager(company_id) or created_by=(select auth.uid()))) with check (private.company_access(company_id) and (private.is_manager(company_id) or created_by=(select auth.uid())));

create policy tags_read on public.tags for select to authenticated using (private.company_access(company_id));
create policy tags_write on public.tags for insert to authenticated with check (private.is_manager(company_id) and created_by=(select auth.uid()));
create policy tags_update on public.tags for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy record_tags_read on public.record_tags for select to authenticated using (private.company_access(company_id));
create policy record_tags_write on public.record_tags for insert to authenticated with check (private.company_access(company_id) and created_by=(select auth.uid()));
create policy record_tags_update on public.record_tags for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy notifications_read on public.notifications for select to authenticated using (private.company_access(company_id) and user_id=(select auth.uid()));
create policy notifications_insert on public.notifications for insert to authenticated with check (private.company_access(company_id));
create policy notifications_update on public.notifications for update to authenticated using (private.company_access(company_id) and user_id=(select auth.uid())) with check (private.company_access(company_id) and user_id=(select auth.uid())) ;
create policy notification_preferences_read on public.notification_preferences for select to authenticated using (private.company_access(company_id) and (private.is_manager(company_id) or user_id=(select auth.uid())));
create policy notification_preferences_write on public.notification_preferences for insert to authenticated with check (private.company_access(company_id) and user_id=(select auth.uid()));
create policy notification_preferences_update on public.notification_preferences for update to authenticated using (private.company_access(company_id) and user_id=(select auth.uid())) with check (private.company_access(company_id) and user_id=(select auth.uid())) ;
