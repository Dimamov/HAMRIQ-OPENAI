import { createClient } from '@supabase/supabase-js';
import config from './config.json';

const url = import.meta.env.VITE_SUPABASE_URL?.trim() || config.supabaseUrl;
const key = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY?.trim() || config.supabasePublishableKey;
const configured = !!url && !!key && /^https:\/\//.test(url) && !url.includes('your-project') && !key.includes('your-publishable-key');

// Only public configuration belongs here. AI and service-role credentials must
// live in Supabase Edge Function secrets, never in VITE_ environment variables.
export const supabase = configured ? createClient(url!, key!, {
  auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: false },
}) : null;
