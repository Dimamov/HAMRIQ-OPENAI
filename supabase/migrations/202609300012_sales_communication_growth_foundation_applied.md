# Applied manually to Supabase

This checkpoint records the sales, communication, and growth foundation that was applied to Supabase through the connected Supabase tool.

Live tables verified with RLS enabled:

- communication_templates
- customer_complaints
- customer_satisfaction_surveys
- direct_mail_campaigns
- lead_capture_forms
- lead_nurture_sequences
- lead_scoring_events
- phone_call_logs
- qr_codes
- referrals
- reputation_reviews
- storm_events
- territories

Also added fields to contacts/jobs for lead score, lead status, source detail, response timing, territory, loss reason, and competitor tracking.

The full SQL migration text was blocked by the GitHub write safety layer during this session, so this file is a checkpoint until the full SQL can be committed cleanly.