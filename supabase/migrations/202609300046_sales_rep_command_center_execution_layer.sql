-- HAMRIQ sales rep personal command-center execution layer
-- Adds rep-facing pipeline, follow-up, coaching, goals, and handoff readiness records.

create table if not exists public.rep_pipeline_snapshots_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  rep_user_id uuid not null,
  snapshot_date date not null default current_date,
  open_leads_count integer not null default 0,
  inspections_scheduled_count integer not null default 0,
  estimates_pending_count integer not null default 0,
  contracts_pending_count integer not null default 0,
  projected_revenue_cents bigint not null default 0,
  at_risk_leads_count integer not null default 0,
  ai_summary text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  unique(company_id, rep_user_id, snapshot_date)
);

create table if not exists public.rep_daily_action_plans_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  rep_user_id uuid not null,
  plan_date date not null default current_date,
  priority_summary text not null default '',
  suggested_route_id uuid null,
  target_doors integer not null default 0,
  target_calls integer not null default 0,
  target_followups integer not null default 0,
  hammy_generated boolean not null default false,
  manager_review_required boolean not null default false,
  status text not null default 'draft' check (status in ('draft','active','completed','skipped','manager_review')),
  completed_at timestamptz null,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, rep_user_id, plan_date)
);

create table if not exists public.rep_followup_queue_items_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  rep_user_id uuid not null,
  job_id uuid null references public.jobs(id) on delete set null,
  contact_id uuid null references public.contacts(id) on delete set null,
  queue_reason text not null default 'general_followup',
  due_at timestamptz not null default now(),
  priority text not null default 'normal' check (priority in ('low','normal','high','urgent')),
  suggested_message text not null default '',
  source_event text not null default '',
  status text not null default 'open' check (status in ('open','snoozed','completed','dismissed','converted')),
  completed_at timestamptz null,
  completed_note text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.rep_personal_goals_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  rep_user_id uuid not null,
  goal_period text not null default 'weekly' check (goal_period in ('daily','weekly','monthly','quarterly','annual')),
  period_start date not null,
  period_end date not null,
  goal_type text not null default 'revenue',
  target_value numeric(14,2) not null default 0,
  current_value numeric(14,2) not null default 0,
  unit_label text not null default '',
  visibility text not null default 'manager_and_rep' check (visibility in ('private','manager_and_rep','team_visible')),
  status text not null default 'active' check (status in ('active','met','missed','paused','cancelled')),
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.rep_objection_coaching_notes_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  rep_user_id uuid not null,
  job_id uuid null references public.jobs(id) on delete set null,
  objection_type text not null default 'general',
  customer_phrase text not null default '',
  recommended_response text not null default '',
  hammy_generated boolean not null default false,
  human_review_required boolean not null default true,
  reviewed_by uuid null,
  reviewed_at timestamptz null,
  rep_feedback text not null default '',
  outcome text not null default 'pending' check (outcome in ('pending','used','helpful','not_helpful','needs_manager')),
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.rep_handoff_readiness_checks_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  rep_user_id uuid not null,
  job_id uuid not null references public.jobs(id) on delete cascade,
  readiness_status text not null default 'not_ready' check (readiness_status in ('not_ready','needs_review','ready','handed_off','blocked')),
  missing_items jsonb not null default '[]'::jsonb,
  completed_items jsonb not null default '[]'::jsonb,
  manager_review_required boolean not null default true,
  reviewed_by uuid null,
  reviewed_at timestamptz null,
  handoff_note text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, job_id)
);

create table if not exists public.rep_command_center_preferences_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  rep_user_id uuid not null,
  default_view text not null default 'today',
  pinned_metrics jsonb not null default '[]'::jsonb,
  notification_preferences jsonb not null default '{}'::jsonb,
  hammy_voice_enabled boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, rep_user_id)
);

create table if not exists public.rep_win_loss_learning_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  rep_user_id uuid not null,
  job_id uuid null references public.jobs(id) on delete set null,
  event_type text not null default 'loss' check (event_type in ('win','loss','stalled','rescued')),
  reason text not null default '',
  competitor_name text not null default '',
  rep_notes text not null default '',
  ai_learning_summary text not null default '',
  use_for_ai_training boolean not null default false,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

-- RLS is enabled in production with policies that let managers see company records and reps manage their own command-center records.
