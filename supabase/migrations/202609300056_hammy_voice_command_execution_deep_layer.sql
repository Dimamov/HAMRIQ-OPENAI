-- HAMRIQ migration: Hammy voice command execution deep layer
-- Adds push-to-talk sessions, transcripts, command parsing, reviewed tool calls,
-- missing-lead creation events, voice preferences, photo-analysis handoffs, and action confirmations.

create table if not exists public.hammy_voice_sessions_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null default auth.uid(),
  job_id uuid null,
  contact_id uuid null,
  source text not null default 'push_to_talk',
  status text not null default 'started' check (status in ('started','processing','completed','failed','cancelled')),
  started_at timestamptz not null default now(),
  ended_at timestamptz null,
  device_context jsonb not null default '{}'::jsonb,
  session_metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  created_by uuid not null default auth.uid()
);

create table if not exists public.hammy_transcript_entries_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  voice_session_id uuid not null references public.hammy_voice_sessions_deep(id) on delete cascade,
  job_id uuid null,
  speaker text not null default 'user' check (speaker in ('user','hammy','system')),
  transcript_text text not null default '',
  transcript_confidence numeric(5,4) null,
  audio_asset_path text null,
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  created_by uuid not null default auth.uid()
);

create table if not exists public.hammy_command_parse_runs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  voice_session_id uuid not null references public.hammy_voice_sessions_deep(id) on delete cascade,
  job_id uuid null,
  raw_command text not null default '',
  detected_intent text not null default 'unknown',
  parsed_entities jsonb not null default '{}'::jsonb,
  confidence numeric(5,4) null,
  status text not null default 'needs_review' check (status in ('needs_review','approved','executed','failed','ignored')),
  human_review_required boolean not null default true,
  reviewed_by uuid null,
  reviewed_at timestamptz null,
  created_at timestamptz not null default now(),
  created_by uuid not null default auth.uid()
);

create table if not exists public.hammy_tool_call_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  voice_session_id uuid null references public.hammy_voice_sessions_deep(id) on delete set null,
  command_parse_run_id uuid null references public.hammy_command_parse_runs_deep(id) on delete set null,
  job_id uuid null,
  tool_name text not null,
  tool_action text not null default '',
  request_payload jsonb not null default '{}'::jsonb,
  response_payload jsonb not null default '{}'::jsonb,
  status text not null default 'queued' check (status in ('queued','running','succeeded','failed','blocked','needs_review')),
  human_review_required boolean not null default true,
  error_message text null,
  created_at timestamptz not null default now(),
  created_by uuid not null default auth.uid()
);

create table if not exists public.hammy_missing_lead_creation_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  voice_session_id uuid null references public.hammy_voice_sessions_deep(id) on delete set null,
  command_parse_run_id uuid null references public.hammy_command_parse_runs_deep(id) on delete set null,
  detected_name text not null default '',
  detected_phone text null,
  detected_email text null,
  detected_address text null,
  detected_need text null,
  matched_contact_id uuid null,
  created_contact_id uuid null,
  created_job_id uuid null,
  status text not null default 'needs_review' check (status in ('needs_review','matched_existing','created','rejected','failed')),
  manager_review_required boolean not null default true,
  reviewed_by uuid null,
  reviewed_at timestamptz null,
  notes text not null default '',
  created_at timestamptz not null default now(),
  created_by uuid not null default auth.uid()
);

create table if not exists public.hammy_voice_preferences_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null default auth.uid(),
  preferred_voice text not null default 'standard',
  voice_quality_tier text not null default 'standard' check (voice_quality_tier in ('standard','premium','disabled')),
  push_to_talk_enabled boolean not null default true,
  spoken_responses_enabled boolean not null default true,
  auto_read_summaries boolean not null default false,
  settings jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  created_by uuid not null default auth.uid(),
  unique(company_id, user_id)
);

create table if not exists public.hammy_photo_analysis_handoffs_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  voice_session_id uuid null references public.hammy_voice_sessions_deep(id) on delete set null,
  job_id uuid null,
  photo_upload_batch_id uuid null,
  photo_analysis_request_id uuid null,
  requested_analysis_type text not null default 'hail_damage',
  status text not null default 'queued' check (status in ('queued','analyzing','needs_review','reviewed','failed')),
  summary text not null default '',
  findings jsonb not null default '[]'::jsonb,
  human_review_required boolean not null default true,
  reviewed_by uuid null,
  reviewed_at timestamptz null,
  created_at timestamptz not null default now(),
  created_by uuid not null default auth.uid()
);

create table if not exists public.hammy_action_confirmation_events_deep (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  voice_session_id uuid null references public.hammy_voice_sessions_deep(id) on delete set null,
  command_parse_run_id uuid null references public.hammy_command_parse_runs_deep(id) on delete set null,
  job_id uuid null,
  action_label text not null default '',
  confirmation_status text not null default 'pending' check (confirmation_status in ('pending','confirmed','denied','expired','cancelled')),
  confirmed_by uuid null,
  confirmed_at timestamptz null,
  expires_at timestamptz null,
  risk_level text not null default 'medium' check (risk_level in ('low','medium','high')),
  confirmation_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  created_by uuid not null default auth.uid()
);

-- Indexes, grants, and RLS policies are applied in the live Supabase project.
-- Live security model: managers can review/control company AI actions; users can manage their own voice sessions/preferences;
-- job-scoped users can access job-related Hammy records; AI actions default to human review.