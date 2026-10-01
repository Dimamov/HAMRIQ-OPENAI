create table public.workspace_ai_requests (
 id uuid primary key default gen_random_uuid(),user_id uuid not null references public.users(id),
 company_id uuid not null references public.companies(id),job_id uuid not null,
 requested_at timestamptz not null default now(),
 foreign key(company_id,job_id) references public.jobs(company_id,id)
);
create index workspace_ai_user_time on public.workspace_ai_requests(user_id,requested_at);
alter table public.workspace_ai_requests enable row level security;
revoke all on public.workspace_ai_requests from anon,authenticated;
grant select on public.workspace_ai_requests to authenticated;
create policy ai_request_read on public.workspace_ai_requests for select to authenticated using(user_id=auth.uid() and private.company_access(company_id));
create function private.reserve_workspace_ai(p_job uuid) returns boolean language plpgsql security definer set search_path='' as $$
declare c uuid;
begin
 if auth.uid() is null then raise exception 'Sign in required' using errcode='42501'; end if;
 select company_id into c from public.jobs where id=p_job;
 if c is null or not private.can_job(c,p_job) then raise exception 'Job unavailable' using errcode='42501'; end if;
 perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text,0));
 if (select count(*) from public.workspace_ai_requests where user_id=auth.uid() and requested_at>now()-interval '1 hour')>=10 then raise exception 'AI hourly request limit reached'; end if;
 insert into public.workspace_ai_requests(user_id,company_id,job_id) values(auth.uid(),c,p_job);
 return true;
end;$$;
revoke all on function private.reserve_workspace_ai(uuid) from public,anon;
grant execute on function private.reserve_workspace_ai(uuid) to authenticated;
create function public.reserve_workspace_ai(p_job uuid) returns boolean language sql security invoker set search_path='' as $$select private.reserve_workspace_ai(p_job)$$;
revoke all on function public.reserve_workspace_ai(uuid) from public,anon;
grant execute on function public.reserve_workspace_ai(uuid) to authenticated;
-- Existing inspection entry points are authenticated app operations, never guest RPCs.
revoke execute on function public.start_additional_inspection_structure(uuid,uuid,text) from public,anon;
revoke execute on function public.complete_inspection_structure(uuid,uuid,uuid,boolean,text) from public,anon;
