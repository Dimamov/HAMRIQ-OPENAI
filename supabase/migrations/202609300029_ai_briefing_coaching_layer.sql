-- HAMRIQ AI briefing/coaching layer
-- Adds daily manager/rep briefings, end-of-day wrap-ups, Hammy coaching insights,
-- role-play training sessions, business-health recommendations, command shortcuts,
-- and feedback capture for AI recommendations.

create table if not exists public.daily_manager_briefings (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  briefing_date date not null default current_date,
  title text not null default 'Daily Manager Briefing',
  summary text,
  key_risks jsonb not null default '[]'::jsonb,
  sales_focus jsonb not null default '[]'::jsonb,
  production_focus jsonb not null default '[]'::jsonb,
  finance_focus jsonb not null default '[]'::jsonb,
  recommended_actions jsonb not null default '[]'::jsonb,
  generated_by text not null default 'hammy',
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  unique(company_id, briefing_date)
);

create table if not exists public.daily_rep_briefings (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  rep_user_id uuid not null,
  briefing_date date not null default current_date,
  title text not null default 'Daily Rep Briefing',
  today_schedule jsonb not null default '[]'::jsonb,
  priority_leads jsonb not null default '[]'::jsonb,
  followups_due jsonb not null default '[]'::jsonb,
  coaching_tip text,
  generated_by text not null default 'hammy',
  acknowledged_at timestamptz,
  created_at timestamptz not null default now(),
  unique(company_id, rep_user_id, briefing_date)
);

create table if not exists public.end_of_day_wrapups (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  rep_user_id uuid not null default auth.uid(),
  wrapup_date date not null default current_date,
  doors_knocked integer not null default 0,
  conversations integer not null default 0,
  appointments_set integer not null default 0,
  inspections_completed integer not null default 0,
  contracts_signed integer not null default 0,
  notes text,
  blockers jsonb not null default '[]'::jsonb,
  hammy_summary text,
  submitted_at timestamptz,
  created_at timestamptz not null default now(),
  unique(company_id, rep_user_id, wrapup_date)
);

create table if not exists public.sales_coaching_insights (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  rep_user_id uuid,
  job_id uuid,
  insight_type text not null default 'general',
  severity text not null default 'info',
  evidence jsonb not null default '{}'::jsonb,
  insight text not null,
  recommended_action text,
  status text not null default 'open',
  manager_note text,
  created_by text not null default 'hammy',
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  constraint sales_coaching_job_fk foreign key (company_id, job_id) references public.jobs(company_id, id) on delete set null
);

create table if not exists public.roleplay_training_sessions (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  rep_user_id uuid not null default auth.uid(),
  scenario text not null,
  objection_type text,
  difficulty text not null default 'normal',
  transcript jsonb not null default '[]'::jsonb,
  ai_feedback text,
  score_snapshot jsonb not null default '{}'::jsonb,
  status text not null default 'started',
  started_at timestamptz not null default now(),
  completed_at timestamptz
);

create table if not exists public.ai_business_health_recommendations (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  category text not null default 'general',
  priority text not null default 'medium',
  finding text not null,
  evidence jsonb not null default '{}'::jsonb,
  recommendation text not null,
  estimated_impact text,
  manager_decision text not null default 'pending_review',
  decided_by uuid,
  decided_at timestamptz,
  created_by text not null default 'hammy',
  created_at timestamptz not null default now()
);

create table if not exists public.hammy_command_shortcuts (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null,
  phrase text not null,
  action_type text not null,
  action_payload jsonb not null default '{}'::jsonb,
  enabled boolean not null default true,
  manager_only boolean not null default false,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.ai_recommendation_feedback (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  source_table text not null,
  source_id uuid not null,
  feedback text not null,
  rating integer check (rating between 1 and 5),
  provided_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create index if not exists daily_manager_briefings_company_date_idx on public.daily_manager_briefings(company_id, briefing_date desc);
create index if not exists daily_rep_briefings_rep_date_idx on public.daily_rep_briefings(company_id, rep_user_id, briefing_date desc);
create index if not exists end_of_day_wrapups_rep_date_idx on public.end_of_day_wrapups(company_id, rep_user_id, wrapup_date desc);
create index if not exists sales_coaching_insights_rep_idx on public.sales_coaching_insights(company_id, rep_user_id, status);
create index if not exists roleplay_training_sessions_rep_idx on public.roleplay_training_sessions(company_id, rep_user_id, started_at desc);
create index if not exists ai_business_health_company_idx on public.ai_business_health_recommendations(company_id, manager_decision, priority);
create index if not exists hammy_command_shortcuts_company_idx on public.hammy_command_shortcuts(company_id, enabled);
create index if not exists ai_recommendation_feedback_source_idx on public.ai_recommendation_feedback(company_id, source_table, source_id);

alter table public.daily_manager_briefings enable row level security;
alter table public.daily_rep_briefings enable row level security;
alter table public.end_of_day_wrapups enable row level security;
alter table public.sales_coaching_insights enable row level security;
alter table public.roleplay_training_sessions enable row level security;
alter table public.ai_business_health_recommendations enable row level security;
alter table public.hammy_command_shortcuts enable row level security;
alter table public.ai_recommendation_feedback enable row level security;

grant select, insert, update on public.daily_manager_briefings to authenticated;
grant select, insert, update on public.daily_rep_briefings to authenticated;
grant select, insert, update on public.end_of_day_wrapups to authenticated;
grant select, insert, update on public.sales_coaching_insights to authenticated;
grant select, insert, update on public.roleplay_training_sessions to authenticated;
grant select, insert, update on public.ai_business_health_recommendations to authenticated;
grant select, insert, update on public.hammy_command_shortcuts to authenticated;
grant select, insert, update on public.ai_recommendation_feedback to authenticated;

create policy daily_manager_briefings_manager_all on public.daily_manager_briefings for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy daily_rep_briefings_read on public.daily_rep_briefings for select to authenticated using (private.is_manager(company_id) or rep_user_id = auth.uid());
create policy daily_rep_briefings_manager_write on public.daily_rep_briefings for insert to authenticated with check (private.is_manager(company_id));
create policy daily_rep_briefings_update on public.daily_rep_briefings for update to authenticated using (private.is_manager(company_id) or rep_user_id = auth.uid()) with check (private.is_manager(company_id) or rep_user_id = auth.uid());

create policy end_of_day_wrapups_read on public.end_of_day_wrapups for select to authenticated using (private.is_manager(company_id) or rep_user_id = auth.uid());
create policy end_of_day_wrapups_insert on public.end_of_day_wrapups for insert to authenticated with check (private.company_access(company_id) and rep_user_id = auth.uid());
create policy end_of_day_wrapups_update on public.end_of_day_wrapups for update to authenticated using (private.is_manager(company_id) or rep_user_id = auth.uid()) with check (private.is_manager(company_id) or rep_user_id = auth.uid());

create policy sales_coaching_insights_read on public.sales_coaching_insights for select to authenticated using (private.is_manager(company_id) or rep_user_id = auth.uid());
create policy sales_coaching_insights_manager_write on public.sales_coaching_insights for insert to authenticated with check (private.is_manager(company_id));
create policy sales_coaching_insights_update on public.sales_coaching_insights for update to authenticated using (private.is_manager(company_id) or rep_user_id = auth.uid()) with check (private.is_manager(company_id) or rep_user_id = auth.uid());

create policy roleplay_training_sessions_read on public.roleplay_training_sessions for select to authenticated using (private.is_manager(company_id) or rep_user_id = auth.uid());
create policy roleplay_training_sessions_insert on public.roleplay_training_sessions for insert to authenticated with check (private.company_access(company_id) and rep_user_id = auth.uid());
create policy roleplay_training_sessions_update on public.roleplay_training_sessions for update to authenticated using (private.is_manager(company_id) or rep_user_id = auth.uid()) with check (private.is_manager(company_id) or rep_user_id = auth.uid());

create policy ai_business_health_recommendations_manager_all on public.ai_business_health_recommendations for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy hammy_command_shortcuts_read on public.hammy_command_shortcuts for select to authenticated using (private.company_access(company_id) and (manager_only = false or private.is_manager(company_id)));
create policy hammy_command_shortcuts_manager_write on public.hammy_command_shortcuts for all to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy ai_recommendation_feedback_read on public.ai_recommendation_feedback for select to authenticated using (private.is_manager(company_id) or provided_by = auth.uid());
create policy ai_recommendation_feedback_insert on public.ai_recommendation_feedback for insert to authenticated with check (private.company_access(company_id) and provided_by = auth.uid());
create policy ai_recommendation_feedback_update on public.ai_recommendation_feedback for update to authenticated using (private.is_manager(company_id) or provided_by = auth.uid()) with check (private.is_manager(company_id) or provided_by = auth.uid());
