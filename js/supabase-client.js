// Ortak Supabase istemcisi — masa.html, panel.html, mutfak.html ve
// index.html tarafından kullanılır.
//
// Bu dosyadan ÖNCE UMD kütüphanesi yüklenmiş olmalı:
//   <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.js"></script>
// O script, global `supabase` adını kütüphanenin namespace'i olarak tanımlar
// (içinde createClient vb. bulunur). Burada aynı global ismi GERÇEK
// istemci örneğiyle değiştiriyoruz ki diğer sayfalardaki `supabase.from(...)`,
// `supabase.auth...`, `supabase.rpc(...)` çağrıları herhangi bir import
// gerekmeden, olduğu gibi çalışsın.
//
// Burada yalnızca ANON (public) key bulunur. Bu key, RLS politikalarıyla
// (bkz. supabase/schema.sql) güvenli hale getirilmiştir — anon key'in
// frontend'de/git'te görünmesi normaldir. service_role anahtarı ASLA
// buraya veya herhangi bir dosyaya eklenmemelidir.
(function () {
  var SUPABASE_URL = 'https://yhhgktlnkdrofbyirkfs.supabase.co';
  var SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InloaGdrdGxua2Ryb2ZieWlya2ZzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ4MjAxMzEsImV4cCI6MjEwMDM5NjEzMX0.hXpoUWzdiZt4yLEb6q18jcI0wlgy1quRSLgJ4_UJZNk';

  if (!window.supabase || typeof window.supabase.createClient !== 'function') {
    console.error('Supabase kütüphanesi yüklenemedi (CDN erişim sorunu olabilir).');
    window.cinarSupabaseYuklenemedi = true;
    return;
  }

  window.supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
})();
