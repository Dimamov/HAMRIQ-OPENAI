create table if not exists public.approved_feature_registry (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  feature_key text not null,
  category text not null,
  title text not null,
  status text not null default 'foundation_created' check (status in ('approved','foundation_created','ui_pending','api_pending','external_integration_pending','manager_setup_required','complete','deferred')),
  implementation_layer text not null default 'database' check (implementation_layer in ('database','api','ui','external_integration','documentation','mixed')),
  requires_ai_training boolean not null default false,
  requires_external_subscription boolean not null default false,
  manager_control_required boolean not null default true,
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (company_id, feature_key)
);

alter table public.approved_feature_registry enable row level security;
revoke all on public.approved_feature_registry from anon, authenticated;
grant select on public.approved_feature_registry to authenticated;
grant insert, update on public.approved_feature_registry to authenticated;

drop policy if exists approved_feature_registry_read on public.approved_feature_registry;
create policy approved_feature_registry_read on public.approved_feature_registry
  for select to authenticated using (private.company_access(company_id));

drop policy if exists approved_feature_registry_insert on public.approved_feature_registry;
create policy approved_feature_registry_insert on public.approved_feature_registry
  for insert to authenticated with check (private.is_manager(company_id));

drop policy if exists approved_feature_registry_update on public.approved_feature_registry;
create policy approved_feature_registry_update on public.approved_feature_registry
  for update to authenticated using (private.is_manager(company_id)) with check (private.is_manager(company_id));

insert into public.approved_feature_registry (company_id, feature_key, category, title, status, implementation_layer, requires_ai_training, requires_external_subscription, manager_control_required, notes)
select c.id, v.feature_key, v.category, v.title, v.status, v.implementation_layer, v.requires_ai_training, v.requires_external_subscription, v.manager_control_required, v.notes
from public.companies c
cross join (values
  ('lead_source_creation','CRM','Lead source at lead creation','foundation_created','database',false,false,true,'Reps can mark lead source when creating a lead.'),
  ('door_hanger_outcome','Prospecting','Door Hanger Placed outcome','foundation_created','database',false,false,true,'Prospecting visits support door hanger tracking.'),
  ('rep_routes','Routing','Rep-created routes and route stops','foundation_created','database',false,false,true,'Routes and route stops exist; optimization logic can build on these records.'),
  ('storm_data_integrations','Storm Data','HailTrace / Hail Recon integration slot','external_integration_pending','mixed',false,true,true,'Additional subscription required. Contact HAMRIQ for information.'),
  ('ai_performance_insights','AI','AI performance insights notice','ui_pending','mixed',true,false,true,'AI requires training/data; better and more data improves results.'),
  ('measurement_provider_fallback','Measurements','EagleView / Hover measurement fallback','manager_setup_required','mixed',false,true,true,'Internal measurement first; connect external provider if needed. Orders require manager approval by default.'),
  ('manager_pricing','Pricing','Manager-controlled pricing','foundation_created','database',false,false,true,'Reps cannot change master pricing.'),
  ('review_funnel','Reviews','Internal rating then public review links','foundation_created','database',false,false,true,'4-5 star internal ratings can trigger Google/Facebook/manager-added review sites.'),
  ('approval_center','Approvals','Manager approval center','foundation_created','database',false,false,true,'Central approval queue for pricing, measurements, supplements, material orders, AI changes, etc.'),
  ('production_control','Production','Production scheduling and live controls','foundation_created','database',false,false,true,'Production plans, issues, stages, delivery verification, and related control tables are in place.'),
  ('billing_finance','Billing','Manager-only billing and finance layer','foundation_created','database',false,false,true,'Invoices, payments, commissions, job costing, and compliance foundations are present.'),
  ('photo_ai_workflow','Inspection','AI photo quality/damage workflow','foundation_created','database',true,false,true,'Photo analyses, inspection reviews, completeness checks, and additional structures workflow exist.'),
  ('hammy_voice_capture','Hammy','Hammy voice/capture workflow','foundation_created','database',true,false,true,'Hammy capture, frequent questions, and lead-detail RPC foundations exist.'),
  ('commercial_workflow','Commercial','Commercial roofing workflow','foundation_created','database',false,false,true,'Commercial bids, RFI/submittal, progress billing, retainage, and closeout foundations exist.'),
  ('people_payroll','People','People, performance, payroll and recruiting layer','foundation_created','database',false,true,true,'Training, reviews, payroll exports, reimbursement, time, mileage, and applicant foundations exist.'),
  ('collaboration_calendar','Operations','Collaboration, scheduling, announcements and tasks','foundation_created','database',false,false,true,'Tasks, calendar, availability, team chat, announcements, and notification tables are present.'),
  ('marketing_growth','Marketing','Campaign, referral, QR, reputation and ROI layer','foundation_created','database',true,true,true,'Marketing campaign, QR, lead capture, referrals, reputation, and ROI foundations exist.'),
  ('backup_system_health','System','Backup, recovery and system health layer','foundation_created','database',true,false,true,'Backup/recovery and system health event foundations exist.')
) as v(feature_key, category, title, status, implementation_layer, requires_ai_training, requires_external_subscription, manager_control_required, notes)
on conflict (company_id, feature_key) do update set
  category = excluded.category,
  title = excluded.title,
  status = excluded.status,
  implementation_layer = excluded.implementation_layer,
  requires_ai_training = excluded.requires_ai_training,
  requires_external_subscription = excluded.requires_external_subscription,
  manager_control_required = excluded.manager_control_required,
  notes = excluded.notes,
  updated_at = now();

comment on table public.approved_feature_registry is 'Internal HAMRIQ implementation tracker for approved features. External integrations marked here may require additional subscription: Contact HAMRIQ for information.';
