-- HAMRIQ document/compliance expiration layer
-- Adds document categories/records, license and insurance tracking, renewal reminders,
-- permit tasks, employee document assignments, and compliance alerts.

create table if not exists public.document_categories (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null,
  applies_to text not null default 'company',
  requires_expiration boolean not null default false,
  default_renewal_notice_days integer not null default 30,
  active boolean not null default true,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.document_records (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  category_id uuid references public.document_categories(id),
  owner_type text not null default 'company',
  owner_id uuid,
  job_id uuid,
  title text not null,
  document_url text,
  status text not null default 'active',
  issue_date date,
  expiration_date date,
  renewal_notice_days integer not null default 30,
  uploaded_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.license_insurance_records (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  holder_type text not null default 'company',
  holder_id uuid,
  record_type text not null,
  provider text,
  policy_or_license_number text,
  status text not null default 'active',
  effective_date date,
  expiration_date date,
  document_record_id uuid references public.document_records(id),
  renewal_owner uuid,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.document_renewal_reminders (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  document_record_id uuid references public.document_records(id) on delete cascade,
  license_insurance_record_id uuid references public.license_insurance_records(id) on delete cascade,
  reminder_date date not null,
  status text not null default 'scheduled',
  assigned_to uuid,
  message text,
  created_at timestamptz not null default now()
);

create table if not exists public.permit_tasks (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  permit_id uuid references public.permits(id),
  task_name text not null,
  status text not null default 'pending',
  jurisdiction text,
  required_by date,
  submitted_at timestamptz,
  approved_at timestamptz,
  document_record_id uuid references public.document_records(id),
  assigned_to uuid,
  notes text,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.employee_document_assignments (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null,
  document_record_id uuid references public.document_records(id) on delete cascade,
  assignment_type text not null default 'acknowledgment',
  status text not null default 'pending',
  due_date date,
  acknowledged_at timestamptz,
  acknowledged_ip text,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.compliance_alerts (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  related_table text not null,
  related_id uuid,
  alert_type text not null,
  severity text not null default 'medium',
  title text not null,
  body text,
  status text not null default 'open',
  assigned_to uuid,
  due_date date,
  resolved_by uuid,
  resolved_at timestamptz,
  created_at timestamptz not null default now()
);

-- Live migration also includes indexes, grants, and RLS policies using existing HAMRIQ helpers.
