// Ortak Supabase istemcisi — masa.html, panel.html ve mutfak.html tarafından
// <script type="module"> ile import edilir.
//
// Burada yalnızca ANON (public) key bulunur. Bu key, RLS politikalarıyla
// (bkz. supabase/schema.sql) güvenli hale getirilmiştir — anon key'in
// frontend'de/git'te görünmesi normaldir. service_role anahtarı ASLA
// buraya veya herhangi bir dosyaya eklenmemelidir.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = 'https://yhhgktlnkdrofbyirkfs.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InloaGdrdGxua2Ryb2ZieWlya2ZzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ4MjAxMzEsImV4cCI6MjEwMDM5NjEzMX0.hXpoUWzdiZt4yLEb6q18jcI0wlgy1quRSLgJ4_UJZNk';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
