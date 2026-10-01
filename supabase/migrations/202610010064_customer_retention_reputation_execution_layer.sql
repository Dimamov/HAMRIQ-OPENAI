create table if not exists public.customer_satisfaction_survey_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid null,
  contact_id uuid null,
  survey_type text not null default 'nps' check (survey_type in ('nps','csat','post_install','service_callback','complaint_recovery','referral')),
  delivery_channel text not null default 'sms' check (delivery_channel in ('sms','email','portal','phone','manual')),
  status text not null default 'draft' check (status in ('draft','scheduled','sent','responded','expired','cancelled')),
  scheduled_for timestamptz null,
  sent_at timestamptz null,
  responded_at timestamptz null,
  recipient_name text null,
  recipient_phone text null,
  recipient_email text null,
  survey_payload jsonb not null default '{}'::jsonb,
  response_payload jsonb not null default '{}'::jsonb,
  requires_manager_review boolean not null default false,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.customer_nps_score_records_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  survey_run_id uuid null references public.customer_satisfaction_survey_runs_deep(id) on delete set null,
  job_id uuid null,
  contact_id uuid null,
  score integer not null check (score between 0 and 10),
  category text generated always as (case when score >= 9 then 'promoter' when score >= 7 then 'passive' else 'detractor' end) stored,
  feedback_text text null,
  followup_status text not null default 'not_started' check (followup_status in ('not_started','assigned','in_progress','resolved','closed')),
  assigned_to uuid null,
  requires_manager_review boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.customer_complaint_cases_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid null,
  contact_id uuid null,
  source text not null default 'manual' check (source in ('manual','phone','sms','email','portal','review_site','social','hammy')),
  severity text not null default 'medium' check (severity in ('low','medium','high','critical')),
  status text not null default 'open' check (status in ('open','triage','assigned','waiting_customer','waiting_internal','resolved','closed')),
  complaint_summary text not null default '',
  customer_requested_resolution text null,
  assigned_to uuid null,
  due_at timestamptz null,
  resolved_at timestamptz null,
  resolution_summary text null,
  ai_summary jsonb not null default '{}'::jsonb,
  requires_manager_review boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.complaint_escalation_steps_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  complaint_case_id uuid not null references public.customer_complaint_cases_deep(id) on delete cascade,
  step_type text not null default 'manager_review' check (step_type in ('manager_review','customer_call','site_visit','production_review','refund_review','legal_review','closeout')),
  status text not null default 'pending' check (status in ('pending','in_progress','completed','cancelled')),
  assigned_to uuid null,
  due_at timestamptz null,
  completed_at timestamptz null,
  step_notes text not null default '',
  outcome_payload jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.reputation_monitoring_reviews_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid null,
  contact_id uuid null,
  review_site text not null default 'google' check (review_site in ('google','facebook','bbb','yelp','angi','other')),
  external_review_id text null,
  rating numeric(3,1) null check (rating is null or (rating >= 0 and rating <= 5)),
  review_text text null,
  reviewer_name text null,
  review_url text null,
  posted_at timestamptz null,
  response_status text not null default 'not_needed' check (response_status in ('not_needed','needs_response','drafted','approved','posted','archived')),
  response_draft text null,
  requires_manager_review boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.referral_reward_claims_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  referring_contact_id uuid null,
  referred_contact_id uuid null,
  referred_job_id uuid null,
  reward_status text not null default 'pending' check (reward_status in ('pending','qualified','approved','paid','denied','cancelled')),
  reward_type text not null default 'cash' check (reward_type in ('cash','gift_card','credit','custom')),
  reward_amount_cents bigint not null default 0,
  qualification_notes text not null default '',
  approved_by uuid null,
  approved_at timestamptz null,
  paid_at timestamptz null,
  requires_manager_review boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.past_customer_reactivation_tasks_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  contact_id uuid null,
  prior_job_id uuid null,
  assigned_to uuid null,
  campaign_name text not null default '',
  reason text not null default 'past_customer_followup' check (reason in ('past_customer_followup','warranty_check','storm_reinspection','maintenance_offer','referral_request','seasonal_checkin')),
  status text not null default 'open' check (status in ('open','contacted','scheduled','not_interested','converted','closed')),
  due_at timestamptz null,
  last_contacted_at timestamptz null,
  outcome_notes text not null default '',
  ai_recommended_next_action jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.retention_reputation_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid null,
  contact_id uuid null,
  event_type text not null default 'note',
  related_table text null,
  related_id uuid null,
  event_summary text not null default '',
  event_payload jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create index if not exists idx_cssr_company_status on public.customer_satisfaction_survey_runs_deep(company_id, status);
create index if not exists idx_nps_company_category on public.customer_nps_score_records_deep(company_id, category);
create index if not exists idx_complaints_company_status on public.customer_complaint_cases_deep(company_id, status);
create index if not exists idx_complaint_steps_case on public.complaint_escalation_steps_deep(complaint_case_id, status);
create index if not exists idx_rep_reviews_company_status on public.reputation_monitoring_reviews_deep(company_id, response_status);
create index if not exists idx_referral_claims_company_status on public.referral_reward_claims_deep(company_id, reward_status);
create index if not exists idx_reactivation_company_status on public.past_customer_reactivation_tasks_deep(company_id, status);
create index if not exists idx_retention_events_company on public.retention_reputation_activity_events_deep(company_id, created_at desc);

alter table public.customer_satisfaction_survey_runs_deep enable row level security;
alter table public.customer_nps_score_records_deep enable row level security;
alter table public.customer_complaint_cases_deep enable row level security;
alter table public.complaint_escalation_steps_deep enable row level security;
alter table public.reputation_monitoring_reviews_deep enable row level security;
alter table public.referral_reward_claims_deep enable row level security;
alter table public.past_customer_reactivation_tasks_deep enable row level security;
alter table public.retention_reputation_activity_events_deep enable row level security;

revoke all on public.customer_satisfaction_survey_runs_deep from anon, authenticated;
revoke all on public.customer_nps_score_records_deep from anon, authenticated;
revoke all on public.customer_complaint_cases_deep from anon, authenticated;
revoke all on public.complaint_escalation_steps_deep from anon, authenticated;
revoke all on public.reputation_monitoring_reviews_deep from anon, authenticated;
revoke all on public.referral_reward_claims_deep from anon, authenticated;
revoke all on public.past_customer_reactivation_tasks_deep from anon, authenticated;
revoke all on public.retention_reputation_activity_events_deep from anon, authenticated;

grant select, insert, update on public.customer_satisfaction_survey_runs_deep to authenticated;
grant select, insert, update on public.customer_nps_score_records_deep to authenticated;
grant select, insert, update on public.customer_complaint_cases_deep to authenticated;
grant select, insert, update on public.complaint_escalation_steps_deep to authenticated;
grant select, insert, update on public.reputation_monitoring_reviews_deep to authenticated;
grant select, insert, update on public.referral_reward_claims_deep to authenticated;
grant select, insert, update on public.past_customer_reactivation_tasks_deep to authenticated;
grant select, insert, update on public.retention_reputation_activity_events_deep to authenticated;

create policy cssr_company_access on public.customer_satisfaction_survey_runs_deep for select using (private.company_access(company_id));
create policy cssr_company_insert on public.customer_satisfaction_survey_runs_deep for insert with check (private.company_access(company_id));
create policy cssr_manager_update on public.customer_satisfaction_survey_runs_deep for update using (private.is_manager(company_id) or created_by = auth.uid() or private.can_job(company_id, job_id)) with check (private.company_access(company_id));

create policy nps_company_access on public.customer_nps_score_records_deep for select using (private.company_access(company_id));
create policy nps_company_insert on public.customer_nps_score_records_deep for insert with check (private.company_access(company_id));
create policy nps_manager_update on public.customer_nps_score_records_deep for update using (private.is_manager(company_id) or assigned_to = auth.uid()) with check (private.company_access(company_id));

create policy complaint_company_access on public.customer_complaint_cases_deep for select using (private.company_access(company_id));
create policy complaint_company_insert on public.customer_complaint_cases_deep for insert with check (private.company_access(company_id));
create policy complaint_manager_assigned_update on public.customer_complaint_cases_deep for update using (private.is_manager(company_id) or assigned_to = auth.uid()) with check (private.company_access(company_id));

create policy complaint_steps_company_access on public.complaint_escalation_steps_deep for select using (private.company_access(company_id));
create policy complaint_steps_company_insert on public.complaint_escalation_steps_deep for insert with check (private.company_access(company_id));
create policy complaint_steps_manager_assigned_update on public.complaint_escalation_steps_deep for update using (private.is_manager(company_id) or assigned_to = auth.uid()) with check (private.company_access(company_id));

create policy reputation_company_access on public.reputation_monitoring_reviews_deep for select using (private.company_access(company_id));
create policy reputation_manager_insert on public.reputation_monitoring_reviews_deep for insert with check (private.is_manager(company_id));
create policy reputation_manager_update on public.reputation_monitoring_reviews_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy referral_company_access on public.referral_reward_claims_deep for select using (private.company_access(company_id));
create policy referral_company_insert on public.referral_reward_claims_deep for insert with check (private.company_access(company_id));
create policy referral_manager_update on public.referral_reward_claims_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));

create policy reactivation_company_access on public.past_customer_reactivation_tasks_deep for select using (private.company_access(company_id));
create policy reactivation_company_insert on public.past_customer_reactivation_tasks_deep for insert with check (private.company_access(company_id));
create policy reactivation_assigned_update on public.past_customer_reactivation_tasks_deep for update using (private.is_manager(company_id) or assigned_to = auth.uid()) with check (private.company_access(company_id));

create policy retention_events_company_access on public.retention_reputation_activity_events_deep for select using (private.company_access(company_id));
create policy retention_events_company_insert on public.retention_reputation_activity_events_deep for insert with check (private.company_access(company_id));
create policy retention_events_manager_update on public.retention_reputation_activity_events_deep for update using (private.is_manager(company_id)) with check (private.is_manager(company_id));
