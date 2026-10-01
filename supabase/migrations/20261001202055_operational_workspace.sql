create table public.workspace_workflow_types (
 key text primary key, definition jsonb not null
);
create table public.workspace_records (
 id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
 job_id uuid, kind text not null references public.workspace_workflow_types(key),
 payload jsonb not null check(jsonb_typeof(payload)='object'),
 status text not null default 'draft' check(status in ('draft','pending_approval','approved','rejected','completed','cancelled')),
 created_by uuid not null references public.users(id), created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(), version integer not null default 1,
 approved_by uuid references public.users(id), approved_at timestamptz,
 foreign key(company_id,job_id) references public.jobs(company_id,id),
 foreign key(company_id,created_by) references public.users(company_id,id)
);
create index workspace_records_company_job on public.workspace_records(company_id,job_id,updated_at desc);
create index workspace_records_queue on public.workspace_records(company_id,status,kind);
create table public.workspace_events (
 id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
 record_id uuid not null references public.workspace_records(id), job_id uuid,
 actor_id uuid not null references public.users(id), action text not null,
 occurred_at timestamptz not null default now(),
 foreign key(company_id,job_id) references public.jobs(company_id,id)
);
create index workspace_events_job on public.workspace_events(company_id,job_id,occurred_at desc);
alter table public.workspace_workflow_types enable row level security;
alter table public.workspace_records enable row level security;
alter table public.workspace_events enable row level security;
revoke all on public.workspace_workflow_types,public.workspace_records,public.workspace_events from anon,authenticated;
grant select on public.workspace_workflow_types,public.workspace_records,public.workspace_events to authenticated;
create policy workflow_types_read on public.workspace_workflow_types for select to authenticated using(true);
-- Definer helpers inspect only membership and authoritative workflow visibility.
create function private.can_workspace(p_company uuid,p_job uuid,p_kind text,p_actor uuid) returns boolean
language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and private.company_access(p_company)
 and (p_job is null or private.can_job(p_company,p_job))
 and exists(select 1 from public.workspace_workflow_types t where t.key=p_kind
 and (p_kind='price' or not coalesce((t.definition->>'manager')::boolean,false) or private.is_manager(p_company))
 and (not coalesce((t.definition->>'owner')::boolean,false) or private.is_owner(p_company))
 and (p_job is not null or private.is_manager(p_company) or p_actor=auth.uid() or p_kind='price'));
$$;
revoke all on function private.can_workspace(uuid,uuid,text,uuid) from public,anon;
grant execute on function private.can_workspace(uuid,uuid,text,uuid) to authenticated;
create policy workspace_read on public.workspace_records for select to authenticated using(private.can_workspace(company_id,job_id,kind,created_by));
create policy workspace_event_read on public.workspace_events for select to authenticated using(exists(select 1 from public.workspace_records r where r.id=record_id and private.can_workspace(r.company_id,r.job_id,r.kind,r.created_by)));
-- All mutations pass this boundary because prices, approval attribution, and history
-- must not be forgeable by directly inserting JSON through the Data API.
create function private.save_workspace(p_id uuid,p_job uuid,p_kind text,p_payload jsonb,p_version integer) returns public.workspace_records
language plpgsql security definer set search_path='' as $$
declare c uuid; d jsonb; f jsonb; v text; r public.workspace_records; oldr public.workspace_records;
 line text; parts text[]; qty numeric; price numeric; total numeric:=0; item public.workspace_records; lines jsonb:='[]';
begin
 if auth.uid() is null then raise exception 'Sign in required' using errcode='42501'; end if;
 select company_id into c from public.users where id=auth.uid() and active;
 select definition into d from public.workspace_workflow_types where key=p_kind;
 if c is null or d is null or not private.company_access(c) then raise exception 'Workspace access required' using errcode='42501'; end if;
 if coalesce((d->>'job')::boolean,true) and p_job is null then raise exception 'Select a job'; end if;
 if not private.can_workspace(c,p_job,p_kind,auth.uid()) then raise exception 'Not authorized for this workflow' using errcode='42501'; end if;
 if coalesce((d->>'manager')::boolean,false) and not private.is_manager(c) then raise exception 'Manager control required' using errcode='42501'; end if;
 if jsonb_typeof(p_payload)<>'object' or octet_length(p_payload::text)>100000 then raise exception 'Invalid record data'; end if;
 for f in select value from jsonb_array_elements(d->'fields') loop
  v:=p_payload->>(f->>'name');
  if coalesce((f->>'required')::boolean,false) and coalesce(trim(v),'')='' then raise exception '% is required',f->>'label'; end if;
  if f->>'type'='number' and coalesce(v,'')<>'' then
   if v !~ '^\d+(\.\d+)?$' or v::numeric>1000000000 then raise exception 'Invalid number for %',f->>'label'; end if;
  end if;
  if f->>'type'='select' and not coalesce((f->'options') ? v,false) then raise exception 'Invalid choice for %',f->>'label'; end if;
  if f->>'type'='checkbox' and jsonb_typeof(p_payload->(f->>'name')) is distinct from 'boolean' then raise exception 'Invalid checkbox'; end if;
  if f->>'type'='date' and coalesce(v,'')<>'' then perform v::date; end if;
 end loop;
 if p_kind='schedule' and (p_payload->>'end')::date<(p_payload->>'start')::date then raise exception 'End date precedes start'; end if;
 if p_kind='review' and coalesce(p_payload->>'rating','')<>'' and (p_payload->>'rating')::numeric not between 1 and 5 then raise exception 'Rating must be 1 to 5'; end if;
 if p_kind='estimate' then
  for line in select regexp_split_to_table(p_payload->>'lines',E'\n') loop
   if trim(line)='' then continue; end if;
   parts:=string_to_array(line,',');
   if cardinality(parts)<>2 or trim(parts[2]) !~ '^\d+(\.\d+)?$' then raise exception 'Use CODE, QUANTITY for each price line'; end if;
   qty:=trim(parts[2])::numeric;
   if qty<=0 or qty>100000 then raise exception 'Quantity must be positive'; end if;
   select * into item from public.workspace_records where company_id=c and kind='price' and status<>'cancelled' and lower(payload->>'code')=lower(trim(parts[1])) order by updated_at desc limit 1;
   if item.id is null then raise exception 'Unknown approved price code: %',trim(parts[1]); end if;
   price:=(item.payload->>'price')::numeric;
   total:=total+round(qty*price,2);
   lines:=lines||jsonb_build_array(jsonb_build_object('code',item.payload->>'code','name',item.payload->>'name','quantity',qty,'unit_price',price,'amount',round(qty*price,2),'price_version',item.version));
  end loop;
  if jsonb_array_length(lines)=0 then raise exception 'Add at least one price book line'; end if;
  if coalesce(nullif(p_payload->>'probability',''),'0')::numeric>100 then raise exception 'Probability exceeds 100'; end if;
  p_payload:=p_payload||jsonb_build_object('total',total,'calculated_lines',lines);
 end if;
 if p_kind='commission' and (p_payload->>'rate')::numeric>100 then raise exception 'Commission exceeds 100 percent'; end if;
 if p_id is not null then
  select * into oldr from public.workspace_records where id=p_id for update;
  if oldr.id is null or oldr.company_id<>c or oldr.kind<>p_kind or oldr.job_id is distinct from p_job or not private.can_workspace(c,p_job,p_kind,oldr.created_by) then raise exception 'Record unavailable' using errcode='42501'; end if;
  if oldr.version<>p_version then raise exception 'This record changed. Refresh before saving.' using errcode='40001'; end if;
  update public.workspace_records set payload=p_payload,status=case when coalesce((d->>'approval')::boolean,false) then 'pending_approval' else 'draft' end,approved_by=null,approved_at=null,updated_at=now(),version=version+1 where id=p_id returning * into r;
 else
  insert into public.workspace_records(company_id,job_id,kind,payload,status,created_by) values(c,p_job,p_kind,p_payload,case when coalesce((d->>'approval')::boolean,false) then 'pending_approval' else 'draft' end,auth.uid()) returning * into r;
 end if;
 insert into public.workspace_events(company_id,record_id,job_id,actor_id,action) values(c,r.id,r.job_id,auth.uid(),case when p_id is null then 'created' else 'updated; previous approval invalidated' end);
 return r;
end;
$$;
revoke all on function private.save_workspace(uuid,uuid,text,jsonb,integer) from public,anon;
grant execute on function private.save_workspace(uuid,uuid,text,jsonb,integer) to authenticated;
create function public.save_workspace_record(p_id uuid,p_job uuid,p_kind text,p_payload jsonb,p_version integer default null) returns public.workspace_records language sql security invoker set search_path='' as $$select private.save_workspace(p_id,p_job,p_kind,p_payload,p_version)$$;
revoke all on function public.save_workspace_record(uuid,uuid,text,jsonb,integer) from public,anon;
grant execute on function public.save_workspace_record(uuid,uuid,text,jsonb,integer) to authenticated;
create function private.transition_workspace(p_id uuid,p_status text,p_version integer) returns public.workspace_records
language plpgsql security definer set search_path='' as $$
declare r public.workspace_records; d jsonb;
begin
 if auth.uid() is null then raise exception 'Sign in required' using errcode='42501'; end if;
 select * into r from public.workspace_records where id=p_id for update;
 if r.id is null or not private.can_workspace(r.company_id,r.job_id,r.kind,r.created_by) then raise exception 'Record unavailable' using errcode='42501'; end if;
 if r.version<>p_version then raise exception 'Record changed. Refresh first.' using errcode='40001'; end if;
 select definition into d from public.workspace_workflow_types where key=r.kind;
 if p_status not in ('approved','rejected','completed','cancelled') then raise exception 'Invalid transition'; end if;
 if p_status in ('approved','rejected') and (not private.is_manager(r.company_id) or r.status<>'pending_approval') then raise exception 'Manager approval required' using errcode='42501'; end if;
 if p_status='completed' and coalesce((d->>'approval')::boolean,false) and r.status<>'approved' then raise exception 'Approve before completion'; end if;
 if r.status in ('completed','cancelled','rejected') then raise exception 'Record already closed'; end if;
 if p_status='completed' and r.kind in ('message','referral','review','material_order','measurement') then raise exception 'Record provider confirmation through the connected service; completion cannot be claimed manually.'; end if;
 update public.workspace_records set status=p_status,version=version+1,updated_at=now(),approved_by=case when p_status='approved' then auth.uid() else approved_by end,approved_at=case when p_status='approved' then now() else approved_at end where id=p_id returning * into r;
 insert into public.workspace_events(company_id,record_id,job_id,actor_id,action) values(r.company_id,r.id,r.job_id,auth.uid(),p_status);
 return r;
end;
$$;
revoke all on function private.transition_workspace(uuid,text,integer) from public,anon;
grant execute on function private.transition_workspace(uuid,text,integer) to authenticated;
create function public.transition_workspace_record(p_id uuid,p_status text,p_version integer) returns public.workspace_records language sql security invoker set search_path='' as $$select private.transition_workspace(p_id,p_status,p_version)$$;
revoke all on function public.transition_workspace_record(uuid,text,integer) from public,anon;
grant execute on function public.transition_workspace_record(uuid,text,integer) to authenticated;
create table public.workspace_portal_links (
 id uuid primary key default gen_random_uuid(),company_id uuid not null references public.companies(id),job_id uuid not null,
 token_hash bytea not null unique,expires_at timestamptz not null default now()+interval '30 days',revoked_at timestamptz,
 created_by uuid not null references public.users(id),created_at timestamptz not null default now(),
 foreign key(company_id,job_id) references public.jobs(company_id,id)
);
alter table public.workspace_portal_links enable row level security;
revoke all on public.workspace_portal_links from anon,authenticated;
grant select on public.workspace_portal_links to authenticated;
create policy portal_link_read on public.workspace_portal_links for select to authenticated using(private.is_manager(company_id));
create function private.create_portal(p_job uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare c uuid; token text:=gen_random_uuid()::text||gen_random_uuid()::text; link public.workspace_portal_links;
begin
 select company_id into c from public.jobs where id=p_job;
 if auth.uid() is null or not private.is_manager(c) then raise exception 'Manager access required' using errcode='42501'; end if;
 insert into public.workspace_portal_links(company_id,job_id,token_hash,created_by) values(c,p_job,sha256(convert_to(token,'UTF8')),auth.uid()) returning * into link;
 return jsonb_build_object('token',token,'expires_at',link.expires_at,'id',link.id);
end;$$;
revoke all on function private.create_portal(uuid) from public,anon;
grant execute on function private.create_portal(uuid) to authenticated;
create function public.create_workspace_portal(p_job uuid) returns jsonb language sql security invoker set search_path='' as $$select private.create_portal(p_job)$$;
revoke all on function public.create_workspace_portal(uuid) from public,anon;
grant execute on function public.create_workspace_portal(uuid) to authenticated;
-- Bearer links reveal only curated homeowner-facing status. No notes, claim numbers,
-- contact data, photos, financial costs, internal messages, or rep information.
create function private.read_portal(p_token text) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare l public.workspace_portal_links; j public.jobs; company text;
begin
 if length(p_token)<>72 then raise exception 'Link unavailable'; end if;
 select * into l from public.workspace_portal_links where token_hash=sha256(convert_to(p_token,'UTF8')) and revoked_at is null and expires_at>now();
 if l.id is null then raise exception 'Link expired or unavailable'; end if;
 select * into j from public.jobs where id=l.job_id and company_id=l.company_id;
 select name into company from public.companies where id=l.company_id;
 return jsonb_build_object('company',company,'stage',j.stage,'expires_at',l.expires_at,'updates',(select coalesce(jsonb_agg(jsonb_build_object('type',kind,'status',case when kind='claim' then payload->>'milestone' when kind='permit' then payload->>'status' else status end,'updated_at',updated_at) order by updated_at desc),'[]') from public.workspace_records where job_id=l.job_id and company_id=l.company_id and kind in ('claim','permit','warranty','schedule') and status not in ('cancelled','rejected')),'proposals',(select coalesce(jsonb_agg(jsonb_build_object('tier',payload->>'tier','scope',payload->>'scope','total',payload->'total')),'[]') from public.workspace_records where job_id=l.job_id and kind='estimate' and status='approved'));
end;$$;
revoke all on function private.read_portal(text) from public;
grant usage on schema private to anon;
grant execute on function private.read_portal(text) to anon,authenticated;
create function public.read_workspace_portal(p_token text) returns jsonb language sql security invoker set search_path='' as $$select private.read_portal(p_token)$$;
revoke all on function public.read_workspace_portal(text) from public;
grant execute on function public.read_workspace_portal(text) to anon,authenticated;
create function private.revoke_portal(p_id uuid) returns void language plpgsql security definer set search_path='' as $$
declare c uuid;
begin select company_id into c from public.workspace_portal_links where id=p_id;
 if auth.uid() is null or not private.is_manager(c) then raise exception 'Manager access required' using errcode='42501'; end if;
 update public.workspace_portal_links set revoked_at=now() where id=p_id;
end;$$;
revoke all on function private.revoke_portal(uuid) from public,anon;
grant execute on function private.revoke_portal(uuid) to authenticated;
create function public.revoke_workspace_portal(p_id uuid) returns void language sql security invoker set search_path='' as $$select private.revoke_portal(p_id)$$;
revoke all on function public.revoke_workspace_portal(uuid) from public,anon;
grant execute on function public.revoke_workspace_portal(uuid) to authenticated;
create function private.create_workspace_lead(p_name text,p_address text,p_phone text,p_email text,p_source text,p_assigned uuid) returns public.jobs language plpgsql security definer set search_path='' as $$
declare c uuid; ct uuid; j public.jobs; assignee uuid:=coalesce(p_assigned,auth.uid());
begin
 select company_id into c from public.users where id=auth.uid() and active;
 if auth.uid() is null or not private.company_access(c) then raise exception 'Workspace access required' using errcode='42501'; end if;
 if assignee<>auth.uid() and not private.is_manager(c) then raise exception 'Manager assignment required' using errcode='42501'; end if;
 if not exists(select 1 from public.users where id=assignee and company_id=c and active) then raise exception 'Invalid assignee'; end if;
 if trim(p_name)='' or trim(p_address)='' or trim(p_source)='' then raise exception 'Name, address and lead source required'; end if;
 insert into public.contacts(company_id,assigned_to,name,address,phone,email,lead_source,created_by) values(c,assignee,p_name,p_address,p_phone,p_email,p_source,auth.uid()) returning id into ct;
 insert into public.jobs(company_id,contact_id,assigned_to,title,address,created_by) values(c,ct,assignee,p_name||' roofing project',p_address,auth.uid()) returning * into j;
 return j;
end;$$;
revoke all on function private.create_workspace_lead(text,text,text,text,text,uuid) from public,anon;
grant execute on function private.create_workspace_lead(text,text,text,text,text,uuid) to authenticated;
create function public.create_workspace_lead(p_name text,p_address text,p_phone text,p_email text,p_source text,p_assigned uuid default null) returns public.jobs language sql security invoker set search_path='' as $$select private.create_workspace_lead(p_name,p_address,p_phone,p_email,p_source,p_assigned)$$;
revoke all on function public.create_workspace_lead(text,text,text,text,text,uuid) from public,anon;
grant execute on function public.create_workspace_lead(text,text,text,text,text,uuid) to authenticated;

insert into public.workspace_workflow_types(key,definition) values
('inspection','{"key":"inspection","title":"Guided inspection","group":"Inspections","fields":[{"name":"structure","label":"Structure","type":"select","options":["Main roof","Garage","Shed","Other"]},{"name":"elevation","label":"Elevation / slope","type":"select","options":["Front","Rear","Left","Right","Roof overview","Collateral"]},{"name":"overview","label":"Roof overview documented","type":"checkbox"},{"name":"slopes","label":"All slopes documented","type":"checkbox"},{"name":"soft_metals","label":"Soft metals documented","type":"checkbox"},{"name":"gutters","label":"Gutters documented","type":"checkbox"},{"name":"collateral","label":"Collateral / splatter documented","type":"checkbox"},{"name":"measurements","label":"Measurements verified","type":"checkbox"},{"name":"damage","label":"Observed damage and locations","type":"textarea","required":false},{"name":"scope","label":"Human-reviewed scope","type":"textarea","required":false}],"job":true}'::jsonb),
('scope','{"key":"scope","title":"Inspection scope draft","group":"Inspections","fields":[{"name":"scope","label":"Scope of work","type":"textarea","required":true},{"name":"evidence","label":"Supporting photo references","type":"textarea","required":false},{"name":"exclusions","label":"Exclusions / items needing review","type":"textarea","required":false}],"job":true,"approval":true}'::jsonb),
('measurement','{"key":"measurement","title":"Measurement fallback request","group":"Inspections","fields":[{"name":"provider","label":"Provider","type":"select","options":["Native HAMRIQ","EagleView","Hover"]},{"name":"reason","label":"Reason / native measurement limitations","type":"textarea","required":true}],"job":true,"approval":true,"provider":true}'::jsonb),
('storm','{"key":"storm","title":"Storm Mode","group":"Prospecting","fields":[{"name":"name","label":"Campaign name","type":"text","required":true},{"name":"area","label":"Storm area","type":"text","required":true},{"name":"loss_date","label":"Storm date","type":"date","required":true},{"name":"severity","label":"Priority","type":"select","options":["Normal","High","Emergency"]},{"name":"instructions","label":"Team instructions","type":"textarea","required":false}],"job":false,"manager":true}'::jsonb),
('route','{"key":"route","title":"Rep route","group":"Prospecting","fields":[{"name":"name","label":"Route name","type":"text","required":true},{"name":"stops","label":"Stops, one address per line","type":"textarea","required":true},{"name":"day","label":"Route date","type":"date","required":false}],"job":false}'::jsonb),
('door','{"key":"door","title":"Door-hanger visit","group":"Prospecting","fields":[{"name":"address","label":"Address","type":"text","required":true},{"name":"outcome","label":"Outcome","type":"select","options":["Door Hanger Placed","No answer","Warm lead","Hot lead","Not interested"]},{"name":"notes","label":"Notes","type":"textarea","required":false}],"job":false}'::jsonb),
('yard','{"key":"yard","title":"Yard-sign placement","group":"Prospecting","fields":[{"name":"placed","label":"Placement date","type":"date","required":true},{"name":"location","label":"Placement location","type":"text","required":true},{"name":"referrals","label":"Neighborhood referrals","type":"number","required":false}],"job":true}'::jsonb),
('neighbor','{"key":"neighbor","title":"Neighbor opportunity","group":"Prospecting","fields":[{"name":"address","label":"Neighbor address","type":"text","required":true},{"name":"source","label":"Opportunity source","type":"text","required":true},{"name":"interest","label":"Interest","type":"select","options":["Uncontacted","Warm","Hot","Not interested"]},{"name":"notes","label":"Permission / follow-up notes","type":"textarea","required":false}],"job":true}'::jsonb),
('competitor','{"key":"competitor","title":"Competitor intelligence","group":"Sales","fields":[{"name":"name","label":"Competitor","type":"text","required":true},{"name":"quoted","label":"Reported quote ($)","type":"number","required":false},{"name":"notes","label":"Homeowner-reported details","type":"textarea","required":true}],"job":true}'::jsonb),
('risk','{"key":"risk","title":"Deal at Risk / Save Desk","group":"Sales","fields":[{"name":"urgency","label":"Urgency","type":"select","options":["Normal","High","Urgent"]},{"name":"reason","label":"Why the deal is at risk","type":"textarea","required":true},{"name":"help","label":"Help needed from management","type":"textarea","required":true}],"job":true}'::jsonb),
('estimate','{"key":"estimate","title":"Good / Better / Best estimate","group":"Sales","fields":[{"name":"tier","label":"Package","type":"select","options":["Good","Better","Best"]},{"name":"scope","label":"Included scope","type":"textarea","required":true},{"name":"lines","label":"Price book lines: CODE, QUANTITY (one per line)","type":"textarea","required":true},{"name":"probability","label":"Forecast probability (%)","type":"number","required":false}],"job":true,"approval":true}'::jsonb),
('presentation','{"key":"presentation","title":"Kitchen-table presentation","group":"Sales","fields":[{"name":"tier","label":"Homeowner selection","type":"select","options":["Undecided","Good","Better","Best"]},{"name":"questions","label":"Questions / objections","type":"textarea","required":false},{"name":"next","label":"Agreed next action","type":"textarea","required":true}],"job":true}'::jsonb),
('claim','{"key":"claim","title":"Claim timeline / Auto-Chaser","group":"Claims","fields":[{"name":"carrier","label":"Carrier","type":"text","required":true},{"name":"number","label":"Claim number","type":"text","required":true},{"name":"milestone","label":"Milestone","type":"select","options":["Filed","Inspection scheduled","Estimate received","Supplement submitted","Approved","Denied","Payment issued","Closed"]},{"name":"due","label":"Next response due","type":"date","required":true},{"name":"next","label":"Next follow-up","type":"textarea","required":true}],"job":true}'::jsonb),
('adjuster','{"key":"adjuster","title":"Adjuster meeting preparation","group":"Claims","fields":[{"name":"meeting","label":"Meeting date","type":"date","required":true},{"name":"adjuster","label":"Adjuster name","type":"text","required":false},{"name":"questions","label":"Questions / disputed items","type":"textarea","required":false},{"name":"evidence","label":"Evidence to bring","type":"textarea","required":false}],"job":true}'::jsonb),
('gap','{"key":"gap","title":"Carrier estimate gap finder","group":"Claims","fields":[{"name":"expected","label":"Expected lines: DESCRIPTION | AMOUNT (one per line)","type":"textarea","required":true},{"name":"carrier_lines","label":"Carrier lines: DESCRIPTION | AMOUNT (one per line)","type":"textarea","required":true}],"job":true}'::jsonb),
('supplement','{"key":"supplement","title":"Supplement evidence builder","group":"Claims","fields":[{"name":"scope","label":"Requested additional scope","type":"textarea","required":true},{"name":"amount","label":"Requested amount ($)","type":"number","required":true},{"name":"evidence","label":"Evidence / photo references","type":"textarea","required":true},{"name":"justification","label":"Reason and supporting documentation","type":"textarea","required":true}],"job":true,"approval":true}'::jsonb),
('packet','{"key":"packet","title":"Claim document packet","group":"Claims","fields":[{"name":"documents","label":"Included documents / uploaded file names","type":"textarea","required":true},{"name":"summary","label":"Claim summary","type":"textarea","required":true}],"job":true,"approval":true}'::jsonb),
('depreciation','{"key":"depreciation","title":"Depreciation recovery","group":"Claims","fields":[{"name":"amount","label":"Recoverable depreciation ($)","type":"number","required":true},{"name":"due","label":"Recovery deadline","type":"date","required":true},{"name":"requirements","label":"Carrier requirements","type":"textarea","required":true}],"job":true}'::jsonb),
('message','{"key":"message","title":"Homeowner message timeline","group":"Customers","fields":[{"name":"channel","label":"Channel","type":"select","options":["Text","Email","Call note"]},{"name":"direction","label":"Direction","type":"select","options":["Draft outbound","Received","Previously sent"]},{"name":"body","label":"Message / call summary","type":"textarea","required":true},{"name":"due","label":"Follow-up date","type":"date","required":false}],"job":true,"approval":true}'::jsonb),
('referral','{"key":"referral","title":"Referral ask / rewards","group":"Customers","fields":[{"name":"name","label":"Referral name","type":"text","required":false},{"name":"source","label":"Referring customer","type":"text","required":false},{"name":"reward","label":"Reward amount ($)","type":"number","required":false},{"name":"due","label":"Ask / follow-up date","type":"date","required":true},{"name":"body","label":"Draft referral request","type":"textarea","required":true}],"job":true,"approval":true}'::jsonb),
('review','{"key":"review","title":"Review request","group":"Customers","fields":[{"name":"due","label":"Request date","type":"date","required":true},{"name":"rating","label":"Internal rating (1–5)","type":"number","required":false},{"name":"body","label":"Draft review request","type":"textarea","required":true}],"job":true,"approval":true}'::jsonb),
('material_order','{"key":"material_order","title":"Supplier material order","group":"Production","fields":[{"name":"supplier","label":"Supplier","type":"text","required":true},{"name":"product","label":"Product / SKU","type":"text","required":true},{"name":"color","label":"Color","type":"text","required":true},{"name":"quantity","label":"Quantity","type":"number","required":true},{"name":"delivery","label":"Requested delivery date","type":"date","required":true}],"job":true,"approval":true,"provider":true}'::jsonb),
('delivery','{"key":"delivery","title":"Material delivery confirmation","group":"Production","fields":[{"name":"product","label":"Received product / SKU","type":"text","required":true},{"name":"color","label":"Received color","type":"text","required":true},{"name":"quantity","label":"Received quantity","type":"number","required":true},{"name":"received","label":"Delivery date","type":"date","required":true},{"name":"proof","label":"Photo / delivery-ticket reference","type":"textarea","required":true}],"job":true}'::jsonb),
('permit','{"key":"permit","title":"Permit status","group":"Production","fields":[{"name":"authority","label":"Municipality","type":"text","required":true},{"name":"number","label":"Permit number","type":"text","required":false},{"name":"status","label":"Permit status","type":"select","options":["Not requested","Submitted","Approved","Inspection scheduled","Passed","Failed"]},{"name":"due","label":"Next deadline","type":"date","required":false},{"name":"notes","label":"Requirements / portal reference","type":"textarea","required":false}],"job":true}'::jsonb),
('schedule','{"key":"schedule","title":"Production schedule","group":"Production","fields":[{"name":"crew","label":"Crew","type":"text","required":true},{"name":"start","label":"Start date","type":"date","required":true},{"name":"end","label":"End date","type":"date","required":true},{"name":"notes","label":"Access / scheduling notes","type":"textarea","required":false}],"job":true}'::jsonb),
('weather','{"key":"weather","title":"Weather Risk Hold","group":"Production","fields":[{"name":"day","label":"Affected date","type":"date","required":true},{"name":"risk","label":"Risk","type":"select","options":["Rain","Wind","Hail","Ice / snow","Heat"]},{"name":"reason","label":"Reason and source","type":"textarea","required":true},{"name":"hold","label":"Hold production","type":"checkbox"}],"job":true}'::jsonb),
('readiness','{"key":"readiness","title":"Job readiness checklist","group":"Production","fields":[{"name":"contract","label":"Signed contract verified","type":"checkbox"},{"name":"materials","label":"Correct materials confirmed","type":"checkbox"},{"name":"permit","label":"Permit approved / not required","type":"checkbox"},{"name":"crew","label":"Crew confirmed","type":"checkbox"},{"name":"access","label":"Access and staging confirmed","type":"checkbox"},{"name":"weather","label":"Weather reviewed","type":"checkbox"},{"name":"notes","label":"Blockers / exceptions","type":"textarea","required":false}],"job":true}'::jsonb),
('warranty','{"key":"warranty","title":"Warranty registration","group":"Production","fields":[{"name":"manufacturer","label":"Manufacturer","type":"text","required":true},{"name":"number","label":"Registration / warranty reference","type":"text","required":false},{"name":"due","label":"Registration deadline","type":"date","required":true},{"name":"status","label":"Status","type":"select","options":["Pending","Submitted","Registered"]},{"name":"notes","label":"Product / coverage details","type":"textarea","required":false}],"job":true}'::jsonb),
('cost','{"key":"cost","title":"Job costing","group":"Financials","fields":[{"name":"materials","label":"Material cost ($)","type":"number","required":true},{"name":"labor","label":"Labor cost ($)","type":"number","required":true},{"name":"other","label":"Other cost ($)","type":"number","required":false},{"name":"revenue","label":"Contract revenue ($)","type":"number","required":true}],"job":true,"manager":true}'::jsonb),
('invoice','{"key":"invoice","title":"Invoices / A/R aging","group":"Financials","fields":[{"name":"number","label":"Invoice number","type":"text","required":true},{"name":"amount","label":"Amount ($)","type":"number","required":true},{"name":"paid","label":"Amount already paid ($)","type":"number","required":false},{"name":"due","label":"Due date","type":"date","required":true}],"job":true,"manager":true,"approval":true}'::jsonb),
('commission','{"key":"commission","title":"Commission tracking","group":"Financials","fields":[{"name":"rep","label":"Rep","type":"text","required":true},{"name":"basis","label":"Commission basis ($)","type":"number","required":true},{"name":"rate","label":"Commission rate (%)","type":"number","required":true},{"name":"status","label":"Status","type":"select","options":["Pending","Earned","Paid"]}],"job":true,"manager":true}'::jsonb),
('campaign','{"key":"campaign","title":"Marketing ROI","group":"Marketing","fields":[{"name":"name","label":"Campaign / lead source","type":"text","required":true},{"name":"spend","label":"Spend ($)","type":"number","required":true},{"name":"start","label":"Start date","type":"date","required":false},{"name":"notes","label":"Campaign details","type":"textarea","required":false}],"job":false,"manager":true}'::jsonb),
('price','{"key":"price","title":"Company Price Book","group":"Settings","fields":[{"name":"code","label":"Item code","type":"text","required":true},{"name":"name","label":"Item name","type":"text","required":true},{"name":"category","label":"Category","type":"select","options":["Materials","Labor","Production","Sales option"]},{"name":"unit","label":"Unit","type":"text","required":true},{"name":"price","label":"Unit price ($)","type":"number","required":true},{"name":"cost","label":"Unit cost ($)","type":"number","required":false}],"job":false,"manager":true}'::jsonb),
('branding','{"key":"branding","title":"Company branding","group":"Settings","fields":[{"name":"name","label":"Company display name","type":"text","required":true},{"name":"phone","label":"Business phone","type":"text","required":false},{"name":"logo","label":"Logo URL (https)","type":"text","required":false},{"name":"accent","label":"Brand color (#hex)","type":"text","required":false},{"name":"review_url","label":"Public review URL (https)","type":"text","required":false}],"job":false,"manager":true,"owner":true}'::jsonb),
('provider','{"key":"provider","title":"Integration settings","group":"Integrations","fields":[{"name":"provider","label":"Provider","type":"select","options":["EagleView","Hover","HailTrace","Hail Recon","QuickBooks","Financing","Payments","SMS / Email","AI"]},{"name":"url","label":"Provider portal / secure service URL (https)","type":"text","required":false},{"name":"account","label":"Account reference (no secrets)","type":"text","required":false},{"name":"state","label":"Setup state","type":"select","options":["Not connected","Setup requested","Configured externally"]},{"name":"approve_all","label":"Approve all measurement requests","type":"checkbox"},{"name":"notes","label":"Connection requirements","type":"textarea","required":false}],"job":false,"manager":true}'::jsonb),
('task','{"key":"task","title":"Next action","group":"Today","fields":[{"name":"title","label":"Action","type":"text","required":true},{"name":"due","label":"Due date","type":"date","required":true},{"name":"priority","label":"Priority","type":"select","options":["Normal","High","Urgent"]},{"name":"notes","label":"Details","type":"textarea","required":false}],"job":true}'::jsonb),
('note','{"key":"note","title":"Property Memory note","group":"Customers","fields":[{"name":"body","label":"Property history / note","type":"textarea","required":true}],"job":true}'::jsonb);
