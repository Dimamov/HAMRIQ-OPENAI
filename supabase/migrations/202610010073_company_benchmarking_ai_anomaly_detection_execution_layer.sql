-- HAMRIQ company benchmarking + AI anomaly detection execution layer
-- Adds benchmark snapshots, peer buckets, anomaly signals, manager review, exclusions, feedback, gaps, and audit events.

create table if not exists public.company_benchmark_snapshots_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  snapshot_name text not null default 'Benchmark Snapshot',
  benchmark_period_start date,
  benchmark_period_end date,
  benchmark_category text not null default 'overall' check (benchmark_category in ('overall','sales','production','finance','marketing','service','commercial','operations')),
  metric_payload jsonb not null default '{}'::jsonb,
  comparison_summary text not null default '',
  requires_manager_review boolean not null default true,
  is_active boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.benchmark_peer_buckets_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  bucket_name text not null,
  bucket_type text not null default 'company_size' check (bucket_type in ('company_size','market','roofing_type','revenue_band','job_volume','custom')),
  anonymized_population_count integer not null default 0,
  inclusion_rules jsonb not null default '{}'::jsonb,
  exclusion_rules jsonb not null default '{}'::jsonb,
  is_visible_to_managers boolean not null default true,
  is_active boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ai_anomaly_signal_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  job_id uuid,
  signal_type text not null default 'general' check (signal_type in ('pricing','margin','production','payment','duplicate','lead','commission','expense','general')),
  severity text not null default 'medium' check (severity in ('low','medium','high','critical')),
  signal_title text not null,
  signal_summary text not null default '',
  evidence_payload jsonb not null default '{}'::jsonb,
  recommended_action text not null default '',
  status text not null default 'review_needed' check (status in ('review_needed','dismissed','accepted','resolved','false_positive')),
  requires_manager_review boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.anomaly_manager_review_queue_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  anomaly_signal_id uuid references public.ai_anomaly_signal_runs_deep(id) on delete cascade,
  assigned_manager_id uuid,
  review_status text not null default 'open' check (review_status in ('open','in_review','approved','dismissed','escalated','closed')),
  manager_notes text not null default '',
  reviewed_at timestamptz,
  due_at timestamptz,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.benchmark_exclusion_rules_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  rule_name text not null,
  rule_reason text not null default '',
  excluded_metric_key text,
  excluded_job_id uuid,
  exclusion_payload jsonb not null default '{}'::jsonb,
  approved_by uuid,
  approved_at timestamptz,
  is_active boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.anomaly_detection_feedback_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  anomaly_signal_id uuid references public.ai_anomaly_signal_runs_deep(id) on delete cascade,
  feedback_type text not null default 'manager_feedback' check (feedback_type in ('manager_feedback','false_positive','confirmed_issue','training_note','threshold_adjustment')),
  feedback_notes text not null default '',
  should_train_model boolean not null default false,
  requires_manager_review boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.benchmark_goal_gap_records_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  snapshot_id uuid references public.company_benchmark_snapshots_deep(id) on delete cascade,
  metric_key text not null,
  current_value numeric,
  benchmark_value numeric,
  target_value numeric,
  gap_direction text not null default 'unknown' check (gap_direction in ('ahead','behind','on_track','unknown')),
  gap_summary text not null default '',
  action_plan text not null default '',
  requires_manager_review boolean not null default true,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.benchmark_anomaly_activity_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  related_record_type text not null default 'benchmark',
  related_record_id uuid,
  event_type text not null,
  event_summary text not null default '',
  event_payload jsonb not null default '{}'::jsonb,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

alter table public.company_benchmark_snapshots_deep enable row level security;
alter table public.benchmark_peer_buckets_deep enable row level security;
alter table public.ai_anomaly_signal_runs_deep enable row level security;
alter table public.anomaly_manager_review_queue_deep enable row level security;
alter table public.benchmark_exclusion_rules_deep enable row level security;
alter table public.anomaly_detection_feedback_deep enable row level security;
alter table public.benchmark_goal_gap_records_deep enable row level security;
alter table public.benchmark_anomaly_activity_events_deep enable row level security;

-- See production DB migration for complete policy/index definitions applied live.
