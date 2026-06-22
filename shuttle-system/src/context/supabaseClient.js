import { createClient } from '@supabase/supabase-js';

// Grab the hidden credentials from your environment file
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

// Export the single initialized connection client instance
export const supabase = createClient(supabaseUrl, supabaseAnonKey);