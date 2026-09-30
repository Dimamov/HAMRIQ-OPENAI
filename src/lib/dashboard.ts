import { JOB_STAGES, type Dashboard } from './types';

function count(value: unknown): number {
  if (typeof value !== 'number' || !Number.isSafeInteger(value) || value < 0) {
    throw new Error('The dashboard returned an invalid count. Please try again.');
  }
  return value;
}

export function parseDashboard(value: unknown): Dashboard {
  if (!value || typeof value !== 'object') throw new Error('The dashboard could not be loaded.');
  const row = value as Record<string, unknown>;
  if (typeof row.local_date !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(row.local_date)) {
    throw new Error('The dashboard returned an invalid date.');
  }
  if (!row.stage_counts || typeof row.stage_counts !== 'object') throw new Error('Job stages could not be loaded.');
  const stages = row.stage_counts as Record<string, unknown>;
  const counts = Object.fromEntries(JOB_STAGES.map(stage => [stage, count(stages[stage])])) as Dashboard['stage_counts'];
  const result: Dashboard = {
    active_jobs: count(row.active_jobs), total_jobs: count(row.total_jobs),
    completed_jobs: count(row.completed_jobs), photos_this_week: count(row.photos_this_week),
    pending_estimates: count(row.pending_estimates), follow_ups_today: count(row.follow_ups_today),
    latest_photo_path: typeof row.latest_photo_path === 'string' ? row.latest_photo_path : null,
    local_date: row.local_date, stage_counts: counts,
  };
  if (result.active_jobs + result.completed_jobs !== result.total_jobs || Object.values(counts).reduce((a,b) => a+b, 0) !== result.total_jobs) {
    throw new Error('Job totals could not be verified. Please refresh.');
  }
  return result;
}

export function dateLabel(localDate: string): string {
  // Treat a database local calendar date as a calendar date, not a UTC midnight
  // that would display the previous day on a Michigan phone.
  return new Intl.DateTimeFormat('en-US', { weekday: 'short', month: 'short', day: 'numeric', timeZone: 'UTC' })
    .format(new Date(`${localDate}T12:00:00Z`));
}

export function progress(dashboard: Dashboard): number {
  return dashboard.total_jobs ? Math.round(dashboard.completed_jobs / dashboard.total_jobs * 100) : 0;
}
