-- Simple lead progression + trigger/event framework.
-- Live migration applied in Supabase.

alter table public.jobs
  add column if not exists lead_progress_stage text not null default 'First contact',
  add column if not exists lead_progress_dead_reason text not null default '',
  add column if not exists lead_progress_updated_at timestamptz not null default now();

alter table public.jobs drop constraint if exists jobs_lead_progress_stage_check;
alter table public.jobs add constraint jobs_lead_progress_stage_check check (lead_progress_stage in ('First contact','Inspection complete','Contingency signed','Claim filed','Claim approved','Supplement submitted','Build contract signed','Completed','DEAD'));

alter table public.jobs drop constraint if exists jobs_dead_requires_reason_check;
alter table public.jobs add constraint jobs_dead_requires_reason_check check (lead_progress_stage <> 'DEAD' or length(trim(lead_progress_dead_reason)) > 0);

create table if not exists public.lead_progress_events (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid not null,
  previous_stage text,
  new_stage text not null,
  comment text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  unique (company_id, id),
  foreign key (company_id, job_id) references public.jobs(company_id, id),
  foreign key (company_id, created_by) references public.users(company_id, id),
  check (new_stage in ('First contact','Inspection complete','Contingency signed','Claim filed','Claim approved','Supplement submitted','Build contract signed','Completed','DEAD')),
  check (new_stage <> 'DEAD' or length(trim(comment)) > 0)
);

create table if not exists public.lead_stage_triggers (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  stage text not null,
  trigger_name text not null,
  action_type text not null default 'tbd',
  action_config jsonb not null default '{}'::jsonb,
  active boolean not null default false,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  unique (company_id, id),
  foreign key (company_id, created_by) references public.users(company_id, id)
);

create table if not exists public.lead_stage_trigger_runs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  job_id uuid not null,
  progression_event_id uuid,
  stage text not null,
  trigger_id uuid,
  action_type text not null default 'tbd',
  status text not null default 'pending_definition',
  result jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (company_id, id),
  foreign key (company_id, job_id) references public.jobs(company_id, id),
  foreign key (company_id, progression_event_id) references public.lead_progress_events(company_id, id),
  foreign key (company_id, trigger_id) references public.lead_stage_triggers(company_id, id)
);

alter table public.lead_progress_events enable row level security;
alter table public.lead_stage_triggers enable row level security;
alter table public.lead_stage_trigger_runs enable row level security;

create or replace function public.progress_lead_stage(p_job_id uuid, p_stage text, p_comment text default '') returns jsonb
language plpgsql security invoker set search_path = '' as $$
declare v_company uuid; v_previous text; v_event_id uuid; v_trigger_count integer;
begin
  select company_id, lead_progress_stage into v_company, v_previous from public.jobs where id = p_job_id limit 1;
  if v_company is null or not private.can_job(v_company, p_job_id) then raise exception 'Job access required.' using errcode = '42501'; end if;
  if p_stage = 'DEAD' and length(trim(coalesce(p_comment,''))) = 0 then raise exception 'DEAD requires a reason/comment.' using errcode = '23514'; end if;
  update public.jobs set lead_progress_stage = p_stage, lead_progress_dead_reason = case when p_stage = 'DEAD' then trim(coalesce(p_comment,'')) else '' end, lead_progress_updated_at = now() where company_id = v_company and id = p_job_id;
  insert into public.lead_progress_events(company_id, job_id, previous_stage, new_stage, comment, created_by) values (v_company, p_job_id, v_previous, p_stage, coalesce(p_comment,''), auth.uid()) returning id into v_event_id;
  insert into public.lead_stage_trigger_runs(company_id, job_id, progression_event_id, stage, trigger_id, action_type, status, result) select v_company, p_job_id, v_event_id, p_stage, t.id, t.action_type, 'queued', t.action_config from public.lead_stage_triggers t where t.company_id = v_company and t.stage = p_stage and t.active;
  get diagnostics v_trigger_count = row_count;
  if v_trigger_count = 0 then insert into public.lead_stage_trigger_runs(company_id, job_id, progression_event_id, stage, action_type, status, result) values (v_company, p_job_id, v_event_id, p_stage, 'tbd', 'pending_definition', jsonb_build_object('notice','Stage events to be determined')); end if;
  return jsonb_build_object('job_id', p_job_id, 'previous_stage', v_previous, 'new_stage', p_stage, 'event_id', v_event_id, 'trigger_runs', greatest(v_trigger_count, 1));
end;
$$;

grant execute on function public.progress_lead_stage(uuid,text,text) to authenticated;
