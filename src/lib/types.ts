export const JOB_STAGES = ['Lead', 'Measured', 'Estimated', 'Contract sent', 'Signed', 'Complete'] as const;
export type JobStage = typeof JOB_STAGES[number];
export type Role = 'owner' | 'manager' | 'rep';
export type Tab = 'Home' | 'Jobs' | 'Contacts' | 'Reports';

export interface Profile {
  id: string;
  company_id: string;
  display_name: string;
  role: Role;
  active: boolean;
}

export interface Company {
  id: string;
  name: string;
  timezone: string;
}

export interface Dashboard {
  active_jobs: number;
  total_jobs: number;
  completed_jobs: number;
  photos_this_week: number;
  pending_estimates: number;
  follow_ups_today: number;
  latest_photo_path: string | null;
  local_date: string;
  stage_counts: Record<JobStage, number>;
}
