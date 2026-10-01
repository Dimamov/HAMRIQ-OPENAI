create table if not exists public.website_lead_capture_forms_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  form_name text not null,
  source_page text,
  form_status text not null default 'draft' check (form_status in ('draft','active','paused','archived')),
  lead_source text not null default 'Website',
  fields_config jsonb not null default '[]'::jsonb,
  routing_rules jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.qr_lead_capture_codes_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  code_name text not null,
  destination_url text,
  campaign_id uuid,
  assigned_rep_user_id uuid,
  status text not null default 'active' check (status in ('active','paused','retired')),
  scan_count integer not null default 0,
  lead_count integer not null default 0,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.marketing_campaign_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  campaign_name text not null,
  campaign_type text not null default 'mixed' check (campaign_type in ('website','qr','direct_mail','neighborhood','email','sms','social','mixed')),
  campaign_status text not null default 'draft' check (campaign_status in ('draft','scheduled','active','paused','complete','archived')),
  start_date date,
  end_date date,
  budget_cents bigint not null default 0,
  spend_cents bigint not null default 0,
  target_areas jsonb not null default '[]'::jsonb,
  goals jsonb not null default '{}'::jsonb,
  ai_generated boolean not null default false,
  human_review_required boolean not null default true,
  approved_by uuid,
  approved_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.direct_mail_fulfillment_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  campaign_run_id uuid references public.marketing_campaign_runs_deep(id) on delete set null,
  provider_name text,
  mailer_name text not null,
  fulfillment_status text not null default 'draft' check (fulfillment_status in ('draft','review_needed','approved','sent_to_provider','in_mail','delivered','cancelled','failed')),
  recipient_count integer not null default 0,
  estimated_cost_cents bigint not null default 0,
  actual_cost_cents bigint not null default 0,
  artwork_asset_url text,
  provider_payload jsonb not null default '{}'::jsonb,
  additional_subscription_required boolean not null default true,
  subscription_notice text not null default 'Additional subscription required. Contact HAMRIQ for information.',
  manager_review_required boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.neighborhood_campaign_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  campaign_run_id uuid references public.marketing_campaign_runs_deep(id) on delete set null,
  neighborhood_name text not null,
  city text,
  state text,
  polygon_geojson jsonb not null default '{}'::jsonb,
  opportunity_score numeric(6,2),
  campaign_status text not null default 'planned' check (campaign_status in ('planned','active','paused','complete','archived')),
  target_home_count integer not null default 0,
  assigned_rep_user_id uuid,
  notes text,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.marketing_roi_snapshots_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  campaign_run_id uuid references public.marketing_campaign_runs_deep(id) on delete cascade,
  snapshot_date date not null default current_date,
  leads_count integer not null default 0,
  appointments_count integer not null default 0,
  inspections_count integer not null default 0,
  signed_jobs_count integer not null default 0,
  revenue_cents bigint not null default 0,
  spend_cents bigint not null default 0,
  roi_percent numeric(8,2),
  attribution_notes text,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.ai_marketing_draft_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  campaign_run_id uuid references public.marketing_campaign_runs_deep(id) on delete set null,
  draft_type text not null default 'campaign' check (draft_type in ('campaign','sms','email','direct_mail','door_hanger','social','ad_copy')),
  prompt_text text,
  draft_content text not null default '',
  target_audience text,
  status text not null default 'review_needed' check (status in ('draft','review_needed','approved','rejected','archived')),
  human_review_required boolean not null default true,
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.marketing_lead_capture_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  campaign_run_id uuid references public.marketing_campaign_runs_deep(id) on delete set null,
  job_id uuid,
  contact_id uuid,
  event_type text not null,
  event_summary text,
  event_payload jsonb not null default '{}'::jsonb,
  performed_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create index if not exists idx_website_lead_capture_forms_company on public.website_lead_capture_forms_deep(company_id, form_status);
create index if not exists idx_qr_lead_capture_codes_company on public.qr_lead_capture_codes_deep(company_id, status);
create index if not exists idx_marketing_campaign_runs_company on public.marketing_campaign_runs_deep(company_id, campaign_status);
create index if not exists idx_direct_mail_fulfillment_company on public.direct_mail_fulfillment_runs_deep(company_id, fulfillment_status);
create index if not exists idx_neighborhood_campaign_company on public.neighborhood_campaign_runs_deep(company_id, campaign_status);
create index if not exists idx_marketing_roi_snapshots_company on public.marketing_roi_snapshots_deep(company_id, snapshot_date desc);
create index if not exists idx_ai_marketing_draft_company on public.ai_marketing_draft_runs_deep(company_id, status);
create index if not exists idx_marketing_activity_company on public.marketing_lead_capture_activity_events_deep(company_id, created_at desc);

alter table public.website_lead_capture_forms_deep enable row level security;
alter table public.qr_lead_capture_codes_deep enable row level security;
alter table public.marketing_campaign_runs_deep enable row level security;
alter table public.direct_mail_fulfillment_runs_deep enable row level security;
alter table public.neighborhood_campaign_runs_deep enable row level security;
alter table public.marketing_roi_snapshots_deep enable row level security;
alter table public.ai_marketing_draft_runs_deep enable row level security;
alter table public.marketing_lead_capture_activity_events_deep enable row level security;

revoke all on public.website_lead_capture_forms_deep from anon, authenticated;
revoke all on public.qr_lead_capture_codes_deep from anon, authenticated;
revoke all on public.marketing_campaign_runs_deep from anon, authenticated;
revoke all on public.direct_mail_fulfillment_runs_deep from anon, authenticated;
revoke all on public.neighborhood_campaign_runs_deep from anon, authenticated;
revoke all on public.marketing_roi_snapshots_deep from anon, authenticated;
revoke all on public.ai_marketing_draft_runs_deep from anon, authenticated;
revoke all on public.marketing_lead_capture_activity_events_deep from anon, authenticated;

grant select, insert, update on public.website_lead_capture_forms_deep to authenticated;
grant select, insert, update on public.qr_lead_capture_codes_deep to authenticated;
grant select, insert, update on public.marketing_campaign_runs_deep to authenticated;
grant select, insert, update on public.direct_mail_fulfillment_runs_deep to authenticated;
grant select, insert, update on public.neighborhood_campaign_runs_deep to authenticated;
grant select, insert, update on public.marketing_roi_snapshots_deep to authenticated;
grant select, insert, update on public.ai_marketing_draft_runs_deep to authenticated;
grant select, insert, update on public.marketing_lead_capture_activity_events_deep to authenticated;

create policy website_lead_forms_company_access on public.website_lead_capture_forms_deep for select using (private.company_access(company_id));
create policy website_lead_forms_manager_write on public.website_lead_capture_forms_deep for insert with check (private.is_manager(company_id));
create policy website_lead_forms_manager_update on public.website_lead_capture_forms_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy qr_lead_codes_company_access on public.qr_lead_capture_codes_deep for select using (private.company_access(company_id));
create policy qr_lead_codes_manager_write on public.qr_lead_capture_codes_deep for insert with check (private.is_manager(company_id));
create policy qr_lead_codes_manager_update on public.qr_lead_capture_codes_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy marketing_campaign_runs_company_access on public.marketing_campaign_runs_deep for select using (private.company_access(company_id));
create policy marketing_campaign_runs_manager_write on public.marketing_campaign_runs_deep for insert with check (private.is_manager(company_id));
create policy marketing_campaign_runs_manager_update on public.marketing_campaign_runs_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy direct_mail_company_access on public.direct_mail_fulfillment_runs_deep for select using (private.company_access(company_id));
create policy direct_mail_manager_write on public.direct_mail_fulfillment_runs_deep for insert with check (private.is_manager(company_id));
create policy direct_mail_manager_update on public.direct_mail_fulfillment_runs_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy neighborhood_campaign_company_access on public.neighborhood_campaign_runs_deep for select using (private.company_access(company_id));
create policy neighborhood_campaign_manager_insert on public.neighborhood_campaign_runs_deep for insert with check (private.is_manager(company_id));
create policy neighborhood_campaign_manager_update on public.neighborhood_campaign_runs_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy marketing_roi_manager_access on public.marketing_roi_snapshots_deep for select using (private.is_manager(company_id));
create policy marketing_roi_manager_insert on public.marketing_roi_snapshots_deep for insert with check (private.is_manager(company_id));
create policy marketing_roi_manager_update on public.marketing_roi_snapshots_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy ai_marketing_draft_company_access on public.ai_marketing_draft_runs_deep for select using (private.company_access(company_id));
create policy ai_marketing_draft_manager_insert on public.ai_marketing_draft_runs_deep for insert with check (private.is_manager(company_id));
create policy ai_marketing_draft_manager_update on public.ai_marketing_draft_runs_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy marketing_activity_company_access on public.marketing_lead_capture_activity_events_deep for select using (private.company_access(company_id));
create policy marketing_activity_company_insert on public.marketing_lead_capture_activity_events_deep for insert with check (private.company_access(company_id));
create policy marketing_activity_manager_update on public.marketing_lead_capture_activity_events_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));
