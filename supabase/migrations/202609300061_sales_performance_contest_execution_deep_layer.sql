-- HAMRIQ sales performance / contest execution deep layer
-- Adds leaderboards, contests, rep achievement tracking, recognition, coaching tasks, quota tracking, and review snapshots.

create table if not exists public.sales_contest_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  contest_name text not null,
  contest_type text not null default 'sales' check (contest_type in ('sales','appointments','inspections','contracts','collections','production','custom')),
  status text not null default 'draft' check (status in ('draft','active','paused','completed','cancelled')),
  starts_at timestamptz,
  ends_at timestamptz,
  rules jsonb not null default '{}'::jsonb,
  prize_details jsonb not null default '{}'::jsonb,
  manager_notes text not null default '',
  ai_summary text not null default '',
  requires_human_review boolean not null default true,
  is_active boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.sales_leaderboard_snapshots_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  contest_id uuid references public.sales_contest_runs_deep(id) on delete set null,
  snapshot_name text not null default 'Leaderboard Snapshot',
  snapshot_period text not null default 'weekly' check (snapshot_period in ('daily','weekly','monthly','quarterly','contest','custom')),
  period_start date,
  period_end date,
  rankings jsonb not null default '[]'::jsonb,
  metric_totals jsonb not null default '{}'::jsonb,
  manager_notes text not null default '',
  ai_summary text not null default '',
  requires_human_review boolean not null default true,
  is_active boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.rep_quota_tracking_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  rep_user_id uuid not null,
  quota_period text not null default 'monthly' check (quota_period in ('weekly','monthly','quarterly','annual','custom')),
  period_start date not null,
  period_end date not null,
  quota_type text not null default 'revenue' check (quota_type in ('revenue','contracts','inspections','appointments','collections','custom')),
  target_value numeric not null default 0,
  current_value numeric not null default 0,
  percent_to_goal numeric not null default 0,
  status text not null default 'tracking' check (status in ('tracking','at_risk','on_track','exceeded','closed')),
  manager_notes text not null default '',
  ai_summary text not null default '',
  requires_human_review boolean not null default true,
  is_active boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.rep_achievement_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  rep_user_id uuid not null,
  contest_id uuid references public.sales_contest_runs_deep(id) on delete set null,
  achievement_type text not null default 'milestone' check (achievement_type in ('milestone','badge','contest_win','quota_hit','streak','manager_award','custom')),
  achievement_name text not null,
  achievement_details jsonb not null default '{}'::jsonb,
  awarded_at timestamptz not null default now(),
  awarded_by uuid default auth.uid(),
  visibility text not null default 'company' check (visibility in ('private','team','company')),
  manager_notes text not null default '',
  ai_summary text not null default '',
  requires_human_review boolean not null default true,
  is_active boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.rep_recognition_posts_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  rep_user_id uuid not null,
  achievement_event_id uuid references public.rep_achievement_events_deep(id) on delete set null,
  title text not null,
  body text not null default '',
  status text not null default 'draft' check (status in ('draft','review_needed','approved','posted','archived')),
  post_channel text not null default 'internal' check (post_channel in ('internal','team','company','external')),
  approved_by uuid,
  approved_at timestamptz,
  manager_notes text not null default '',
  ai_summary text not null default '',
  requires_human_review boolean not null default true,
  is_active boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.sales_coaching_task_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  rep_user_id uuid not null,
  related_job_id uuid references public.jobs(id) on delete set null,
  task_type text not null default 'coaching' check (task_type in ('coaching','roleplay','objection_practice','followup_review','pipeline_review','custom')),
  task_title text not null,
  task_status text not null default 'open' check (task_status in ('open','in_progress','completed','skipped','cancelled')),
  due_at timestamptz,
  completed_at timestamptz,
  coaching_notes text not null default '',
  ai_summary text not null default '',
  requires_human_review boolean not null default true,
  is_active boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.performance_review_snapshots_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  rep_user_id uuid not null,
  review_period text not null default 'monthly' check (review_period in ('weekly','monthly','quarterly','annual','custom')),
  period_start date not null,
  period_end date not null,
  scorecard jsonb not null default '{}'::jsonb,
  strengths jsonb not null default '[]'::jsonb,
  improvement_areas jsonb not null default '[]'::jsonb,
  manager_notes text not null default '',
  rep_acknowledged_at timestamptz,
  manager_reviewed_at timestamptz,
  ai_summary text not null default '',
  requires_human_review boolean not null default true,
  is_active boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.sales_performance_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  rep_user_id uuid,
  related_job_id uuid references public.jobs(id) on delete set null,
  event_type text not null,
  event_title text not null,
  event_payload jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

alter table public.sales_contest_runs_deep enable row level security;
alter table public.sales_leaderboard_snapshots_deep enable row level security;
alter table public.rep_quota_tracking_deep enable row level security;
alter table public.rep_achievement_events_deep enable row level security;
alter table public.rep_recognition_posts_deep enable row level security;
alter table public.sales_coaching_task_runs_deep enable row level security;
alter table public.performance_review_snapshots_deep enable row level security;
alter table public.sales_performance_activity_events_deep enable row level security;

-- Live database includes indexes, grants, and RLS policies for manager control, rep-owned visibility, and job-scoped access.