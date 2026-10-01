create table if not exists public.duplicate_payment_scan_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  scan_name text not null default 'Duplicate payment scan',
  scan_scope text not null default 'company' check (scan_scope in ('company','vendor','job','invoice','payment_batch')),
  scan_status text not null default 'queued' check (scan_status in ('queued','running','review_needed','cleared','resolved','failed')),
  scan_started_at timestamptz,
  scan_completed_at timestamptz,
  duplicate_candidates_count integer not null default 0,
  high_risk_count integer not null default 0,
  requires_manager_review boolean not null default true,
  scan_parameters jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.duplicate_payment_candidates_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  scan_run_id uuid references public.duplicate_payment_scan_runs_deep(id) on delete set null,
  job_id uuid references public.jobs(id) on delete set null,
  vendor_name text not null default '',
  invoice_number text not null default '',
  payment_reference text not null default '',
  first_payment_cents bigint not null default 0,
  second_payment_cents bigint not null default 0,
  match_confidence numeric(5,2) not null default 0,
  risk_level text not null default 'medium' check (risk_level in ('low','medium','high','critical')),
  candidate_status text not null default 'review_needed' check (candidate_status in ('review_needed','confirmed_duplicate','false_positive','refund_needed','resolved')),
  evidence jsonb not null default '{}'::jsonb,
  assigned_reviewer uuid,
  reviewed_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.vendor_payment_risk_signals_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  vendor_name text not null default '',
  job_id uuid references public.jobs(id) on delete set null,
  signal_type text not null default 'unusual_amount' check (signal_type in ('unusual_amount','new_vendor','bank_change','rapid_repeat_payment','invoice_pattern','manual_override','other')),
  signal_status text not null default 'open' check (signal_status in ('open','reviewing','dismissed','confirmed','resolved')),
  risk_level text not null default 'medium' check (risk_level in ('low','medium','high','critical')),
  amount_cents bigint not null default 0,
  requires_manager_review boolean not null default true,
  signal_summary text not null default '',
  signal_evidence jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.invoice_mismatch_checks_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  invoice_identifier text not null default '',
  expected_amount_cents bigint not null default 0,
  submitted_amount_cents bigint not null default 0,
  mismatch_amount_cents bigint not null default 0,
  mismatch_type text not null default 'amount' check (mismatch_type in ('amount','line_item','vendor','tax','job','duplicate','other')),
  check_status text not null default 'review_needed' check (check_status in ('review_needed','approved','rejected','corrected','resolved')),
  requires_manager_review boolean not null default true,
  mismatch_notes text not null default '',
  evidence jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.payment_fraud_review_queue_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  review_source text not null default 'ai_signal' check (review_source in ('duplicate_scan','vendor_signal','invoice_mismatch','manual_flag','ai_signal','other')),
  source_record_id uuid,
  review_priority text not null default 'normal' check (review_priority in ('low','normal','high','urgent')),
  review_status text not null default 'open' check (review_status in ('open','assigned','in_review','approved','blocked','resolved','dismissed')),
  assigned_manager uuid,
  due_at timestamptz,
  decision_summary text not null default '',
  decision_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.fraud_resolution_actions_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  review_queue_id uuid references public.payment_fraud_review_queue_deep(id) on delete set null,
  job_id uuid references public.jobs(id) on delete set null,
  action_type text not null default 'note' check (action_type in ('note','hold_payment','release_payment','request_refund','contact_vendor','correct_invoice','dismiss','escalate','other')),
  action_status text not null default 'open' check (action_status in ('open','in_progress','complete','cancelled')),
  action_summary text not null default '',
  amount_held_cents bigint not null default 0,
  amount_recovered_cents bigint not null default 0,
  completed_at timestamptz,
  performed_by uuid not null default auth.uid(),
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.fraud_detection_feedback_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  review_queue_id uuid references public.payment_fraud_review_queue_deep(id) on delete set null,
  feedback_type text not null default 'accuracy' check (feedback_type in ('accuracy','false_positive','missed_issue','risk_adjustment','training_note','other')),
  feedback_status text not null default 'submitted' check (feedback_status in ('submitted','accepted','rejected','applied')),
  model_should_learn boolean not null default false,
  feedback_notes text not null default '',
  feedback_payload jsonb not null default '{}'::jsonb,
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.payment_protection_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  event_type text not null default 'activity',
  event_summary text not null default '',
  actor_user_id uuid not null default auth.uid(),
  related_record_type text not null default '',
  related_record_id uuid,
  event_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_dup_payment_scan_company on public.duplicate_payment_scan_runs_deep(company_id, scan_status);
create index if not exists idx_dup_payment_candidates_company on public.duplicate_payment_candidates_deep(company_id, candidate_status, risk_level);
create index if not exists idx_vendor_payment_risk_company on public.vendor_payment_risk_signals_deep(company_id, signal_status, risk_level);
create index if not exists idx_invoice_mismatch_company on public.invoice_mismatch_checks_deep(company_id, check_status);
create index if not exists idx_payment_fraud_review_company on public.payment_fraud_review_queue_deep(company_id, review_status, review_priority);
create index if not exists idx_fraud_resolution_company on public.fraud_resolution_actions_deep(company_id, action_status);
create index if not exists idx_fraud_feedback_company on public.fraud_detection_feedback_deep(company_id, feedback_status);
create index if not exists idx_payment_protection_events_company on public.payment_protection_activity_events_deep(company_id, created_at desc);

alter table public.duplicate_payment_scan_runs_deep enable row level security;
alter table public.duplicate_payment_candidates_deep enable row level security;
alter table public.vendor_payment_risk_signals_deep enable row level security;
alter table public.invoice_mismatch_checks_deep enable row level security;
alter table public.payment_fraud_review_queue_deep enable row level security;
alter table public.fraud_resolution_actions_deep enable row level security;
alter table public.fraud_detection_feedback_deep enable row level security;
alter table public.payment_protection_activity_events_deep enable row level security;

revoke all on public.duplicate_payment_scan_runs_deep from anon, authenticated;
revoke all on public.duplicate_payment_candidates_deep from anon, authenticated;
revoke all on public.vendor_payment_risk_signals_deep from anon, authenticated;
revoke all on public.invoice_mismatch_checks_deep from anon, authenticated;
revoke all on public.payment_fraud_review_queue_deep from anon, authenticated;
revoke all on public.fraud_resolution_actions_deep from anon, authenticated;
revoke all on public.fraud_detection_feedback_deep from anon, authenticated;
revoke all on public.payment_protection_activity_events_deep from anon, authenticated;

grant select, insert, update on public.duplicate_payment_scan_runs_deep to authenticated;
grant select, insert, update on public.duplicate_payment_candidates_deep to authenticated;
grant select, insert, update on public.vendor_payment_risk_signals_deep to authenticated;
grant select, insert, update on public.invoice_mismatch_checks_deep to authenticated;
grant select, insert, update on public.payment_fraud_review_queue_deep to authenticated;
grant select, insert, update on public.fraud_resolution_actions_deep to authenticated;
grant select, insert, update on public.fraud_detection_feedback_deep to authenticated;
grant select, insert, update on public.payment_protection_activity_events_deep to authenticated;

create policy duplicate_payment_scan_company_access_deep on public.duplicate_payment_scan_runs_deep for select using (private.company_access(company_id));
create policy duplicate_payment_scan_manager_write_deep on public.duplicate_payment_scan_runs_deep for insert with check (private.is_manager(company_id));
create policy duplicate_payment_scan_manager_update_deep on public.duplicate_payment_scan_runs_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy duplicate_payment_candidates_company_access_deep on public.duplicate_payment_candidates_deep for select using (private.company_access(company_id));
create policy duplicate_payment_candidates_manager_write_deep on public.duplicate_payment_candidates_deep for insert with check (private.is_manager(company_id));
create policy duplicate_payment_candidates_manager_update_deep on public.duplicate_payment_candidates_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy vendor_payment_risk_company_access_deep on public.vendor_payment_risk_signals_deep for select using (private.company_access(company_id));
create policy vendor_payment_risk_manager_write_deep on public.vendor_payment_risk_signals_deep for insert with check (private.is_manager(company_id));
create policy vendor_payment_risk_manager_update_deep on public.vendor_payment_risk_signals_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy invoice_mismatch_company_access_deep on public.invoice_mismatch_checks_deep for select using (private.company_access(company_id));
create policy invoice_mismatch_manager_write_deep on public.invoice_mismatch_checks_deep for insert with check (private.is_manager(company_id));
create policy invoice_mismatch_manager_update_deep on public.invoice_mismatch_checks_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy payment_fraud_review_company_access_deep on public.payment_fraud_review_queue_deep for select using (private.company_access(company_id));
create policy payment_fraud_review_manager_write_deep on public.payment_fraud_review_queue_deep for insert with check (private.is_manager(company_id));
create policy payment_fraud_review_manager_update_deep on public.payment_fraud_review_queue_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy fraud_resolution_company_access_deep on public.fraud_resolution_actions_deep for select using (private.company_access(company_id));
create policy fraud_resolution_manager_write_deep on public.fraud_resolution_actions_deep for insert with check (private.is_manager(company_id));
create policy fraud_resolution_manager_update_deep on public.fraud_resolution_actions_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy fraud_feedback_company_access_deep on public.fraud_detection_feedback_deep for select using (private.company_access(company_id));
create policy fraud_feedback_manager_write_deep on public.fraud_detection_feedback_deep for insert with check (private.is_manager(company_id));
create policy fraud_feedback_manager_update_deep on public.fraud_detection_feedback_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy payment_protection_events_company_access_deep on public.payment_protection_activity_events_deep for select using (private.company_access(company_id));
create policy payment_protection_events_company_insert_deep on public.payment_protection_activity_events_deep for insert with check (private.company_access(company_id));
create policy payment_protection_events_manager_update_deep on public.payment_protection_activity_events_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));
