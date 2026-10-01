create unique index workspace_automation_once on public.workspace_records(company_id,(payload->>'automation_ref')) where payload ? 'automation_ref';
create function private.prepare_workspace_draft(p_company uuid,p_job uuid,p_actor uuid,p_kind text,p_payload jsonb) returns boolean
language plpgsql security definer set search_path='' as $$
declare r public.workspace_records;
begin
 insert into public.workspace_records(company_id,job_id,created_by,kind,payload,status) values(p_company,p_job,p_actor,p_kind,p_payload,'pending_approval') on conflict do nothing returning * into r;
 if r.id is null then return false; end if;
 insert into public.workspace_events(company_id,job_id,record_id,actor_id,action) values(p_company,p_job,r.id,p_actor,'system prepared draft; human approval required');return true;
end;$$;
revoke all on function private.prepare_workspace_draft(uuid,uuid,uuid,text,jsonb) from public,anon,authenticated;
create function private.workspace_daily_drafts(p_company uuid default null) returns integer
language plpgsql security definer set search_path='' as $$
declare r public.workspace_records; n integer:=0; ref text; day date:=(now() at time zone 'America/Detroit')::date;
begin
 for r in select w.* from public.workspace_records w join public.users u on u.id=w.created_by and u.active join public.jobs j on j.id=w.job_id where (p_company is null or w.company_id=p_company) and w.kind in ('claim','depreciation','warranty') and w.status not in ('completed','cancelled','rejected') and coalesce(w.payload->>'due','')<>'' and (w.payload->>'due')::date<=day and j.stage<>'Complete' loop
  if r.kind='claim' and r.payload->>'milestone'='Closed' then continue; end if;
  ref:='deadline:'||r.id::text||':'||(r.payload->>'due');
  if private.prepare_workspace_draft(r.company_id,r.job_id,r.created_by,'message',jsonb_build_object('channel','Email','direction','Draft outbound','body',case when r.kind='claim' then 'Please provide a status update for claim '||coalesce(r.payload->>'number','')||'. Last recorded milestone: '||coalesce(r.payload->>'milestone','')||'. '||coalesce(r.payload->>'next','') when r.kind='depreciation' then 'Please review the recoverable depreciation deadline and required documentation: '||coalesce(r.payload->>'requirements','') else 'Please review warranty registration requirements for '||coalesce(r.payload->>'manufacturer','') end,'due',day::text,'automation_ref',ref)) then n:=n+1; end if;
 end loop;
 return n;
end;$$;
revoke all on function private.workspace_daily_drafts(uuid) from public,anon,authenticated;
grant execute on function private.workspace_daily_drafts(uuid) to service_role;
create function private.run_workspace_drafts() returns integer language plpgsql security definer set search_path='' as $$
declare c uuid;
begin select company_id into c from public.users where id=auth.uid() and active;
 if auth.uid() is null or not private.is_manager(c) then raise exception 'Manager access required' using errcode='42501'; end if;
 return private.workspace_daily_drafts(c);
end;$$;
revoke all on function private.run_workspace_drafts() from public,anon;
grant execute on function private.run_workspace_drafts() to authenticated;
create function public.run_workspace_automations() returns integer language sql security invoker set search_path='' as $$select private.run_workspace_drafts()$$;
revoke all on function public.run_workspace_automations() from public,anon;
grant execute on function public.run_workspace_automations() to authenticated;
create function private.workspace_closeout_drafts() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if new.stage='Complete' and old.stage is distinct from new.stage then
  perform private.prepare_workspace_draft(new.company_id,new.id,new.assigned_to,'referral',jsonb_build_object('name','','source',new.title,'reward','','due',(now() at time zone 'America/Detroit')::date::text,'body','Thank you for trusting our team with your roofing project. Do you know a neighbor or friend who could use our help?','automation_ref','closeout-referral:'||new.id::text));
  perform private.prepare_workspace_draft(new.company_id,new.id,new.assigned_to,'review',jsonb_build_object('due',(now() at time zone 'America/Detroit')::date::text,'rating','','body','Thank you for choosing our team. How was your experience? We would appreciate your feedback.','automation_ref','closeout-review:'||new.id::text));
 end if;return new;
end;$$;
revoke all on function private.workspace_closeout_drafts() from public,anon,authenticated;
create trigger workspace_closeout_drafts after update of stage on public.jobs for each row execute function private.workspace_closeout_drafts();
create extension if not exists pg_cron;
select cron.schedule('hamriq-workspace-drafts','0 * * * *',$$select private.workspace_daily_drafts(null);$$);
