# Çınar Restaurant — QR Menü & Canlı Sipariş Sistemi

> Bu doküman, [CINAR_RESTORANT_PLAN.md](CINAR_RESTORANT_PLAN.md)'deki tanıtım sitesine ek olarak geliştirilen **QR menü ve canlı sipariş sistemini** anlatır. Sistem canlıda: **https://cinarrestaurant.vercel.app**

---

## 1. Ne Yapıyor?

Her masaya özel bir QR kod basılır. Müşteri telefonuyla QR'ı okutur, menüyü görür, sepet oluşturup sipariş verir. Sipariş önce **kontrol paneline (panel.html)** düşer; personel onaylayınca **mutfak ekranına (mutfak.html)** iletilir ve orada hazırlanıyor → hazır → teslim aşamalarından geçer. Tüm akış Supabase Realtime ile **canlıdır** — sayfa yenilemeye gerek yoktur.

Ödeme masada (nakit/kart) alınır; sistemde online ödeme yoktur. Menü ve fiyatlar panelden yönetilir; kod değişikliği veya yeniden deploy gerekmez.

---

## 2. Mimari

Sistem, mevcut statik siteyle aynı yaklaşımı korur: **build adımı yok**, her sayfa tek başına çalışan HTML dosyası. Veri tabanı ve gerçek zamanlı iletişim için **Supabase** (Postgres + Realtime + Auth) kullanılır.

| Dosya | Rol | Kim kullanır |
|---|---|---|
| `index.html` | Tanıtım sitesi — menü artık aynı veri tabanından okunuyor | Herkes |
| `masa.html` | QR hedefi — menü görüntüleme ve sipariş verme | Müşteri (QR ile, `?t=<masa_token>`) |
| `panel.html` | Kontrol birimi — sipariş onay/red, menü yönetimi, masa & QR üretimi | Personel (giriş gerekli) |
| `mutfak.html` | Mutfak ekranı — onaylı siparişlerin hazırlanma takibi | Personel (giriş gerekli) |
| `supabase/schema.sql` | Veri tabanı şeması, güvenlik kuralları, RPC fonksiyonları, başlangıç verisi | Kurulum (bir kez çalıştırılır) |
| `supabase/rapor.sql` | Satış raporu RPC'si (`satis_raporu`) | Kurulum (bir kez çalıştırılır) |
| `js/supabase-client.js` | Ortak Supabase istemcisi (URL + anon key) | Tüm sayfalar |
| `js/pdf-font.js` | PDF raporu için gömülü Türkçe destekli Noto Sans fontu (base64) | panel.html (Raporlar → PDF İndir) |
| `css/cinar-theme.css` | Paylaşılan tasarım sistemi (index.html ile aynı renk/tipografi) | masa/panel/mutfak sayfaları |

### Sipariş durum akışı

```
beklemede  →  onaylandı  →  hazırlanıyor  →  hazır  →  teslim
   ↑              ↑              ↑            ↑
 müşteri        panel          mutfak       mutfak
 gönderir      onaylar       başlatır      tamamlar
```

Panel, `iptal` durumuna da her aşamada geçirebilir.

---

## 3. Veri Tabanı (Supabase / Postgres)

Tam şema `supabase/schema.sql` içinde. Özet tablolar:

- **`masalar`** — masa no + tahmin edilemez `qr_token` (uuid)
- **`menu_kategoriler`** / **`menu_urunler`** — menü içeriği ve fiyatlar
- **`siparisler`** — sipariş başlığı (masa, durum, toplam, not)
- **`siparis_kalemleri`** — sipariş satırları (ürün, adet, **sipariş anındaki** fiyat)

### Güvenlik modeli (RLS)

Bu sistemin en kritik tarafı: **anon (müşteri) anahtarı frontend'de herkese açıktır**, dolayısıyla veri tabanı kuralları buna göre sıkı tasarlandı:

- `masalar` ve `siparisler` tablolarında anon için **toplu SELECT yetkisi yoktur** — biri anon key'i ele geçirse bile `select * from masalar` ile tüm QR token'larını veya `select * from siparisler` ile tüm siparişleri çekemez.
- Müşteri erişimi yalnızca **elindeki tek token/uuid** ile çalışan `SECURITY DEFINER` RPC fonksiyonları üzerinden sağlanır:
  - `masa_dogrula(qr_token)` — QR'daki token'ı doğrular, sadece o masayı döner.
  - `siparis_olustur(qr_token, kalemler, not)` — siparişi oluşturur.
  - `siparis_durumu_getir(siparis_id)` — sadece elindeki sipariş uuid'sinin durumunu döner.
- **Fiyat bütünlüğü:** `siparis_olustur` fiyatları client'tan almaz, `menu_urunler` tablosundan sunucu tarafında okur ve toplamı kendisi hesaplar. Client'tan sahte bir fiyat gönderilse bile hiçbir etkisi olmaz.
- Personel (authenticated) rolü tüm tablolarda tam yetkiye sahiptir (RLS policy'leriyle).
- `satis_raporu(baslangic, bitis)` — satış raporu RPC'si. Yalnızca `authenticated` role'e `execute` yetkisi verilmiştir; anon bu fonksiyonu çağıramaz (ciro bilgisi gizlidir).

### Neden polling, neden realtime değil (müşteri tarafı)

`masa.html`, kendi sipariş durumunu **5 saniyede bir RPC ile sorgulayarak (polling)** takip eder — Supabase Realtime değil. Sebep: Realtime abonelikleri de RLS'e tabidir; `siparisler` tablosunda anon için SELECT policy'si olmadığından (yukarıdaki güvenlik gerekçesiyle) anon bu tabloyu realtime dinleyemez. Panel ve mutfak ekranları ise personel (authenticated) olduğu için gerçek Supabase Realtime kullanır — sipariş geldiği an, saniyeler içinde ekranda belirir.

### PDF fontu (`js/pdf-font.js`)

PDF motoru (jsPDF) varsayılan olarak yalnızca temel Latin harflerini destekler; Türkçe'ye özgü ğ, ş, ı, İ, ö, ü, ç ve ₺ işareti standart PDF fontlarında **yoktur**. Bunu çözmek için Google'ın açık kaynaklı **Noto Sans** fontu (Apache 2.0) kullanıldı:

1. Değişken (variable) font, `fonttools` ile Regular (400) ve Bold (700) statik örneklerine indirgendi.
2. Yalnızca gereken karakterlere (Latin + Türkçe + ₺ + tire) `pyftsubset` ile subset edilerek ~2 MB'tan ~49 KB/font'a indirildi.
3. Base64'e çevrilip `js/pdf-font.js` içine gömüldü — çalışma zamanında harici bir font sunucusuna istek atılmaz (bu projede CDN kaynaklı iki ayrı sorun yaşandığından — bkz. aşağıdaki bölüm — üçüncü bir dış bağımlılık riski alınmadı).

---

## 4. Kurulum (bir kereye mahsus, tamamlandı)

1. Supabase projesi oluşturuldu, Project URL + anon key `js/supabase-client.js` içine eklendi.
2. `supabase/schema.sql`, Supabase SQL Editor'de çalıştırıldı → tablolar, RLS, RPC'ler ve başlangıç menüsü (mevcut `index.html` menüsünden aktarıldı, fiyatlar 0 olarak) + 5 örnek masa oluşturuldu.
3. Supabase Authentication'da personel girişi için en az bir e-posta/şifre hesabı açıldı (panel.html ve mutfak.html bu hesapla açılır).
4. `supabase/rapor.sql`, Supabase SQL Editor'de çalıştırıldı → `satis_raporu` RPC'si oluşturuldu (panel.html'deki Raporlar sekmesi için).

---

## 5. Günlük Kullanım

### Personel — Panel (`panel.html`)
- **Siparişler** sekmesi: bekleyen siparişler burada belirir (yeni sipariş geldiğinde sesli uyarı çalar), **Onayla** veya **İptal** ile işlem yapılır.
- **Menü Yönetimi** sekmesi: kategori/ürün ekle-düzenle-sil, fiyat güncelle, "Stokta" işaretini kaldırarak bir ürünü geçici olarak menüden kaldır.
- **Masalar & QR** sekmesi: yeni masa ekle, her masanın QR kodunu gör/yazdır, masayı aktif/pasif yap.
- **Raporlar** sekmesi: hangi üründen kaç adet satıldığını ve cirosunu gösterir. Bugün / Bu Hafta / Bu Ay / Tümü hazır aralıkları veya özel tarih seçimi ile filtrelenir; ürün bazında ve kategori bazında dökümü, toplam ciro/adet/sipariş sayısı özet kartlarını gösterir. **PDF İndir** ve **Yazdır** düğmeleriyle dışa aktarılabilir. İptal edilen siparişler rapora dahil edilmez; ciro, sipariş anındaki (snapshot) fiyat üzerinden hesaplanır — sonradan menü fiyatı değişse bile geçmiş rapor bozulmaz.
  - **PDF:** jsPDF + jsPDF-AutoTable ile oluşturulur; Türkçe karakterler (ğ, ş, ı, İ, ö, ü, ç) ve ₺ işareti için `js/pdf-font.js` içine **gömülü** bir Noto Sans font kullanılır (bkz. aşağıdaki "PDF fontu" notu) — harici bir font CDN'ine bağımlı değildir.

### Personel — Mutfak (`mutfak.html`)
- Onaylanan siparişler otomatik belirir. **Hazırlanıyor → Hazır → Teslim** butonlarıyla ilerletilir.

### Müşteri (`masa.html`)
- QR kod okutulur → menü görünür → sepete ürün eklenir → not eklenebilir → "Siparişi Gönder".
- Gönderildikten sonra sipariş durumu ekranda canlı olarak (adım adım) takip edilir.
- "+ Yeni Sipariş Ver" ile aynı masadan ikinci bir sipariş daha verilebilir.

---

## 6. Bilinen Sınırlamalar / Sonraki Adaylar

- Menüdeki bazı ürünlerin fiyatı henüz 0 ₺ — panelden girilmesi gerekiyor.
- Şu an yalnızca 5 örnek masa var; gerçek masa sayısına göre panelden eklenip QR'lar yazdırılmalı.
- Online ödeme, yazıcı entegrasyonu ve çoklu dil şu an kapsam dışı (bkz. orijinal plan).
- "Garson Çağır" butonu gelecekte eklenebilecek küçük bir iyileştirme.

---

## 7. Geliştirme Sırasında Çözülen Sorunlar

Kayıt amacıyla: canlıya alma sürecinde çıkan ve düzeltilen teknik sorunlar —

1. **Supabase istemcisi yüklenmiyordu:** İlk sürümde `<script type="module">` ile `esm.sh` üzerinden ESM import kullanılıyordu; bazı ağlarda bu import sessizce başarısız olup formların tepkisiz kalmasına yol açıyordu. Çözüm: `@supabase/supabase-js` UMD build'i klasik `<script>` etiketiyle yükleniyor; kütüphane yüklenemezse artık kullanıcıya net bir hata mesajı gösteriliyor.
2. **QR kodları görünmüyordu:** `panel.html`'de kullanılan `qrcode@1.5.3` paketinin CDN'deki `build/qrcode.min.js` dosyası kaldırılmış (404), bu da Masalar & QR sekmesinin JS hatasıyla boş kalmasına neden oluyordu. Çözüm: çalışan `qrcodejs` (davidshimjs) kütüphanesine geçildi.
3. **CSV indirmede Türkçe karakterler bozuluyordu:** Rapor CSV'sine UTF-8 BOM, bir JS string literaline gömülü görünmez `﻿` karakteriyle ekleniyordu; kaynak dosya doğru kodlanmış olsa da (bayt düzeyinde doğrulandı) kullanıcı tarafında Excel'de karakterler bozuk görünüyordu (aynı anda PDF çıktısı sorunsuzdu). Önce `TextEncoder` + açık `0xEF,0xBB,0xBF` bayt dizisiyle daha sağlam bir yönteme geçildi; ardından **CSV özelliği tamamen kaldırıldı** — Türkçe karakter desteği yalnızca **PDF İndir** üzerinden sağlanıyor.

---

*Bu doküman, [CINAR_RESTORANT_PLAN.md](CINAR_RESTORANT_PLAN.md) ile birlikte projenin yaşayan teknik dokümantasyonudur.*
