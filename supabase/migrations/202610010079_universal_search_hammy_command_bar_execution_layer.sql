create table if not exists public.universal_search_query_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null default auth.uid(),
  search_text text not null,
  search_scope text not null default 'all' check (search_scope in ('all','jobs','contacts','documents','communications','production','finance','settings','commercial','help')),
  filters jsonb not null default '{}'::jsonb,
  result_count integer not null default 0,
  latency_ms integer not null default 0,
  permission_filtered boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.universal_search_result_hits_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  query_run_id uuid references public.universal_search_query_runs_deep(id) on delete cascade,
  result_type text not null,
  result_record_id uuid,
  result_title text not null,
  result_subtitle text not null default '',
  result_url text not null default '',
  relevance_score numeric(10,4) not null default 0,
  permission_context jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.hammy_command_bar_sessions_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null default auth.uid(),
  session_source text not null default 'command_bar' check (session_source in ('command_bar','voice','mobile_shortcut','dashboard','job_page')),
  raw_input text not null,
  interpreted_intent text not null default '',
  confidence numeric(5,4) not null default 0,
  requires_confirmation boolean not null default true,
  status text not null default 'drafted' check (status in ('drafted','awaiting_confirmation','confirmed','executed','cancelled','failed','manager_review')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.hammy_command_suggestions_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  session_id uuid references public.hammy_command_bar_sessions_deep(id) on delete cascade,
  suggested_action text not null,
  target_type text not null default '',
  target_record_id uuid,
  explanation text not null default '',
  risk_level text not null default 'low' check (risk_level in ('low','medium','high','critical')),
  manager_review_required boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.hammy_command_execution_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  session_id uuid references public.hammy_command_bar_sessions_deep(id) on delete cascade,
  suggestion_id uuid references public.hammy_command_suggestions_deep(id) on delete set null,
  executed_by uuid not null default auth.uid(),
  action_type text not null,
  target_type text not null default '',
  target_record_id uuid,
  execution_status text not null default 'queued' check (execution_status in ('queued','running','succeeded','failed','reverted','blocked')),
  before_snapshot jsonb not null default '{}'::jsonb,
  after_snapshot jsonb not null default '{}'::jsonb,
  error_message text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.hammy_saved_commands_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  owner_user_id uuid not null default auth.uid(),
  command_name text not null,
  command_text text not null,
  category text not null default 'general',
  is_company_shared boolean not null default false,
  manager_approved boolean not null default false,
  usage_count integer not null default 0,
  last_used_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.search_recent_items_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null default auth.uid(),
  item_type text not null,
  item_record_id uuid,
  item_title text not null,
  last_opened_at timestamptz not null default now(),
  open_count integer not null default 1,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.search_command_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  actor_user_id uuid not null default auth.uid(),
  event_type text not null,
  related_table text not null default '',
  related_record_id uuid,
  event_summary text not null default '',
  event_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists universal_search_query_runs_deep_company_user_idx on public.universal_search_query_runs_deep(company_id, user_id, created_at desc);
create index if not exists universal_search_result_hits_deep_company_query_idx on public.universal_search_result_hits_deep(company_id, query_run_id);
create index if not exists hammy_command_bar_sessions_deep_company_user_idx on public.hammy_command_bar_sessions_deep(company_id, user_id, created_at desc);
create index if not exists hammy_command_suggestions_deep_company_session_idx on public.hammy_command_suggestions_deep(company_id, session_id);
create index if not exists hammy_command_execution_runs_deep_company_session_idx on public.hammy_command_execution_runs_deep(company_id, session_id);
create index if not exists hammy_saved_commands_deep_company_owner_idx on public.hammy_saved_commands_deep(company_id, owner_user_id);
create index if not exists search_recent_items_deep_company_user_idx on public.search_recent_items_deep(company_id, user_id, last_opened_at desc);
create index if not exists search_command_activity_events_deep_company_created_idx on public.search_command_activity_events_deep(company_id, created_at desc);

alter table public.universal_search_query_runs_deep enable row level security;
alter table public.universal_search_result_hits_deep enable row level security;
alter table public.hammy_command_bar_sessions_deep enable row level security;
alter table public.hammy_command_suggestions_deep enable row level security;
alter table public.hammy_command_execution_runs_deep enable row level security;
alter table public.hammy_saved_commands_deep enable row level security;
alter table public.search_recent_items_deep enable row level security;
alter table public.search_command_activity_events_deep enable row level security;

revoke all on public.universal_search_query_runs_deep from anon, authenticated;
revoke all on public.universal_search_result_hits_deep from anon, authenticated;
revoke all on public.hammy_command_bar_sessions_deep from anon, authenticated;
revoke all on public.hammy_command_suggestions_deep from anon, authenticated;
revoke all on public.hammy_command_execution_runs_deep from anon, authenticated;
revoke all on public.hammy_saved_commands_deep from anon, authenticated;
revoke all on public.search_recent_items_deep from anon, authenticated;
revoke all on public.search_command_activity_events_deep from anon, authenticated;

grant select, insert, update on public.universal_search_query_runs_deep to authenticated;
grant select, insert, update on public.universal_search_result_hits_deep to authenticated;
grant select, insert, update on public.hammy_command_bar_sessions_deep to authenticated;
grant select, insert, update on public.hammy_command_suggestions_deep to authenticated;
grant select, insert, update on public.hammy_command_execution_runs_deep to authenticated;
grant select, insert, update on public.hammy_saved_commands_deep to authenticated;
grant select, insert, update on public.search_recent_items_deep to authenticated;
grant select, insert, update on public.search_command_activity_events_deep to authenticated;

create policy "search query runs company access" on public.universal_search_query_runs_deep for all to authenticated using (private.company_access(company_id)) with check (private.company_access(company_id));
create policy "search hits company access" on public.universal_search_result_hits_deep for all to authenticated using (private.company_access(company_id)) with check (private.company_access(company_id));
create policy "hammy sessions owner or manager" on public.hammy_command_bar_sessions_deep for all to authenticated using (user_id = auth.uid() or private.is_manager(company_id)) with check (user_id = auth.uid() or private.is_manager(company_id));
create policy "hammy suggestions company access" on public.hammy_command_suggestions_deep for all to authenticated using (private.company_access(company_id)) with check (private.company_access(company_id));
create policy "hammy execution company access" on public.hammy_command_execution_runs_deep for all to authenticated using (private.company_access(company_id)) with check (private.company_access(company_id));
create policy "saved commands owner shared or manager" on public.hammy_saved_commands_deep for all to authenticated using (owner_user_id = auth.uid() or is_company_shared = true or private.is_manager(company_id)) with check (owner_user_id = auth.uid() or private.is_manager(company_id));
create policy "recent search owner or manager" on public.search_recent_items_deep for all to authenticated using (user_id = auth.uid() or private.is_manager(company_id)) with check (user_id = auth.uid() or private.is_manager(company_id));
create policy "search command activity company access" on public.search_command_activity_events_deep for all to authenticated using (private.company_access(company_id)) with check (private.company_access(company_id));
