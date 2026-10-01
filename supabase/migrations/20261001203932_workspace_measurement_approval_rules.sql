create or replace function private.save_workspace(p_id uuid,p_job uuid,p_kind text,p_payload jsonb,p_version integer) returns public.workspace_records
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
 if p_kind='measurement' and p_payload->>'provider' in ('EagleView','Hover') then
  select * into item from public.workspace_records where company_id=c and kind='provider' and status<>'cancelled' and payload->>'provider'=p_payload->>'provider' and payload->>'state'='Configured externally' and payload->>'approve_all'='true' order by updated_at desc limit 1;
  if item.id is not null then
   update public.workspace_records set status='approved',approved_by=item.created_by,approved_at=now() where id=r.id returning * into r;
   insert into public.workspace_events(company_id,record_id,job_id,actor_id,action) values(c,r.id,r.job_id,item.created_by,'system approved measurement request under manager Approve All rule; provider fulfillment pending');
  end if;
 end if;
 insert into public.workspace_events(company_id,record_id,job_id,actor_id,action) values(c,r.id,r.job_id,auth.uid(),case when p_id is null then 'created' else 'updated; previous approval invalidated' end);
 return r;
end;
$$;
