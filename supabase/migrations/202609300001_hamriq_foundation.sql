-- HAMRIQ: company isolation, private-by-default access, immutable AI measurements.
create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated, service_role;

create type public.app_role as enum ('owner', 'manager', 'rep');
create type public.job_stage as enum ('Lead', 'Measured', 'Estimated', 'Contract sent', 'Signed', 'Complete');
create type public.touch_kind as enum ('call', 'text', 'email', 'visit');

create table public.companies (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) > 0),
  owner_email text not null,
  owner_user_id uuid unique references auth.users(id),
  access_mode text not null default 'owner_only' check (access_mode in ('owner_only', 'team')),
  timezone text not null default 'America/Detroit' check (timezone = 'America/Detroit'),
  phone text not null default '', address text not null default '',
  license_number text not null default '',
  contract_terms text not null default '',
  google_review_url text not null default '', facebook_review_url text not null default '',
  created_at timestamptz not null default now()
);
create unique index company_owner_email on public.companies(lower(owner_email));

create table public.users (
  id uuid primary key references auth.users(id),
  company_id uuid not null references public.companies(id),
  display_name text not null,
  role public.app_role not null default 'rep',
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (company_id, id)
);
create index users_company on public.users(company_id);

create table public.contacts (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  assigned_to uuid not null default auth.uid(),
  name text not null check (length(trim(name)) > 0),
  email text not null default '', phone text not null default '',
  address text not null default '', city text not null default '',
  state text not null default 'MI', zip text not null default '',
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique (company_id, id),
  foreign key (company_id, assigned_to) references public.users(company_id, id),
  foreign key (company_id, created_by) references public.users(company_id, id)
);
create index contacts_assigned on public.contacts(company_id, assigned_to);

create table public.jobs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  contact_id uuid not null,
  assigned_to uuid not null default auth.uid(),
  title text not null check (length(trim(title)) > 0),
  address text not null, municipality text not null default '',
  stage public.job_stage not null default 'Lead',
  material text not null default 'Asphalt shingles',
  installed_on date, expected_life_years integer check (expected_life_years between 1 and 100),
  notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique (company_id, id),
  foreign key (company_id, contact_id) references public.contacts(company_id, id),
  foreign key (company_id, assigned_to) references public.users(company_id, id),
  foreign key (company_id, created_by) references public.users(company_id, id)
);
create index jobs_assigned_stage on public.jobs(company_id, assigned_to, stage);
create index jobs_contact on public.jobs(company_id, contact_id);

create table public.touch_points (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  contact_id uuid not null, job_id uuid,
  kind public.touch_kind not null, summary text not null check (length(trim(summary)) > 0),
  user_id uuid not null default auth.uid(),
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  foreign key (company_id, contact_id) references public.contacts(company_id, id),
  foreign key (company_id, job_id) references public.jobs(company_id, id),
  foreign key (company_id, user_id) references public.users(company_id, id)
);
create index touch_contact_time on public.touch_points(company_id, contact_id, occurred_at desc);
create index touch_job on public.touch_points(company_id, job_id);
create index touch_user on public.touch_points(company_id, user_id);

create table public.follow_ups (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  job_id uuid not null, assigned_to uuid not null default auth.uid(),
  due_on date not null, note text not null default '', completed_at timestamptz,
  created_by uuid not null default auth.uid(), created_at timestamptz not null default now(),
  foreign key (company_id, job_id) references public.jobs(company_id, id),
  foreign key (company_id, assigned_to) references public.users(company_id, id),
  foreign key (company_id, created_by) references public.users(company_id, id)
);
create index follow_ups_due on public.follow_ups(company_id, assigned_to, due_on) where completed_at is null;
create index follow_ups_job on public.follow_ups(company_id, job_id);
create index follow_ups_creator on public.follow_ups(company_id, created_by);

create table public.photos (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  job_id uuid not null, storage_path text not null unique,
  category text not null default 'property' check (category in ('property','front','rear','left','right','reference','slope','hail','other')),
  slope text not null default '', caption text not null default '',
  uploaded_by uuid not null default auth.uid(), uploaded_at timestamptz not null default now(),
  unique (company_id, id),
  foreign key (company_id, job_id) references public.jobs(company_id, id),
  foreign key (company_id, uploaded_by) references public.users(company_id, id),
  check (storage_path like company_id::text || '/' || job_id::text || '/%')
);
create index photos_job on public.photos(company_id, job_id, uploaded_at desc);
create index photos_uploader on public.photos(company_id, uploaded_by);

create table public.measurements (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  job_id uuid not null,
  status text not null default 'awaiting_api' check (status in ('awaiting_api','needs_photos','processing','validated','failed')),
  provider text, provider_reference text,
  confidence numeric check (confidence between 0 and 1),
  data jsonb not null default '{}' check (jsonb_typeof(data) = 'object'),
  requested_photos jsonb not null default '[]' check (jsonb_typeof(requested_photos) = 'array'),
  created_at timestamptz not null default now(),
  unique (company_id, id), foreign key (company_id, job_id) references public.jobs(company_id, id),
  check (status <> 'validated' or (provider is not null and provider_reference is not null and confidence is not null))
);
create index measurements_job on public.measurements(company_id, job_id);

create table public.price_list_items (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  code text not null, name text not null check (length(trim(name)) > 0),
  unit text not null, unit_price_cents bigint not null check (unit_price_cents >= 0),
  active boolean not null default true,
  uploaded_by uuid not null default auth.uid(), updated_at timestamptz not null default now(),
  unique (company_id, id), unique (company_id, code),
  foreign key (company_id, uploaded_by) references public.users(company_id, id)
);
create index prices_uploader on public.price_list_items(company_id, uploaded_by);

create table public.estimates (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  job_id uuid not null, measurement_id uuid,
  status text not null default 'draft' check (status in ('draft','pending_approval','approved','sent','accepted','declined')),
  title text not null default 'Roof replacement estimate',
  line_items jsonb not null default '[]' check (jsonb_typeof(line_items) = 'array'),
  subtotal_cents bigint not null default 0 check (subtotal_cents >= 0),
  tax_basis_points integer not null default 0 check (tax_basis_points between 0 and 10000),
  total_cents bigint not null default 0 check (total_cents >= 0),
  notes text not null default '',
  created_by uuid not null default auth.uid(), approved_by uuid, approved_at timestamptz, sent_at timestamptz,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique (company_id, id), foreign key (company_id, job_id) references public.jobs(company_id, id),
  foreign key (company_id, measurement_id) references public.measurements(company_id, id),
  foreign key (company_id, created_by) references public.users(company_id, id),
  foreign key (company_id, approved_by) references public.users(company_id, id),
  check ((approved_by is null) = (approved_at is null)),
  check (status not in ('approved','sent','accepted') or approved_by is not null),
  check (sent_at is null or approved_at is not null)
);
create index estimates_job on public.estimates(company_id, job_id);
create index estimates_measurement on public.estimates(company_id, measurement_id);
create index estimates_creator on public.estimates(company_id, created_by);
create index estimates_approver on public.estimates(company_id, approved_by);

create table public.claims (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id), job_id uuid not null,
  carrier text not null, claim_number text not null default '',
  adjuster_name text not null default '', adjuster_email text not null default '', adjuster_phone text not null default '',
  loss_date date, status text not null default 'open' check (status in ('open','submitted','negotiating','approved','closed')),
  adjuster_estimate_path text, adjuster_items jsonb not null default '[]' check (jsonb_typeof(adjuster_items) = 'array'),
  last_outbound_at timestamptz, last_response_at timestamptz,
  notes text not null default '', created_at timestamptz not null default now(),
  unique (company_id, id), foreign key (company_id, job_id) references public.jobs(company_id, id)
);
create index claims_job on public.claims(company_id, job_id);

create table public.adjuster_events (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id), claim_id uuid not null,
  kind text not null check (kind in ('call','email_sent','email_received','visit','note')),
  summary text not null, user_id uuid not null default auth.uid(), occurred_at timestamptz not null default now(),
  foreign key (company_id, claim_id) references public.claims(company_id, id),
  foreign key (company_id, user_id) references public.users(company_id, id)
);
create index adjuster_events_claim on public.adjuster_events(company_id, claim_id, occurred_at desc);
create index adjuster_events_user on public.adjuster_events(company_id, user_id);

create table public.reviews (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  job_id uuid not null, rating integer check (rating between 1 and 5),
  feedback text not null default '', recorded_by uuid not null default auth.uid(),
  request_approved_by uuid, request_approved_at timestamptz, requested_at timestamptz,
  created_at timestamptz not null default now(),
  foreign key (company_id, job_id) references public.jobs(company_id, id),
  foreign key (company_id, recorded_by) references public.users(company_id, id),
  foreign key (company_id, request_approved_by) references public.users(company_id, id),
  check ((request_approved_by is null) = (request_approved_at is null)),
  check (requested_at is null or request_approved_at is not null)
);
create index reviews_job on public.reviews(company_id, job_id);
create index reviews_recorder on public.reviews(company_id, recorded_by);
create index reviews_approver on public.reviews(company_id, request_approved_by);

create table public.contracts (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  job_id uuid not null, estimate_id uuid not null,
  status text not null default 'draft' check (status in ('draft','approved','sent','signed','void')),
  body text not null, estimate_snapshot jsonb not null,
  approved_by uuid, approved_at timestamptz, sent_at timestamptz,
  signer_name text, signature_path text, signed_at timestamptz,
  created_by uuid not null default auth.uid(), created_at timestamptz not null default now(),
  unique (company_id, id), foreign key (company_id, job_id) references public.jobs(company_id, id),
  foreign key (company_id, estimate_id) references public.estimates(company_id, id),
  foreign key (company_id, created_by) references public.users(company_id, id),
  foreign key (company_id, approved_by) references public.users(company_id, id),
  check ((approved_by is null) = (approved_at is null)),
  check (status not in ('approved','sent','signed') or approved_by is not null),
  check (sent_at is null or approved_at is not null),
  check (status <> 'signed' or (signed_at is not null and signer_name is not null and signature_path is not null))
);
create index contracts_job on public.contracts(company_id, job_id);
create index contracts_estimate on public.contracts(company_id, estimate_id);
create index contracts_creator on public.contracts(company_id, created_by);
create index contracts_approver on public.contracts(company_id, approved_by);

-- All outbound communication starts as a draft. Only server-side delivery can
-- mark it sent after a human approval. No email/SMS provider is configured yet.
create table public.message_drafts (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  job_id uuid not null, channel text not null check (channel in ('email','text')),
  purpose text not null check (purpose in ('follow_up','adjuster','review_request','review_thanks','contract','estimate')),
  recipient text not null, subject text not null default '', body text not null,
  status text not null default 'draft' check (status in ('draft','approved','sending','sent','failed')),
  created_by uuid not null default auth.uid(), approved_by uuid, approved_at timestamptz, sent_at timestamptz,
  content_version integer not null default 1, approved_version integer,
  delivery_reference text, created_at timestamptz not null default now(),
  foreign key (company_id, job_id) references public.jobs(company_id, id),
  foreign key (company_id, created_by) references public.users(company_id, id),
  foreign key (company_id, approved_by) references public.users(company_id, id),
  check ((approved_by is null) = (approved_at is null)),
  check (status not in ('approved','sending','sent') or (approved_by is not null and approved_version = content_version)),
  check (sent_at is null or approved_at is not null)
);
create index messages_job on public.message_drafts(company_id, job_id);
create index messages_creator on public.message_drafts(company_id, created_by);
create index messages_approver on public.message_drafts(company_id, approved_by);

create table public.hail_assessments (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  job_id uuid not null, photo_id uuid not null,
  slope text not null,
  square_bounds jsonb, hits jsonb not null default '[]' check (jsonb_typeof(hits) = 'array'),
  scale_verified boolean not null default false,
  scale_evidence text not null default '',
  status text not null default 'needs_review' check (status in ('needs_review','reviewed','not_assessable')),
  ai_findings jsonb, reviewed_by uuid, reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  foreign key (company_id, job_id) references public.jobs(company_id, id),
  foreign key (company_id, photo_id) references public.photos(company_id, id),
  foreign key (company_id, reviewed_by) references public.users(company_id, id),
  check (status <> 'reviewed' or (reviewed_by is not null and reviewed_at is not null)),
  check (not scale_verified or length(trim(scale_evidence)) > 0)
);
create index hail_job on public.hail_assessments(company_id, job_id);
create index hail_photo on public.hail_assessments(company_id, photo_id);
create index hail_reviewer on public.hail_assessments(company_id, reviewed_by);

create table public.municipality_resources (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id),
  municipality text not null, title text not null, official_url text not null check (official_url like 'https://%'),
  citation text not null default '', notes text not null default '', verified_on date,
  created_by uuid not null default auth.uid(),
  foreign key (company_id, created_by) references public.users(company_id, id)
);
create index municipality_company on public.municipality_resources(company_id);
create index municipality_creator on public.municipality_resources(company_id, created_by);

create table public.audit_events (
  id bigint generated always as identity primary key,
  company_id uuid not null references public.companies(id), actor_id uuid,
  entity_type text not null, entity_id uuid not null, action text not null,
  created_at timestamptz not null default now()
);
create index audit_company_time on public.audit_events(company_id, created_at desc);

-- These helpers bypass table RLS only to inspect membership. They never accept
-- a client-supplied user ID; the caller is always auth.uid().
create function private.company_access(p_company uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.users u join public.companies c on c.id = u.company_id
    join auth.users a on a.id = u.id
    where u.id = (select auth.uid()) and u.company_id = p_company and u.active
      and a.email_confirmed_at is not null
      and (c.access_mode = 'team' or (u.role = 'owner' and c.owner_user_id = u.id))
  );
$$;
create function private.is_manager(p_company uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select private.company_access(p_company) and exists (
    select 1 from public.users where id = (select auth.uid()) and company_id = p_company and role in ('owner','manager')
  );
$$;
create function private.is_owner(p_company uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select private.company_access(p_company) and exists (
    select 1 from public.users u join public.companies c on c.id = u.company_id
    where u.id = (select auth.uid()) and u.company_id = p_company and u.role = 'owner' and c.owner_user_id = u.id
  );
$$;
create function private.can_contact(p_company uuid, p_contact uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select private.company_access(p_company) and exists (
    select 1 from public.contacts where company_id = p_company and id = p_contact
      and (private.is_manager(p_company) or assigned_to = (select auth.uid()))
  );
$$;
create function private.can_job(p_company uuid, p_job uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select private.company_access(p_company) and exists (
    select 1 from public.jobs where company_id = p_company and id = p_job
      and (private.is_manager(p_company) or assigned_to = (select auth.uid()))
  );
$$;
create function private.can_claim(p_company uuid, p_claim uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.claims where company_id = p_company and id = p_claim and private.can_job(p_company,job_id));
$$;
create function private.can_storage(p_name text) returns boolean
language plpgsql stable security definer set search_path = '' as $$
declare parts text[] := string_to_array(p_name, '/');
begin
  if array_length(parts, 1) < 3 then return false; end if;
  return private.can_job(parts[1]::uuid, parts[2]::uuid);
exception when invalid_text_representation then return false;
end;
$$;

-- Team accounts cannot self-escalate or change company. Provisioning is an
-- owner/manager server operation; owner-only access remains the default.
create function private.provision_owner() returns trigger
language plpgsql security definer set search_path = '' as $$
declare company uuid;
begin
  update public.companies set owner_user_id = new.id
    where lower(owner_email) = lower(new.email) and owner_user_id is null returning id into company;
  if company is not null then
    insert into public.users(id, company_id, display_name, role)
      values (new.id, company, 'Owner', 'owner');
  end if;
  return new;
end;
$$;
create trigger provision_hamriq_owner after insert on auth.users for each row execute function private.provision_owner();

-- Creator attribution is protected even if a caller bypasses the UI.
create function private.guard_actor() returns trigger
language plpgsql set search_path = '' as $$
declare actor_field text := tg_argv[0]; actor uuid;
begin
  if auth.uid() is null then return new; end if;
  actor := (to_jsonb(new)->>actor_field)::uuid;
  if tg_op = 'INSERT' and actor is distinct from auth.uid() then
    raise exception 'Record creator must be the signed-in user.' using errcode = '42501';
  end if;
  if tg_op = 'UPDATE' then
    if to_jsonb(new)->>actor_field is distinct from to_jsonb(old)->>actor_field
      or new.company_id is distinct from old.company_id then
      raise exception 'Record attribution and company cannot be changed.' using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;
create trigger contacts_actor before insert or update on public.contacts for each row execute function private.guard_actor('created_by');
create trigger jobs_actor before insert or update on public.jobs for each row execute function private.guard_actor('created_by');
create trigger touches_actor before insert or update on public.touch_points for each row execute function private.guard_actor('user_id');
create trigger photos_actor before insert or update on public.photos for each row execute function private.guard_actor('uploaded_by');
create trigger follow_actor before insert or update on public.follow_ups for each row execute function private.guard_actor('created_by');
create trigger adjuster_actor before insert or update on public.adjuster_events for each row execute function private.guard_actor('user_id');

create function private.log_change() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.audit_events(company_id, actor_id, entity_type, entity_id, action)
    values (new.company_id, auth.uid(), tg_table_name, new.id, lower(tg_op));
  if tg_table_name in ('jobs','contacts') then new.updated_at := now(); end if;
  return new;
end;
$$;
create trigger audit_jobs before insert or update on public.jobs for each row execute function private.log_change();
create trigger audit_contacts before insert or update on public.contacts for each row execute function private.log_change();

-- Do not grant browser clients any write access to measurements, estimates,
-- contracts, or message approval/sending. They are written through validated RPCs
-- or authenticated server-side functions in subsequent migrations.
do $$ declare t text; begin
  foreach t in array array['companies','users','contacts','jobs','touch_points','follow_ups','photos','measurements','price_list_items','estimates','claims','adjuster_events','reviews','contracts','message_drafts','hail_assessments','municipality_resources','audit_events'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on public.%I from anon, authenticated', t);
    execute format('grant select on public.%I to authenticated', t);
  end loop;
end $$;

create policy companies_read on public.companies for select to authenticated using (private.company_access(id));
create policy users_read on public.users for select to authenticated using (private.company_access(company_id) and (id = (select auth.uid()) or private.is_manager(company_id)));
create policy contacts_read on public.contacts for select to authenticated using (private.can_contact(company_id,id));
create policy contacts_insert on public.contacts for insert to authenticated with check (private.company_access(company_id) and (private.is_manager(company_id) or assigned_to = (select auth.uid())));
create policy contacts_update on public.contacts for update to authenticated using (private.can_contact(company_id,id)) with check (private.company_access(company_id) and (private.is_manager(company_id) or assigned_to = (select auth.uid())));
create policy jobs_read on public.jobs for select to authenticated using (private.can_job(company_id,id));
create policy jobs_insert on public.jobs for insert to authenticated with check (private.can_contact(company_id,contact_id) and (private.is_manager(company_id) or assigned_to = (select auth.uid())));
create policy jobs_update on public.jobs for update to authenticated using (private.can_job(company_id,id)) with check (private.can_contact(company_id,contact_id) and (private.is_manager(company_id) or assigned_to = (select auth.uid())));
create policy touches_read on public.touch_points for select to authenticated using (private.can_contact(company_id,contact_id) and (job_id is null or private.can_job(company_id,job_id)));
create policy touches_insert on public.touch_points for insert to authenticated with check (user_id = (select auth.uid()) and private.can_contact(company_id,contact_id) and (job_id is null or private.can_job(company_id,job_id)));
create policy follow_read on public.follow_ups for select to authenticated using (private.can_job(company_id,job_id) and (private.is_manager(company_id) or assigned_to = (select auth.uid())));
create policy follow_insert on public.follow_ups for insert to authenticated with check (private.can_job(company_id,job_id) and (private.is_manager(company_id) or assigned_to = (select auth.uid())));
create policy follow_update on public.follow_ups for update to authenticated using (private.can_job(company_id,job_id) and (private.is_manager(company_id) or assigned_to = (select auth.uid()))) with check (private.can_job(company_id,job_id) and (private.is_manager(company_id) or assigned_to = (select auth.uid())));
create policy photos_read on public.photos for select to authenticated using (private.can_job(company_id,job_id));
create policy photos_insert on public.photos for insert to authenticated with check (private.can_job(company_id,job_id) and uploaded_by = (select auth.uid()));
create policy price_read on public.price_list_items for select to authenticated using (private.company_access(company_id));
create policy price_insert on public.price_list_items for insert to authenticated with check (private.is_owner(company_id) and uploaded_by = (select auth.uid()));
create policy price_update on public.price_list_items for update to authenticated using (private.is_owner(company_id)) with check (private.is_owner(company_id) and uploaded_by = (select auth.uid()));
create policy claims_read on public.claims for select to authenticated using (private.can_job(company_id,job_id));
create policy claims_insert on public.claims for insert to authenticated with check (private.can_job(company_id,job_id));
create policy claims_update on public.claims for update to authenticated using (private.can_job(company_id,job_id)) with check (private.can_job(company_id,job_id));
create policy adjuster_read on public.adjuster_events for select to authenticated using (private.can_claim(company_id,claim_id));
create policy adjuster_insert on public.adjuster_events for insert to authenticated with check (private.can_claim(company_id,claim_id) and user_id = (select auth.uid()));
create policy reviews_read on public.reviews for select to authenticated using (private.can_job(company_id,job_id));
create policy hail_read on public.hail_assessments for select to authenticated using (private.can_job(company_id,job_id));
create policy resources_read on public.municipality_resources for select to authenticated using (private.company_access(company_id));
create policy resources_insert on public.municipality_resources for insert to authenticated with check (private.is_manager(company_id) and created_by = (select auth.uid()));
create policy resources_update on public.municipality_resources for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy audit_read on public.audit_events for select to authenticated using (private.is_manager(company_id));
do $$ declare t text; begin
  foreach t in array array['measurements','estimates','contracts','message_drafts'] loop
    execute format('create policy job_read on public.%I for select to authenticated using (private.can_job(company_id,job_id))', t);
  end loop;
end $$;

grant insert, update on public.contacts, public.jobs, public.follow_ups, public.price_list_items, public.claims, public.municipality_resources to authenticated;
grant insert on public.touch_points, public.photos, public.adjuster_events to authenticated;
revoke all on all functions in schema private from public, anon, authenticated;
grant execute on function private.company_access(uuid), private.is_manager(uuid), private.is_owner(uuid), private.can_contact(uuid,uuid), private.can_job(uuid,uuid), private.can_claim(uuid,uuid), private.can_storage(text) to authenticated;

-- Private storage, never a public gallery. Paths: company UUID/job UUID/file.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('job-files','job-files',false,26214400,array['image/jpeg','image/png','image/webp','application/pdf'])
on conflict (id) do nothing;
create policy hamriq_files_read on storage.objects for select to authenticated using (bucket_id = 'job-files' and private.can_storage(name));
create policy hamriq_files_insert on storage.objects for insert to authenticated with check (bucket_id = 'job-files' and private.can_storage(name));
create policy hamriq_files_delete on storage.objects for delete to authenticated using (bucket_id = 'job-files' and private.can_storage(name) and owner_id = (select auth.uid())::text);

create function public.dashboard_summary() returns jsonb
language plpgsql stable security invoker set search_path = '' as $$
declare company uuid; local_day date; week_start timestamptz; local_end timestamptz;
begin
  select company_id into company from public.users where id = auth.uid() and active;
  if company is null or not private.company_access(company) then raise exception 'Private access required.' using errcode = '42501'; end if;
  local_day := (now() at time zone 'America/Detroit')::date;
  week_start := date_trunc('week', now() at time zone 'America/Detroit') at time zone 'America/Detroit';
  local_end := (local_day + 1)::timestamp at time zone 'America/Detroit';
  return jsonb_build_object(
    'active_jobs',(select count(*) from public.jobs where company_id = company and stage <> 'Complete'),
    'total_jobs',(select count(*) from public.jobs where company_id = company),
    'completed_jobs',(select count(*) from public.jobs where company_id = company and stage = 'Complete'),
    'photos_this_week',(select count(*) from public.photos where company_id = company and uploaded_at >= week_start and uploaded_at < local_end),
    'pending_estimates',(select count(*) from public.estimates where company_id = company and status in ('draft','pending_approval','approved')),
    'follow_ups_today',(select count(*) from public.follow_ups where company_id = company and due_on = local_day and completed_at is null),
    'latest_photo_path',(select storage_path from public.photos where company_id = company order by uploaded_at desc limit 1),
    'local_date',local_day::text,
    'stage_counts',(select jsonb_object_agg(s::text,(select count(*) from public.jobs where company_id = company and stage = s)) from unnest(enum_range(null::public.job_stage)) s)
  );
end;
$$;
revoke all on function public.dashboard_summary() from public, anon;
grant execute on function public.dashboard_summary() to authenticated;

-- JSON response to initialize the app without accepting a client company ID.
create function public.workspace_context() returns jsonb
language sql stable security invoker set search_path = '' as $$
  select jsonb_build_object('user',to_jsonb(u),'company',to_jsonb(c) - 'owner_email')
  from public.users u join public.companies c on c.id = u.company_id
  where u.id = auth.uid() and u.active and private.company_access(c.id);
$$;
revoke all on function public.workspace_context() from public, anon;
grant execute on function public.workspace_context() to authenticated;

comment on table public.measurements is 'API integration pending. No browser write privileges. Never manually edit AI measurements; request additional photos instead.';
comment on table public.price_list_items is 'Owner-supplied prices only; never seed default or AI-suggested prices.';
comment on table public.adjuster_events is 'Typed touch-point records only. No audio recording or voice transcription.';
