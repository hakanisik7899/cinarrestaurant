-- ============================================================================
-- Çınar Restaurant — Satış Raporu RPC'si
-- ============================================================================
-- Bu dosyayı Supabase Dashboard → SQL Editor'de bir kez çalıştırın.
-- panel.html'deki "Raporlar" sekmesi bu fonksiyonu kullanır.
--
-- Ön koşul: supabase/schema.sql zaten çalıştırılmış olmalı (siparisler,
-- siparis_kalemleri, menu_urunler, menu_kategoriler tabloları mevcut olmalı).
-- ============================================================================

-- Belirtilen tarih aralığında (iptal hariç) ürün bazında satılan adet ve ciro.
-- Ciro, sipariş anındaki (snapshot) birim_fiyat üzerinden hesaplanır; bu sayede
-- menü fiyatı sonradan değişse bile geçmiş rapor doğru kalır.
create or replace function satis_raporu(p_baslangic timestamptz, p_bitis timestamptz)
returns table (
  urun_id bigint,
  urun_ad text,
  kategori_ad text,
  toplam_adet bigint,
  toplam_tutar numeric
)
language sql
security definer
set search_path = public
stable
as $$
  select
    k.urun_id,
    coalesce(max(u.ad), max(k.urun_ad))     as urun_ad,
    coalesce(max(kat.ad), '(kategorisiz)')  as kategori_ad,
    sum(k.adet)::bigint                     as toplam_adet,
    sum(k.adet * k.birim_fiyat)             as toplam_tutar
  from siparis_kalemleri k
  join siparisler s              on s.id = k.siparis_id
  left join menu_urunler u       on u.id = k.urun_id
  left join menu_kategoriler kat on kat.id = u.kategori_id
  where s.durum <> 'iptal'
    and s.created_at >= p_baslangic
    and s.created_at <  p_bitis
  group by k.urun_id
  order by toplam_tutar desc;
$$;

-- Rapor gizlidir: yalnızca giriş yapmış personel (authenticated) çağırabilir.
-- anon (müşteri) key'i bu fonksiyonu çağıramaz.
revoke all on function satis_raporu(timestamptz, timestamptz) from public;
revoke all on function satis_raporu(timestamptz, timestamptz) from anon;
grant execute on function satis_raporu(timestamptz, timestamptz) to authenticated;

-- ============================================================================
-- Bitti. Sonraki adım: panel.html → Raporlar sekmesinden test edin.
-- ============================================================================
