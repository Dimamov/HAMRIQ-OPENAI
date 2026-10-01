-- HAMRIQ inspection additional structures workflow
-- Supports primary inspection followed by unlimited additional structures.
-- UI flow: after each structure inspection, show buttons: Additional Structure / Complete.
-- Additional Structure opens a type dropdown: Garage, Barn, Shed, Other.

alter table public.inspection_completeness_checks
  add column if not exists structure_id uuid,
  add column if not exists structure_label text not null default 'Primary structure',
  add column if not exists structure_type text not null default 'primary';

create table if not exists public.inspection_structures (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  parent_structure_id uuid references public.inspection_structures(id) on delete set null,
  structure_order integer not null default 1,
  structure_type text not null default 'primary',
  label text not null default 'Primary structure',
  status text not null default 'in_progress',
  started_by uuid default auth.uid(),
  completed_by uuid,
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  notes text,
  constraint inspection_structures_job_fk foreign key (company_id, job_id) references public.jobs(company_id, id) on delete cascade,
  constraint inspection_structures_type_chk check (structure_type in ('primary','garage','barn','shed','other')),
  constraint inspection_structures_status_chk check (status in ('in_progress','complete','skipped'))
);

create table if not exists public.inspection_structure_events (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  structure_id uuid not null references public.inspection_structures(id) on delete cascade,
  event_type text not null,
  event_note text,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  constraint inspection_structure_events_job_fk foreign key (company_id, job_id) references public.jobs(company_id, id) on delete cascade
);

create index if not exists inspection_structures_job_idx on public.inspection_structures(company_id, job_id, structure_order);
create index if not exists inspection_structures_status_idx on public.inspection_structures(company_id, status);
create index if not exists inspection_structure_events_job_idx on public.inspection_structure_events(company_id, job_id, created_at desc);

alter table public.inspection_structures enable row level security;
alter table public.inspection_structure_events enable row level security;

grant select, insert, update on public.inspection_structures to authenticated;
grant select, insert, update on public.inspection_structure_events to authenticated;

do $$ begin
  create policy inspection_structures_read on public.inspection_structures for select to authenticated
    using (private.can_job(company_id, job_id));
exception when duplicate_object then null; end $$;

do $$ begin
  create policy inspection_structures_insert on public.inspection_structures for insert to authenticated
    with check (private.can_job(company_id, job_id));
exception when duplicate_object then null; end $$;

do $$ begin
  create policy inspection_structures_update on public.inspection_structures for update to authenticated
    using (private.can_job(company_id, job_id))
    with check (private.can_job(company_id, job_id));
exception when duplicate_object then null; end $$;

do $$ begin
  create policy inspection_structure_events_read on public.inspection_structure_events for select to authenticated
    using (private.can_job(company_id, job_id));
exception when duplicate_object then null; end $$;

do $$ begin
  create policy inspection_structure_events_insert on public.inspection_structure_events for insert to authenticated
    with check (private.can_job(company_id, job_id));
exception when duplicate_object then null; end $$;

create or replace function public.start_additional_inspection_structure(
  p_company_id uuid,
  p_job_id uuid,
  p_structure_type text
)
returns uuid
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_structure_id uuid;
  v_order integer;
  v_label text;
begin
  if not private.can_job(p_company_id, p_job_id) then
    raise exception 'Not allowed';
  end if;

  if lower(p_structure_type) not in ('garage','barn','shed','other') then
    raise exception 'Additional structure type must be garage, barn, shed, or other';
  end if;

  select coalesce(max(structure_order), 0) + 1
    into v_order
    from public.inspection_structures
   where company_id = p_company_id and job_id = p_job_id;

  v_label := initcap(lower(p_structure_type)) || ' ' || v_order::text;

  insert into public.inspection_structures(company_id, job_id, structure_order, structure_type, label, started_by)
  values (p_company_id, p_job_id, v_order, lower(p_structure_type), v_label, auth.uid())
  returning id into v_structure_id;

  insert into public.inspection_structure_events(company_id, job_id, structure_id, event_type, event_note, created_by)
  values (p_company_id, p_job_id, v_structure_id, 'additional_structure_started', v_label, auth.uid());

  return v_structure_id;
end;
$$;

create or replace function public.complete_inspection_structure(
  p_company_id uuid,
  p_job_id uuid,
  p_structure_id uuid,
  p_add_another boolean default false,
  p_next_structure_type text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_next_id uuid;
begin
  if not private.can_job(p_company_id, p_job_id) then
    raise exception 'Not allowed';
  end if;

  update public.inspection_structures
     set status = 'complete', completed_by = auth.uid(), completed_at = now()
   where id = p_structure_id and company_id = p_company_id and job_id = p_job_id;

  if not found then
    raise exception 'Inspection structure not found';
  end if;

  insert into public.inspection_structure_events(company_id, job_id, structure_id, event_type, event_note, created_by)
  values (p_company_id, p_job_id, p_structure_id, 'structure_completed', case when p_add_another then 'Additional structure requested' else 'Inspection complete' end, auth.uid());

  if p_add_another then
    if p_next_structure_type is null then
      raise exception 'Next structure type is required when adding another structure';
    end if;
    v_next_id := public.start_additional_inspection_structure(p_company_id, p_job_id, p_next_structure_type);
    return v_next_id;
  end if;

  return null;
end;
$$;

grant execute on function public.start_additional_inspection_structure(uuid, uuid, text) to authenticated;
grant execute on function public.complete_inspection_structure(uuid, uuid, uuid, boolean, text) to authenticated;
