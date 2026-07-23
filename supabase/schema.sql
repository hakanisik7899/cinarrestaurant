-- ============================================================================
-- Çınar Restaurant — QR Menü & Canlı Sipariş Sistemi — Supabase Şeması
-- ============================================================================
-- Bu dosyayı Supabase Dashboard → SQL Editor'de baştan sona tek seferde
-- çalıştırın. Tüm tablolar, RLS politikaları, sipariş RPC'si ve başlangıç
-- (seed) verisi bu dosyada.
--
-- ÖNEMLİ: Seed verideki fiyatlar 0 (placeholder) olarak eklenir. Canlıya
-- almadan önce panel.html → Menü Yönetimi'nden gerçek fiyatları girin.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. TABLOLAR
-- ----------------------------------------------------------------------------

create table if not exists masalar (
  id          bigint generated always as identity primary key,
  masa_no     text not null unique,
  qr_token    uuid not null default gen_random_uuid() unique,
  aktif       boolean not null default true,
  created_at  timestamptz not null default now()
);

create table if not exists menu_kategoriler (
  id          bigint generated always as identity primary key,
  ad          text not null unique,
  sira        int not null default 0,
  aktif       boolean not null default true,
  created_at  timestamptz not null default now()
);

create table if not exists menu_urunler (
  id          bigint generated always as identity primary key,
  kategori_id bigint not null references menu_kategoriler(id) on delete cascade,
  ad          text not null,
  aciklama    text not null default '',
  fiyat       numeric(10,2) not null default 0 check (fiyat >= 0),
  gorsel_url  text not null default '',
  rozet       text not null default '',
  one_cikan   boolean not null default false,
  stokta      boolean not null default true,
  sira        int not null default 0,
  created_at  timestamptz not null default now(),
  unique (kategori_id, ad)
);

create table if not exists siparisler (
  id             uuid primary key default gen_random_uuid(),
  masa_id        bigint not null references masalar(id),
  durum          text not null default 'beklemede'
                 check (durum in ('beklemede','onaylandi','hazirlaniyor','hazir','teslim','iptal')),
  toplam_tutar   numeric(10,2) not null default 0,
  musteri_not    text not null default '',
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create table if not exists siparis_kalemleri (
  id            bigint generated always as identity primary key,
  siparis_id    uuid not null references siparisler(id) on delete cascade,
  urun_id       bigint not null references menu_urunler(id),
  urun_ad       text not null,       -- sipariş anındaki ürün adı (snapshot)
  adet          int not null check (adet > 0),
  birim_fiyat   numeric(10,2) not null,  -- sipariş anındaki fiyat (snapshot)
  kalem_not     text not null default ''
);

-- updated_at otomatik güncellensin
create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_siparisler_updated_at on siparisler;
create trigger trg_siparisler_updated_at
  before update on siparisler
  for each row execute function set_updated_at();

-- ----------------------------------------------------------------------------
-- 2. ROW LEVEL SECURITY
-- ----------------------------------------------------------------------------

alter table masalar            enable row level security;
alter table menu_kategoriler   enable row level security;
alter table menu_urunler       enable row level security;
alter table siparisler         enable row level security;
alter table siparis_kalemleri  enable row level security;

-- --- Menü: herkes (anon dahil) aktif/stoktaki ürünleri okuyabilir ----------
create policy "menu_kategoriler_public_select"
  on menu_kategoriler for select
  to anon, authenticated
  using (aktif = true);

create policy "menu_urunler_public_select"
  on menu_urunler for select
  to anon, authenticated
  using (stokta = true);

-- --- Menü: sadece personel (authenticated) yönetebilir ---------------------
create policy "menu_kategoriler_staff_all"
  on menu_kategoriler for all
  to authenticated
  using (true) with check (true);

create policy "menu_urunler_staff_all"
  on menu_urunler for all
  to authenticated
  using (true) with check (true);

-- --- Masalar: anon için SELECT policy YOK (bilerek). ------------------------
-- "aktif=true" gibi bir policy anon'a `select * from masalar` ile TÜM
-- masaların qr_token'ını tek seferde ifşa eder — bu, fiziksel QR taramadan
-- geçerli sipariş üretmeyi mümkün kılar. Bunun yerine anon, elindeki (QR'dan
-- okuttuğu) TEK token'ı aşağıdaki masa_dogrula RPC'siyle doğrular.
create policy "masalar_staff_all"
  on masalar for all
  to authenticated
  using (true) with check (true);

-- --- Siparişler: anon için SELECT policy YOK (bilerek). --------------------
-- RLS row-level çalışır: "using(true)" gibi bir policy anon'a TÜM
-- siparişleri toplu listeleme izni verir (id bilmese bile `select * from
-- siparisler` çeker) — bu istenmiyor. Bunun yerine müşteri kendi siparişini
-- yalnızca aşağıdaki SECURITY DEFINER RPC'ler ile, elindeki tek bir sipariş
-- uuid'siyle (siparis_olustur'un döndürdüğü) sorgulayabilir. Personel ise
-- authenticated policy'siyle tabloyu doğrudan görür.

create policy "siparisler_staff_select"
  on siparisler for select
  to authenticated
  using (true);

create policy "siparisler_staff_update"
  on siparisler for update
  to authenticated
  using (true) with check (true);

create policy "siparis_kalemleri_staff_select"
  on siparis_kalemleri for select
  to authenticated
  using (true);

-- Not: anon için siparisler/siparis_kalemleri tablolarına doğrudan
-- INSERT/SELECT politikası YOK — ekleme ve müşteri tarafı okuma sadece
-- aşağıdaki SECURITY DEFINER RPC'ler ile yapılır. Bu sayede hem fiyatlar
-- sunucu tarafında menu_urunler'den okunur (client fiyatına güvenilmez),
-- hem de bir müşteri başka bir masanın siparişini toplu listeleyemez.

-- ----------------------------------------------------------------------------
-- 3. RPC'LER
-- ----------------------------------------------------------------------------

-- --- Masa token doğrulama: anon yalnızca ELİNDEKİ tek token'ı sorgular -----
create or replace function masa_dogrula(p_qr_token uuid)
returns table (id bigint, masa_no text)
language sql
security definer
set search_path = public
stable
as $$
  select m.id, m.masa_no
  from masalar m
  where m.qr_token = p_qr_token and m.aktif = true;
$$;

revoke all on function masa_dogrula(uuid) from public;
grant execute on function masa_dogrula(uuid) to anon, authenticated;

-- --- Sipariş oluşturma (fiyat bütünlüğü burada garanti edilir) -------------
create or replace function siparis_olustur(
  p_qr_token uuid,
  p_kalemler jsonb,   -- [{ "urun_id": 1, "adet": 2, "kalem_not": "acısız" }, ...]
  p_musteri_not text default ''
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_masa_id     bigint;
  v_siparis_id  uuid;
  v_toplam      numeric(10,2) := 0;
  v_kalem       jsonb;
  v_urun        menu_urunler%rowtype;
  v_adet        int;
begin
  -- Masayı token ile doğrula
  select id into v_masa_id
  from masalar
  where qr_token = p_qr_token and aktif = true;

  if v_masa_id is null then
    raise exception 'Geçersiz veya pasif masa QR kodu';
  end if;

  if p_kalemler is null or jsonb_array_length(p_kalemler) = 0 then
    raise exception 'Sipariş en az bir ürün içermeli';
  end if;

  -- Siparişi oluştur (toplam sonra güncellenecek)
  insert into siparisler (masa_id, durum, musteri_not)
  values (v_masa_id, 'beklemede', coalesce(p_musteri_not, ''))
  returning id into v_siparis_id;

  -- Her kalem için fiyatı DB'den oku, snapshot'la ekle
  for v_kalem in select * from jsonb_array_elements(p_kalemler)
  loop
    select * into v_urun
    from menu_urunler
    where id = (v_kalem->>'urun_id')::bigint and stokta = true;

    if v_urun.id is null then
      raise exception 'Ürün bulunamadı veya stokta değil: %', v_kalem->>'urun_id';
    end if;

    v_adet := coalesce((v_kalem->>'adet')::int, 0);
    if v_adet <= 0 then
      raise exception 'Geçersiz adet: %', v_kalem->>'adet';
    end if;

    insert into siparis_kalemleri (siparis_id, urun_id, urun_ad, adet, birim_fiyat, kalem_not)
    values (v_siparis_id, v_urun.id, v_urun.ad, v_adet, v_urun.fiyat, coalesce(v_kalem->>'kalem_not', ''));

    v_toplam := v_toplam + (v_urun.fiyat * v_adet);
  end loop;

  update siparisler set toplam_tutar = v_toplam where id = v_siparis_id;

  return v_siparis_id;
end;
$$;

-- anon'un bu fonksiyonu çağırabilmesi gerekiyor (SECURITY DEFINER sayesinde
-- fonksiyon içindeki işlemler tablo sahibi yetkisiyle çalışır, ama anon'a
-- doğrudan tablo INSERT yetkisi verilmez):
revoke all on function siparis_olustur(uuid, jsonb, text) from public;
grant execute on function siparis_olustur(uuid, jsonb, text) to anon, authenticated;

-- --- Müşteri kendi siparişini id ile sorgulasın (SECURITY DEFINER) --------
-- Anon'un siparisler tablosunda SELECT policy'si yok; bu fonksiyon, sadece
-- elinde geçerli bir sipariş uuid'si olan çağıranın o TEK siparişin özetini
-- görmesine izin verir. Toplu listeleme mümkün değildir.
create or replace function siparis_durumu_getir(p_siparis_id uuid)
returns table (
  id uuid,
  durum text,
  toplam_tutar numeric,
  created_at timestamptz,
  kalemler jsonb
)
language sql
security definer
set search_path = public
stable
as $$
  select
    s.id,
    s.durum,
    s.toplam_tutar,
    s.created_at,
    coalesce(
      (select jsonb_agg(jsonb_build_object(
                 'urun_ad', k.urun_ad,
                 'adet', k.adet,
                 'birim_fiyat', k.birim_fiyat,
                 'kalem_not', k.kalem_not
               ))
       from siparis_kalemleri k
       where k.siparis_id = s.id),
      '[]'::jsonb
    ) as kalemler
  from siparisler s
  where s.id = p_siparis_id;
$$;

revoke all on function siparis_durumu_getir(uuid) from public;
grant execute on function siparis_durumu_getir(uuid) to anon, authenticated;

-- ----------------------------------------------------------------------------
-- 4. REALTIME
-- ----------------------------------------------------------------------------

alter publication supabase_realtime add table siparisler;
alter publication supabase_realtime add table siparis_kalemleri;

-- ----------------------------------------------------------------------------
-- 5. SEED — mevcut index.html menüsü + örnek masalar
-- ----------------------------------------------------------------------------

insert into menu_kategoriler (ad, sira) values
  ('Çorbalar', 0),
  ('Başlangıçlar', 1),
  ('Izgara & Kebap', 2),
  ('Ev Yemekleri', 3),
  ('Tatlılar', 4),
  ('İçecekler', 5)
on conflict do nothing;

insert into menu_urunler (kategori_id, ad, aciklama, fiyat, gorsel_url, rozet, one_cikan, sira)
select k.id, u.ad, u.aciklama, 0, u.gorsel_url, u.rozet, u.one_cikan, u.sira
from (values
  ('Çorbalar', 'Kelle Paça Çorbası', 'Saatlerce kaynatılan, sarımsaklı sirkesiyle harika bir lezzet sunan meşhur kelle paça çorbamız — sabahın en iyi başlangıcı.', '', '★ Harika Lezzet', true, 0),
  ('Çorbalar', 'Mercimek Çorbası', 'Günlük taze hazırlanan, kremamsı kıvamda klasik mercimek çorbamız.', '', '', false, 1),
  ('Çorbalar', 'İşkembe Çorbası', 'Sirke ve sarımsaklı sosuyla servis edilen geleneksel işkembe çorbamız.', '', '', false, 2),
  ('Başlangıçlar', 'Mevsim Salata', 'Taze mevsim sebzeleri ile hazırlanan hafif başlangıç.', '', '', false, 0),
  ('Başlangıçlar', 'Ezme & Cacık', 'Acılı ezme ve serinletici cacık ikilisi.', '', '', false, 1),
  ('Izgara & Kebap', 'Patlıcanlı Köfte Kebap', 'Bulgur pilavı ve közlenmiş sebzelerle servis edilen özel kebabımız.', 'PatlicanKebap.jpeg', 'Şefin Önerisi', false, 0),
  ('Izgara & Kebap', 'Karışık Kebap Tabağı', 'Adana, kuşbaşı, pide ve mevsim garnitürleriyle zengin karışık tabak.', 'karisikkebap.jpeg', 'Popüler', false, 1),
  ('Izgara & Kebap', 'Kuzu İncik', 'Saatlerce pişirilen, kemiğinden ayrılan yumuşaklıkta kuzu incik.', 'incik.jpeg', '', false, 2),
  ('Izgara & Kebap', 'Meşhur Yaprak Döner', 'Odun ateşinde pişen, ince dilimlenmiş meşhur yaprak dönerimiz — Çınar''ın imza lezzeti.', '', '★ Meşhur', true, 3),
  ('Ev Yemekleri', 'Günün Ev Yemekleri', 'Her gün taze hazırlanan, ocak başı usulü çeşit çeşit ev yemeklerimiz.', 'evyemekleri.jpeg', '', false, 0),
  ('Ev Yemekleri', 'Etli Kuru Fasulye', 'Pilav eşliğinde, geleneksel tarifle pişen kuru fasulyemiz.', '', '', false, 1),
  ('Ev Yemekleri', 'Nohutlu Tas Kebabı', 'Yumuşacık et parçaları ve nohutla hazırlanan ev yemeği klasiği.', '', '', false, 2),
  ('Tatlılar', 'Künefe', 'Sıcak servis edilen, üzeri fıstıklı geleneksel künefe.', '', 'Popüler', false, 0),
  ('İçecekler', 'Ayran', 'Ev yapımı, taze çırpılmış ayran.', '', '', false, 0),
  ('İçecekler', 'Şalgam', 'Acılı/acısız seçenekleriyle klasik şalgam suyu.', '', '', false, 1)
) as u(kategori_ad, ad, aciklama, gorsel_url, rozet, one_cikan, sira)
join menu_kategoriler k on k.ad = u.kategori_ad
on conflict do nothing;

insert into masalar (masa_no) values
  ('1'), ('2'), ('3'), ('4'), ('5')
on conflict do nothing;

-- ============================================================================
-- Bitti. Sonraki adım: panel.html üzerinden gerçek fiyatları girin ve
-- Masalar & QR sekmesinden her masa için QR kodu yazdırın.
-- ============================================================================
