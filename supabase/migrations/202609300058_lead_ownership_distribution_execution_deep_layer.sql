-- HAMRIQ lead ownership and distribution execution layer
-- Adds smart assignment decisions, rep capacity snapshots, territory conflict resolution,
-- lead ownership claims, takeover requests, reassignment approvals, SLA tracking, and audit events.

create table if not exists public.lead_assignment_decision_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  contact_id uuid references public.contacts(id) on delete set null,
  job_id uuid references public.jobs(id) on delete set null,
  recommended_rep_user_id uuid,
  assigned_rep_user_id uuid,
  decision_status text not null default 'pending_review' check (decision_status in ('pending_review','approved','rejected','assigned','overridden','cancelled')),
  decision_source text not null default 'hamriq_ai' check (decision_source in ('manual','hamriq_ai','round_robin','territory_rule','manager_override')),
  assignment_reason text not null default '',
  scoring_snapshot jsonb not null default '{}'::jsonb,
  manager_review_required boolean not null default true,
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_active boolean not null default true
);

create table if not exists public.rep_assignment_capacity_snapshots_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  rep_user_id uuid not null,
  snapshot_date date not null default current_date,
  open_leads_count integer not null default 0,
  active_jobs_count integer not null default 0,
  appointments_today_count integer not null default 0,
  overdue_followups_count integer not null default 0,
  capacity_status text not null default 'normal' check (capacity_status in ('low','normal','busy','overloaded','unavailable')),
  capacity_notes text not null default '',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_active boolean not null default true
);

create table if not exists public.territory_assignment_conflicts_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  contact_id uuid references public.contacts(id) on delete set null,
  job_id uuid references public.jobs(id) on delete set null,
  territory_id uuid,
  conflict_status text not null default 'open' check (conflict_status in ('open','manager_review','resolved','dismissed','escalated')),
  conflict_type text not null default 'overlap' check (conflict_type in ('overlap','duplicate_knock','existing_customer','rep_claim','route_conflict','other')),
  involved_rep_user_ids uuid[] not null default '{}'::uuid[],
  recommended_resolution text not null default '',
  final_resolution text not null default '',
  resolved_by uuid,
  resolved_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_active boolean not null default true
);

create table if not exists public.lead_ownership_claims_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  contact_id uuid references public.contacts(id) on delete set null,
  job_id uuid references public.jobs(id) on delete set null,
  claiming_rep_user_id uuid not null default auth.uid(),
  claim_status text not null default 'pending' check (claim_status in ('pending','approved','rejected','expired','withdrawn')),
  claim_reason text not null default '',
  supporting_notes text not null default '',
  evidence_payload jsonb not null default '{}'::jsonb,
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_active boolean not null default true
);

create table if not exists public.lead_takeover_requests_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  contact_id uuid references public.contacts(id) on delete set null,
  job_id uuid references public.jobs(id) on delete set null,
  from_rep_user_id uuid,
  to_rep_user_id uuid not null,
  request_status text not null default 'pending_manager_review' check (request_status in ('pending_manager_review','approved','rejected','cancelled','completed')),
  takeover_reason text not null default '',
  homeowner_context text not null default '',
  manager_notes text not null default '',
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_active boolean not null default true
);

create table if not exists public.lead_reassignment_approval_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  takeover_request_id uuid references public.lead_takeover_requests_deep(id) on delete set null,
  assignment_decision_id uuid references public.lead_assignment_decision_runs_deep(id) on delete set null,
  job_id uuid references public.jobs(id) on delete set null,
  approval_status text not null default 'pending' check (approval_status in ('pending','approved','rejected','expired','cancelled')),
  required_approver_role text not null default 'manager',
  approval_notes text not null default '',
  approved_by uuid,
  approved_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_active boolean not null default true
);

create table if not exists public.lead_distribution_sla_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  contact_id uuid references public.contacts(id) on delete set null,
  job_id uuid references public.jobs(id) on delete set null,
  assigned_rep_user_id uuid,
  sla_status text not null default 'watching' check (sla_status in ('watching','on_time','at_risk','breached','resolved','waived')),
  response_due_at timestamptz,
  first_response_at timestamptz,
  breach_reason text not null default '',
  escalation_payload jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_active boolean not null default true
);

create table if not exists public.lead_ownership_audit_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  contact_id uuid references public.contacts(id) on delete set null,
  job_id uuid references public.jobs(id) on delete set null,
  event_type text not null default 'ownership_changed',
  old_owner_user_id uuid,
  new_owner_user_id uuid,
  event_notes text not null default '',
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  is_active boolean not null default true
);

create index if not exists idx_lead_assignment_decision_runs_deep_company on public.lead_assignment_decision_runs_deep(company_id, decision_status, created_at desc);
create index if not exists idx_rep_assignment_capacity_snapshots_deep_company on public.rep_assignment_capacity_snapshots_deep(company_id, rep_user_id, snapshot_date desc);
create index if not exists idx_territory_assignment_conflicts_deep_company on public.territory_assignment_conflicts_deep(company_id, conflict_status, created_at desc);
create index if not exists idx_lead_ownership_claims_deep_company on public.lead_ownership_claims_deep(company_id, claim_status, created_at desc);
create index if not exists idx_lead_takeover_requests_deep_company on public.lead_takeover_requests_deep(company_id, request_status, created_at desc);
create index if not exists idx_lead_reassignment_approval_runs_deep_company on public.lead_reassignment_approval_runs_deep(company_id, approval_status, created_at desc);
create index if not exists idx_lead_distribution_sla_events_deep_company on public.lead_distribution_sla_events_deep(company_id, sla_status, created_at desc);
create index if not exists idx_lead_ownership_audit_events_deep_company on public.lead_ownership_audit_events_deep(company_id, created_at desc);

alter table public.lead_assignment_decision_runs_deep enable row level security;
alter table public.rep_assignment_capacity_snapshots_deep enable row level security;
alter table public.territory_assignment_conflicts_deep enable row level security;
alter table public.lead_ownership_claims_deep enable row level security;
alter table public.lead_takeover_requests_deep enable row level security;
alter table public.lead_reassignment_approval_runs_deep enable row level security;
alter table public.lead_distribution_sla_events_deep enable row level security;
alter table public.lead_ownership_audit_events_deep enable row level security;

revoke all on public.lead_assignment_decision_runs_deep from anon, authenticated;
revoke all on public.rep_assignment_capacity_snapshots_deep from anon, authenticated;
revoke all on public.territory_assignment_conflicts_deep from anon, authenticated;
revoke all on public.lead_ownership_claims_deep from anon, authenticated;
revoke all on public.lead_takeover_requests_deep from anon, authenticated;
revoke all on public.lead_reassignment_approval_runs_deep from anon, authenticated;
revoke all on public.lead_distribution_sla_events_deep from anon, authenticated;
revoke all on public.lead_ownership_audit_events_deep from anon, authenticated;

grant select, insert, update on public.lead_assignment_decision_runs_deep to authenticated;
grant select, insert, update on public.rep_assignment_capacity_snapshots_deep to authenticated;
grant select, insert, update on public.territory_assignment_conflicts_deep to authenticated;
grant select, insert, update on public.lead_ownership_claims_deep to authenticated;
grant select, insert, update on public.lead_takeover_requests_deep to authenticated;
grant select, insert, update on public.lead_reassignment_approval_runs_deep to authenticated;
grant select, insert, update on public.lead_distribution_sla_events_deep to authenticated;
grant select, insert, update on public.lead_ownership_audit_events_deep to authenticated;

create policy lead_assignment_decision_runs_deep_manager_all on public.lead_assignment_decision_runs_deep for all using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy lead_assignment_decision_runs_deep_rep_read on public.lead_assignment_decision_runs_deep for select using (recommended_rep_user_id = auth.uid() or assigned_rep_user_id = auth.uid() or private.can_job(company_id, job_id));
create policy rep_assignment_capacity_snapshots_deep_manager_all on public.rep_assignment_capacity_snapshots_deep for all using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy rep_assignment_capacity_snapshots_deep_rep_read on public.rep_assignment_capacity_snapshots_deep for select using (rep_user_id = auth.uid());
create policy territory_assignment_conflicts_deep_manager_all on public.territory_assignment_conflicts_deep for all using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy territory_assignment_conflicts_deep_rep_read on public.territory_assignment_conflicts_deep for select using (auth.uid() = any(involved_rep_user_ids) or private.can_job(company_id, job_id));
create policy lead_ownership_claims_deep_manager_all on public.lead_ownership_claims_deep for all using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy lead_ownership_claims_deep_rep_own on public.lead_ownership_claims_deep for all using (claiming_rep_user_id = auth.uid()) with check (claiming_rep_user_id = auth.uid() and private.company_access(company_id));
create policy lead_takeover_requests_deep_manager_all on public.lead_takeover_requests_deep for all using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy lead_takeover_requests_deep_rep_read on public.lead_takeover_requests_deep for select using (from_rep_user_id = auth.uid() or to_rep_user_id = auth.uid());
create policy lead_takeover_requests_deep_rep_create on public.lead_takeover_requests_deep for insert with check ((to_rep_user_id = auth.uid() or created_by = auth.uid()) and private.company_access(company_id));
create policy lead_reassignment_approval_runs_deep_manager_all on public.lead_reassignment_approval_runs_deep for all using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy lead_reassignment_approval_runs_deep_job_read on public.lead_reassignment_approval_runs_deep for select using (private.can_job(company_id, job_id));
create policy lead_distribution_sla_events_deep_manager_all on public.lead_distribution_sla_events_deep for all using (private.is_manager(company_id)) with check (private.is_manager(company_id));
create policy lead_distribution_sla_events_deep_rep_read_update on public.lead_distribution_sla_events_deep for all using (assigned_rep_user_id = auth.uid() or private.can_job(company_id, job_id)) with check (assigned_rep_user_id = auth.uid() or private.can_job(company_id, job_id));
create policy lead_ownership_audit_events_deep_company_read on public.lead_ownership_audit_events_deep for select using (private.company_access(company_id));
create policy lead_ownership_audit_events_deep_manager_write on public.lead_ownership_audit_events_deep for insert with check (private.is_manager(company_id));
