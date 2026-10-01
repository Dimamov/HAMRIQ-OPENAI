-- Prospecting script / objection tracking layer
-- Adds manager-approved door scripts, objection response tracking, AI suggestion review,
-- and coaching cards for canvassing talk tracks.

create table if not exists public.prospecting_script_templates_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  script_name text not null,
  script_type text not null default 'door_knock' check (script_type in ('door_knock','storm_area','follow_up','door_hanger','referral','rebuttal','other')),
  target_use text not null default 'general',
  script_body text not null default '',
  approved_status text not null default 'draft' check (approved_status in ('draft','manager_review','approved','retired')),
  approved_by uuid,
  approved_at timestamptz,
  is_default boolean not null default false,
  version_number integer not null default 1,
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.prospecting_objection_categories_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  category_name text not null,
  category_type text not null default 'general',
  default_response text not null default '',
  manager_notes text not null default '',
  is_active boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.prospecting_objection_response_library_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  objection_category_id uuid references public.prospecting_objection_categories_deep(id) on delete set null,
  response_title text not null,
  response_text text not null default '',
  tone text not null default 'professional',
  approved_status text not null default 'draft',
  approved_by uuid,
  approved_at timestamptz,
  usage_count integer not null default 0,
  success_count integer not null default 0,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.prospecting_rep_objection_logs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  prospecting_visit_id uuid,
  job_id uuid references public.jobs(id) on delete cascade,
  contact_id uuid references public.contacts(id) on delete set null,
  rep_user_id uuid not null default auth.uid(),
  objection_category_id uuid references public.prospecting_objection_categories_deep(id) on delete set null,
  objection_text text not null default '',
  response_used_id uuid references public.prospecting_objection_response_library_deep(id) on delete set null,
  response_notes text not null default '',
  outcome text not null default 'logged',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.prospecting_ai_script_suggestion_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  rep_user_id uuid default auth.uid(),
  source_type text not null default 'objection_log',
  source_record_id uuid,
  prompt_summary text not null default '',
  suggested_script text not null default '',
  suggested_response text not null default '',
  training_notice text not null default 'AI script suggestions require manager review before reps use them.',
  review_status text not null default 'needs_manager_review',
  reviewed_by uuid,
  reviewed_at timestamptz,
  manager_feedback text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.prospecting_talk_track_coaching_cards_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  rep_user_id uuid not null,
  coaching_reason text not null default '',
  related_metric text not null default '',
  recommended_script_id uuid references public.prospecting_script_templates_deep(id) on delete set null,
  recommended_response_id uuid references public.prospecting_objection_response_library_deep(id) on delete set null,
  status text not null default 'open',
  manager_notes text not null default '',
  acknowledged_at timestamptz,
  resolved_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.prospecting_script_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  event_type text not null default 'script_event',
  actor_user_id uuid not null default auth.uid(),
  related_record_type text not null default '',
  related_record_id uuid,
  event_summary text not null default '',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.prospecting_script_templates_deep enable row level security;
alter table public.prospecting_objection_categories_deep enable row level security;
alter table public.prospecting_objection_response_library_deep enable row level security;
alter table public.prospecting_rep_objection_logs_deep enable row level security;
alter table public.prospecting_ai_script_suggestion_runs_deep enable row level security;
alter table public.prospecting_talk_track_coaching_cards_deep enable row level security;
alter table public.prospecting_script_activity_events_deep enable row level security;

-- Live database includes supporting indexes, grants, and manager/rep RLS policies.
