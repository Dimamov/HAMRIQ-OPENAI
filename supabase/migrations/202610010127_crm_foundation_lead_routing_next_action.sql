-- HAMRIQ CRM foundation: lead source, required next action, role-aware lead creation.

alter table public.contacts add column if not exists lead_source text not null default '';
alter table public.jobs add column if not exists priority text not null default 'Normal';
alter table public.jobs add column if not exists lead_status text not null default 'Active';
alter table public.jobs add column if not exists next_action text not null default '';
alter table public.jobs add column if not exists next_action_due date;

create index if not exists contacts_company_lead_source on public.contacts(company_id, lead_source);
create index if not exists jobs_company_priority_due on public.jobs(company_id, priority, next_action_due);
create index if not exists jobs_company_status_stage on public.jobs(company_id, lead_status, stage);

create or replace function public.create_workspace_lead(
  p_name text,
  p_address text,
  p_phone text default '',
  p_email text default '',
  p_source text default '',
  p_assigned uuid default null,
  p_priority text default 'Normal',
  p_next_action text default 'Contact homeowner',
  p_next_action_due date default current_date
)
returns public.jobs
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user public.users%rowtype;
  v_assigned uuid;
  v_contact public.contacts%rowtype;
  v_job public.jobs%rowtype;
begin
  select * into v_user
  from public.users
  where id = auth.uid()
    and active = true;

  if not found then
    raise exception 'No active HAMRIQ user record found for this login.';
  end if;

  if nullif(trim(p_name), '') is null then
    raise exception 'Homeowner name is required.';
  end if;

  if nullif(trim(p_address), '') is null then
    raise exception 'Address is required.';
  end if;

  if nullif(trim(p_next_action), '') is null then
    raise exception 'Every active lead must have a next action.';
  end if;

  v_assigned := coalesce(p_assigned, auth.uid());

  if v_assigned <> auth.uid() and v_user.role not in ('owner','manager') then
    raise exception 'Only managers can assign leads to another user.';
  end if;

  if not exists (
    select 1 from public.users u
    where u.company_id = v_user.company_id
      and u.id = v_assigned
      and u.active = true
  ) then
    raise exception 'Assigned user is not active in this company.';
  end if;

  insert into public.contacts (
    company_id, assigned_to, name, email, phone, address, lead_source, created_by
  ) values (
    v_user.company_id,
    v_assigned,
    trim(p_name),
    coalesce(p_email, ''),
    coalesce(p_phone, ''),
    trim(p_address),
    coalesce(nullif(trim(p_source), ''), 'Unknown'),
    auth.uid()
  ) returning * into v_contact;

  insert into public.jobs (
    company_id, contact_id, assigned_to, title, address, stage,
    priority, lead_status, next_action, next_action_due, created_by
  ) values (
    v_user.company_id,
    v_contact.id,
    v_assigned,
    trim(p_name),
    trim(p_address),
    'Lead',
    coalesce(nullif(trim(p_priority), ''), 'Normal'),
    'Active',
    trim(p_next_action),
    p_next_action_due,
    auth.uid()
  ) returning * into v_job;

  return v_job;
end;
$$;

create or replace function public.update_workspace_job_next_action(
  p_job uuid,
  p_next_action text,
  p_due date default null,
  p_priority text default null,
  p_lead_status text default null
)
returns public.jobs
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user public.users%rowtype;
  v_job public.jobs%rowtype;
begin
  select * into v_user
  from public.users
  where id = auth.uid()
    and active = true;

  if not found then
    raise exception 'No active HAMRIQ user record found for this login.';
  end if;

  select * into v_job
  from public.jobs
  where id = p_job
    and company_id = v_user.company_id;

  if not found then
    raise exception 'Job not found.';
  end if;

  if v_user.role not in ('owner','manager') and v_job.assigned_to <> auth.uid() then
    raise exception 'You can only update jobs assigned to you.';
  end if;

  if nullif(trim(p_next_action), '') is null and coalesce(p_lead_status, v_job.lead_status) <> 'Completed' then
    raise exception 'Every active job must have a next action.';
  end if;

  update public.jobs
  set next_action = coalesce(nullif(trim(p_next_action), ''), next_action),
      next_action_due = p_due,
      priority = coalesce(nullif(trim(p_priority), ''), priority),
      lead_status = coalesce(nullif(trim(p_lead_status), ''), lead_status),
      updated_at = now()
  where id = p_job
    and company_id = v_user.company_id
  returning * into v_job;

  return v_job;
end;
$$;

grant execute on function public.create_workspace_lead(text, text, text, text, text, uuid, text, text, date) to authenticated;
grant execute on function public.update_workspace_job_next_action(uuid, text, date, text, text) to authenticated;
