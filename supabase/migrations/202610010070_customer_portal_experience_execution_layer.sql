create table if not exists public.customer_portal_home_views_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid,
  contact_id uuid,
  portal_session_id uuid,
  viewed_at timestamptz not null default now(),
  visible_sections jsonb not null default '[]'::jsonb,
  homeowner_status_summary text not null default '',
  manager_review_required boolean not null default false,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.portal_status_milestones_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid not null,
  contact_id uuid,
  milestone_key text not null,
  milestone_label text not null,
  milestone_status text not null default 'pending' check (milestone_status in ('pending','active','complete','blocked','hidden')),
  display_order int not null default 0,
  homeowner_description text not null default '',
  internal_notes text not null default '',
  completed_at timestamptz,
  manager_review_required boolean not null default false,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.portal_document_share_packages_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid,
  contact_id uuid,
  package_name text not null,
  document_ids jsonb not null default '[]'::jsonb,
  share_status text not null default 'draft' check (share_status in ('draft','shared','viewed','revoked','expired')),
  expires_at timestamptz,
  manager_review_required boolean not null default false,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.portal_selection_tasks_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid,
  contact_id uuid,
  selection_type text not null default 'product' check (selection_type in ('shingle','drip_edge','gutter','accessory','product','color','other')),
  task_label text not null,
  available_options jsonb not null default '[]'::jsonb,
  selected_option jsonb not null default '{}'::jsonb,
  task_status text not null default 'open' check (task_status in ('open','selected','approved','rejected','locked')),
  locked_at timestamptz,
  manager_review_required boolean not null default false,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.portal_message_notifications_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid,
  contact_id uuid,
  message_thread_id uuid,
  notification_channel text not null default 'portal' check (notification_channel in ('portal','sms','email','push')),
  notification_status text not null default 'pending' check (notification_status in ('pending','sent','viewed','failed','cancelled')),
  title text not null default '',
  body text not null default '',
  sent_at timestamptz,
  viewed_at timestamptz,
  manager_review_required boolean not null default false,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.portal_appointment_views_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid,
  contact_id uuid,
  calendar_event_id uuid,
  appointment_title text not null,
  appointment_start_at timestamptz not null,
  appointment_status text not null default 'scheduled' check (appointment_status in ('scheduled','confirmed','reschedule_requested','completed','cancelled','missed')),
  homeowner_visible_notes text not null default '',
  manager_review_required boolean not null default false,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.portal_payment_request_views_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid,
  contact_id uuid,
  invoice_id uuid,
  amount_cents bigint not null default 0,
  payment_label text not null,
  payment_status text not null default 'open' check (payment_status in ('open','viewed','paid','partial','cancelled','failed')),
  due_at timestamptz,
  manager_review_required boolean not null default false,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.portal_signoff_requests_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid,
  contact_id uuid,
  signoff_type text not null default 'completion' check (signoff_type in ('selection','scope','change_order','completion','warranty','other')),
  signoff_label text not null,
  request_status text not null default 'requested' check (request_status in ('draft','requested','signed','declined','expired','cancelled')),
  requested_at timestamptz,
  signed_at timestamptz,
  signer_name text not null default '',
  signature_payload jsonb not null default '{}'::jsonb,
  manager_review_required boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.customer_portal_home_views_deep enable row level security;
alter table public.portal_status_milestones_deep enable row level security;
alter table public.portal_document_share_packages_deep enable row level security;
alter table public.portal_selection_tasks_deep enable row level security;
alter table public.portal_message_notifications_deep enable row level security;
alter table public.portal_appointment_views_deep enable row level security;
alter table public.portal_payment_request_views_deep enable row level security;
alter table public.portal_signoff_requests_deep enable row level security;