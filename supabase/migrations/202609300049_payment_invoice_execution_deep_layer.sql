-- HAMRIQ payment / invoice execution layer
-- Adds invoice sending, payment links, attempts, AR reminders, collection promises,
-- refunds, finance approval holds, and write-off review records.

create table if not exists public.invoice_send_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  invoice_id uuid,
  recipient_contact_id uuid,
  send_channel text not null default 'email' check (send_channel in ('email','sms','portal','print','other')),
  status text not null default 'draft' check (status in ('draft','queued','sent','delivered','failed','cancelled')),
  amount_cents bigint not null default 0,
  due_at timestamptz,
  sent_at timestamptz,
  delivered_at timestamptz,
  failure_reason text,
  metadata jsonb not null default '{}',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.payment_links_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  invoice_send_run_id uuid references public.invoice_send_runs_deep(id) on delete set null,
  provider text not null default 'manual',
  provider_reference text,
  link_status text not null default 'active' check (link_status in ('active','paid','expired','cancelled','failed')),
  amount_cents bigint not null default 0,
  expires_at timestamptz,
  paid_at timestamptz,
  public_token_hash text,
  metadata jsonb not null default '{}',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.payment_attempts_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  payment_link_id uuid references public.payment_links_deep(id) on delete set null,
  provider text not null default 'manual',
  provider_reference text,
  attempt_status text not null default 'started' check (attempt_status in ('started','authorized','captured','failed','cancelled','refunded','disputed')),
  amount_cents bigint not null default 0,
  fee_cents bigint not null default 0,
  failure_code text,
  failure_message text,
  attempted_at timestamptz not null default now(),
  metadata jsonb not null default '{}',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.ar_reminder_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  invoice_id uuid,
  reminder_stage text not null default 'friendly' check (reminder_stage in ('friendly','due_today','overdue','final_notice','collections_review')),
  channel text not null default 'email' check (channel in ('email','sms','phone','portal','mail','other')),
  status text not null default 'queued' check (status in ('queued','sent','delivered','failed','cancelled','responded')),
  balance_cents bigint not null default 0,
  scheduled_at timestamptz,
  sent_at timestamptz,
  response_summary text,
  metadata jsonb not null default '{}',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.collection_promise_records_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  contact_id uuid,
  promised_amount_cents bigint not null default 0,
  promised_date date,
  status text not null default 'open' check (status in ('open','kept','missed','renegotiated','cancelled')),
  notes text,
  next_followup_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.refund_records_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  payment_attempt_id uuid references public.payment_attempts_deep(id) on delete set null,
  refund_status text not null default 'requested' check (refund_status in ('requested','approved','submitted','processed','denied','cancelled')),
  amount_cents bigint not null default 0,
  reason text,
  requested_by uuid not null default auth.uid(),
  approved_by uuid,
  approved_at timestamptz,
  processed_at timestamptz,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.finance_approval_holds_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  hold_type text not null default 'payment_review' check (hold_type in ('payment_review','refund_review','pricing_exception','writeoff_review','commission_hold','other')),
  status text not null default 'open' check (status in ('open','approved','denied','released','cancelled')),
  amount_cents bigint not null default 0,
  reason text,
  manager_notes text,
  resolved_by uuid,
  resolved_at timestamptz,
  metadata jsonb not null default '{}',
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.writeoff_review_records_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  invoice_id uuid,
  requested_amount_cents bigint not null default 0,
  approved_amount_cents bigint not null default 0,
  reason text,
  status text not null default 'requested' check (status in ('requested','approved','denied','posted','cancelled')),
  requested_by uuid not null default auth.uid(),
  approved_by uuid,
  approved_at timestamptz,
  posted_at timestamptz,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists invoice_send_runs_deep_company_job_idx on public.invoice_send_runs_deep(company_id, job_id);
create index if not exists payment_links_deep_company_job_idx on public.payment_links_deep(company_id, job_id);
create index if not exists payment_attempts_deep_company_job_idx on public.payment_attempts_deep(company_id, job_id);
create index if not exists ar_reminder_runs_deep_company_job_idx on public.ar_reminder_runs_deep(company_id, job_id);
create index if not exists collection_promise_records_deep_company_job_idx on public.collection_promise_records_deep(company_id, job_id);
create index if not exists refund_records_deep_company_job_idx on public.refund_records_deep(company_id, job_id);
create index if not exists finance_approval_holds_deep_company_job_idx on public.finance_approval_holds_deep(company_id, job_id);
create index if not exists writeoff_review_records_deep_company_job_idx on public.writeoff_review_records_deep(company_id, job_id);

alter table public.invoice_send_runs_deep enable row level security;
alter table public.payment_links_deep enable row level security;
alter table public.payment_attempts_deep enable row level security;
alter table public.ar_reminder_runs_deep enable row level security;
alter table public.collection_promise_records_deep enable row level security;
alter table public.refund_records_deep enable row level security;
alter table public.finance_approval_holds_deep enable row level security;
alter table public.writeoff_review_records_deep enable row level security;

revoke all on public.invoice_send_runs_deep from anon, authenticated;
revoke all on public.payment_links_deep from anon, authenticated;
revoke all on public.payment_attempts_deep from anon, authenticated;
revoke all on public.ar_reminder_runs_deep from anon, authenticated;
revoke all on public.collection_promise_records_deep from anon, authenticated;
revoke all on public.refund_records_deep from anon, authenticated;
revoke all on public.finance_approval_holds_deep from anon, authenticated;
revoke all on public.writeoff_review_records_deep from anon, authenticated;

grant select, insert, update on public.invoice_send_runs_deep to authenticated;
grant select, insert, update on public.payment_links_deep to authenticated;
grant select, insert, update on public.payment_attempts_deep to authenticated;
grant select, insert, update on public.ar_reminder_runs_deep to authenticated;
grant select, insert, update on public.collection_promise_records_deep to authenticated;
grant select, insert, update on public.refund_records_deep to authenticated;
grant select, insert, update on public.finance_approval_holds_deep to authenticated;
grant select, insert, update on public.writeoff_review_records_deep to authenticated;

create policy invoice_send_runs_deep_select on public.invoice_send_runs_deep for select using (private.company_access(company_id) or (job_id is not null and private.can_job(company_id, job_id)));
create policy invoice_send_runs_deep_insert on public.invoice_send_runs_deep for insert with check (private.is_manager(company_id) or (job_id is not null and private.can_job(company_id, job_id)));
create policy invoice_send_runs_deep_update on public.invoice_send_runs_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy payment_links_deep_select on public.payment_links_deep for select using (private.company_access(company_id) or (job_id is not null and private.can_job(company_id, job_id)));
create policy payment_links_deep_insert on public.payment_links_deep for insert with check (private.is_manager(company_id));
create policy payment_links_deep_update on public.payment_links_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy payment_attempts_deep_select on public.payment_attempts_deep for select using (private.company_access(company_id) or (job_id is not null and private.can_job(company_id, job_id)));
create policy payment_attempts_deep_insert on public.payment_attempts_deep for insert with check (private.is_manager(company_id));
create policy payment_attempts_deep_update on public.payment_attempts_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy ar_reminder_runs_deep_select on public.ar_reminder_runs_deep for select using (private.company_access(company_id) or (job_id is not null and private.can_job(company_id, job_id)));
create policy ar_reminder_runs_deep_insert on public.ar_reminder_runs_deep for insert with check (private.is_manager(company_id));
create policy ar_reminder_runs_deep_update on public.ar_reminder_runs_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy collection_promise_records_deep_select on public.collection_promise_records_deep for select using (private.company_access(company_id) or (job_id is not null and private.can_job(company_id, job_id)));
create policy collection_promise_records_deep_insert on public.collection_promise_records_deep for insert with check (private.is_manager(company_id) or (job_id is not null and private.can_job(company_id, job_id)));
create policy collection_promise_records_deep_update on public.collection_promise_records_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy refund_records_deep_select on public.refund_records_deep for select using (private.company_access(company_id) or (job_id is not null and private.can_job(company_id, job_id)));
create policy refund_records_deep_insert on public.refund_records_deep for insert with check (private.is_manager(company_id));
create policy refund_records_deep_update on public.refund_records_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy finance_approval_holds_deep_select on public.finance_approval_holds_deep for select using (private.company_access(company_id));
create policy finance_approval_holds_deep_insert on public.finance_approval_holds_deep for insert with check (private.is_manager(company_id));
create policy finance_approval_holds_deep_update on public.finance_approval_holds_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy writeoff_review_records_deep_select on public.writeoff_review_records_deep for select using (private.company_access(company_id));
create policy writeoff_review_records_deep_insert on public.writeoff_review_records_deep for insert with check (private.is_manager(company_id));
create policy writeoff_review_records_deep_update on public.writeoff_review_records_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));
