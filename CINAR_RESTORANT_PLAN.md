# Çınar Restorant — Web Sitesi Tasarım & Kurgu Dokümanı

> **Proje:** Erzincan'da yıllardır hizmet veren Çınar Restorant için modern, gösterişli ve dönüşüm odaklı tek sayfa web sitesi
> **Teslim biçimi:** Tek dosyalık `index.html` (build adımı yok, CSS/JS gömülü) → Netlify / Vercel
> **Dil:** Türkçe
> **Bu doküman:** Claude Code'a devir (handoff) için hazırlanmıştır. `[PLACEHOLDER]` etiketli her yer, işletmeden gelecek gerçek içerikle doldurulacaktır.

---

## 1. Konsept & Marka Yönü

Çınar Restorant "yıllardır halkına hizmet eden" bir işletme. Bu, sitenin duygusal çekirdeği: **köklülük, güven, sıcaklık ve emek.** Çınar ağacı zaten bu hikâyenin sembolü — geniş gölge, uzun ömür, bir mahallenin buluşma noktası. Tasarım bu metaforun üzerine kurulmalı.

**Estetik yön: "Modern köklülük" (warm editorial).**
Ne steril bir kurumsal şablon, ne de klişe restoran teması. Sıcak toprak tonları + zengin koyu yeşil (çınar yaprağı) + doğal doku hissi. Bol nefes alan boşluk, iri ve iddialı tipografi, yemek fotoğraflarının kahraman olduğu bir sahne.

**Akılda kalacak tek şey (differentiator):** Açılışta çınar yaprağı temalı hafif bir "gölge/ışık" animasyonu ve iri serifli başlık — kullanıcı daha ilk saniyede "burası köklü ve kaliteli bir yer" hissini almalı.

---

## 2. Tasarım Sistemi

### Renk paleti (CSS değişkenleri)

```css
:root {
  --cinar-green:    #2F4A3C;  /* koyu çınar yeşili — ana marka rengi */
  --cinar-green-2:  #3E6350;  /* açık yeşil vurgu */
  --terracotta:     #C4703E;  /* toprak / bakır — sıcak aksan (CTA, ikon) */
  --cream:          #F5EFE4;  /* krem zemin */
  --sand:           #E8DDC8;  /* kum tonu kartlar */
  --charcoal:       #23201C;  /* metin — sıcak siyah */
  --muted:          #6B6459;  /* ikincil metin */
  --gold:           #B08D4C;  /* ince altın çizgi/ayraç */
}
```

> Klişeden kaçın: mor gradyan, saf beyaz zemin, sistem fontu kullanma. Zemin **krem**, siyah **sıcak siyah** olacak.

### Tipografi

- **Başlık (display):** Zarif serif — `Playfair Display` veya `Fraunces` (Google Fonts). İri, iddialı, karakterli.
- **Gövde metni:** Okunaklı ve modern sans — `DM Sans` veya `Manrope`.
- Türkçe karakter desteği doğrulanmalı (ş, ğ, ı, İ, ö, ç, ü).

### Genel his

- Yumuşak, uzun gölgeler; ince altın ayraç çizgileri.
- Fotoğrafların üzerinde hafif koyulaştırma (overlay) ile metin okunurluğu.
- Bölüm geçişlerinde scroll ile beliren (fade-up) hafif animasyonlar.
- Köşeler yumuşak (border-radius ~12–16px), kartlarda doğal doku hissi.
- Mobil öncelikli (mobile-first), tam responsive.

---

## 3. Sayfa Yapısı (Tek Sayfa / Bölümler)

Aşağıdaki bölümler tek `index.html` içinde, üstte sabit (sticky) bir gezinme menüsüyle bağlanacak.

### 3.1 Navigasyon (sticky header)
- Sol: Çınar Restorant logosu `[PLACEHOLDER: logo]`
- Orta/Sağ: Menü · Hakkımızda · Galeri · İletişim
- Sağ uçta belirgin **"Rezervasyon"** butonu (terracotta renk)
- Scroll edilince header hafif küçülüp gölge alsın.

### 3.2 Hero (Kahraman bölüm)
- Tam ekran, arka planda mekânın en güzel yemek/ambiyans fotoğrafı `[PLACEHOLDER]`
- İri serif başlık: **"Erzincan'ın sofrası, yıllardır Çınar'da"** `[PLACEHOLDER: slogan onayı]`
- Alt metin: kısa bir cümle (ör. "1998'den bu yana aynı lezzet, aynı samimiyet") `[PLACEHOLDER: kuruluş yılı]`
- İki buton: **Rezervasyon Yap** (birincil) · **Menüyü Gör** (ikincil)
- Alt köşede küçük bilgi çipleri: ⭐ Puan · 📍 Konum · 🕒 Açılış saatleri

### 3.3 Hikâye / "Neden Çınar?" (Hakkımızda)
İşletmenin karakterini anlatan bölüm — kullanıcının "neden oraya gitmeli" sorusuna cevap.
- Sol: doku hisli görsel (mutfak / usta / mekân) `[PLACEHOLDER]`
- Sağ: 2-3 paragraf hikâye metni `[PLACEHOLDER: gerçek hikâye]`
- Alt: 3-4 değer kartı — örn:
  - 🌿 **Yıllanmış Tecrübe** — [X] yıldır aynı sofra
  - 🍲 **Yöresel Lezzetler** — Erzincan mutfağının özü
  - 👨‍🍳 **Usta Eller** — her tabak elde, taze
  - 🤝 **Samimi Hizmet** — misafir değil, aile

### 3.4 Menü & Fiyatlandırma (görselli)
En kritik bölüm. Kategorilere ayrılmış, fotoğraflı, fiyatlı menü.
- Üstte kategori sekmeleri (tab): **Başlangıçlar · Ana Yemekler · Izgara · Tatlılar · İçecekler** `[PLACEHOLDER: gerçek kategoriler]`
- Her ürün kartı:
  - Ürün fotoğrafı `[PLACEHOLDER]`
  - Ürün adı + kısa açıklama
  - Fiyat (₺) `[PLACEHOLDER]`
  - İsteğe bağlı rozet: "Şefin Önerisi" / "Popüler"
- Grid yapısı: masaüstünde 3 sütun, tablette 2, mobilde 1.
- **Not:** Fiyatlar sık değişiyorsa, JS içinde tek bir `menuData` dizisinde tutulmalı ki güncellemesi kolay olsun.

**Örnek veri yapısı (JS):**
```js
const menuData = {
  "Ana Yemekler": [
    { ad: "[PLACEHOLDER]", aciklama: "[PLACEHOLDER]", fiyat: "[₺]", gorsel: "[url]", rozet: "Şefin Önerisi" },
    // ...
  ],
  // diğer kategoriler...
};
```

### 3.5 Galeri (mekânın güzelliği)
Mekânın atmosferini, ambiyansını, sunumları gösteren fotoğraf galerisi.
- Masonry / ızgara galeri, tıklayınca büyüyen lightbox.
- 8-12 kaliteli fotoğraf `[PLACEHOLDER]`: iç mekân, bahçe/teras, masa düzeni, tabak sunumları, kalabalık/atmosfer.
- Amaç: "buranın havası güzelmiş" hissini vermek.

### 3.6 Yorumlar / Sosyal Kanıt
- 3-4 gerçek müşteri yorumu kartı `[PLACEHOLDER]` (ad, yıldız, kısa yorum)
- Varsa Google puanı ve yorum sayısı rozeti `[PLACEHOLDER]`

### 3.7 Rezervasyon Bölümü
Ayrı bir bölüm + hero'daki butonların hedefi. (Detaylar Bölüm 4.)

### 3.8 İletişim & Konum
- Adres, telefon (tıkla-ara), WhatsApp butonu, çalışma saatleri `[PLACEHOLDER]`
- Gömülü harita (Google Maps iframe) `[PLACEHOLDER: konum linki]`
- Sosyal medya ikonları (Instagram öncelikli) `[PLACEHOLDER]`

### 3.9 Footer
- Logo, kısa slogan, hızlı linkler, telif satırı, KVKK/gizlilik notu.

---

## 4. Rezervasyon Uygulaması (Detaylı Spesifikasyon)

Tek dosyalık statik site olduğu için sunucu tarafı olmadan çalışan bir yaklaşım öneriyorum. Üç seçenek — önerilenden başlayarak:

### Seçenek A — WhatsApp'a yönlendirme (ÖNERİLEN, en hızlı)
Form doldurulur, "Rezervasyon Gönder" butonu bilgileri hazır bir WhatsApp mesajına çevirip işletme numarasına yönlendirir. Sunucu, veritabanı, maliyet yok. Küçük/orta işletme için ideal.

```js
function rezervasyonGonder() {
  const mesaj = `Merhaba, rezervasyon yapmak istiyorum.%0A
    Ad: ${ad}%0AKişi: ${kisi}%0ATarih: ${tarih}%0ASaat: ${saat}%0ANot: ${not}`;
  window.open(`https://wa.me/[PLACEHOLDER_TELEFON]?text=${mesaj}`, "_blank");
}
```

**Form alanları:**
- Ad Soyad (zorunlu)
- Telefon (zorunlu)
- Tarih (date picker — geçmiş tarihler kapalı)
- Saat (çalışma saatlerine göre select)
- Kişi sayısı (1-20+ select)
- Özel not (opsiyonel — doğum günü, alerji vb.)

**Doğrulama:** boş alan kontrolü, geçerli tarih/saat, mobil dostu native input'lar.

### Seçenek B — E-posta gönderimi
Formspree / Web3Forms gibi ücretsiz bir servisle form doğrudan işletme e-postasına düşer. Yine sunucu gerekmez, sadece bir API anahtarı.

### Seçenek C — Tam rezervasyon sistemi (ileri seviye)
Supabase tablosu + basit admin paneli (senin Bey Efendi Kuaför projendeki gibi randevu takibi). Rezervasyonlar veritabanına yazılır, işletme bir panelden görür. İşletme büyürse bu yola geçilebilir — şimdilik overkill.

> **Karar gerekli:** Hangi seçenek? Varsayılan olarak **Seçenek A (WhatsApp)** ile ilerlenecek.

---

## 5. Teknik Notlar

- **Yapı:** Tek `index.html`, gömülü `<style>` ve `<script>`. Build adımı yok.
- **Fontlar:** Google Fonts CDN üzerinden (`<link>`).
- **İkonlar:** Inline SVG veya Lucide (CDN).
- **Görseller:** WebP formatında, `loading="lazy"`. İşletmeden gelen ham fotoğraflar optimize edilecek.
- **Performans:** Hero görseli optimize, kritik CSS gömülü, lazy-load ile hızlı ilk açılış.
- **SEO:**
  - `<title>`: "Çınar Restorant | Erzincan'ın Köklü Lezzet Durağı" `[PLACEHOLDER]`
  - Meta description, Open Graph etiketleri (WhatsApp/sosyal paylaşımda güzel görünsün).
  - LocalBusiness (Restaurant) JSON-LD şeması — Google'da adres, saat, puan görünür.
- **Erişilebilirlik:** yeterli renk kontrastı, alt metinler, klavye ile gezinilebilir menü.
- **Dağıtım:** Netlify veya Vercel (senin standart akışın).

---

## 6. İşletmeden Toplanacak İçerik (Checklist)

Site canlıya çıkmadan önce doldurulması gerekenler:

- [ ] Logo (SVG veya yüksek çözünürlüklü PNG)
- [ ] Kuruluş yılı / kaç yıldır hizmet verdiği
- [ ] İşletme hikâyesi (2-3 paragraf)
- [ ] Tam menü: kategoriler, ürün adları, açıklamalar, **güncel fiyatlar**
- [ ] Menü ürünlerinin fotoğrafları (en azından öne çıkan ürünler)
- [ ] Mekân/ambiyans fotoğrafları (galeri için 8-12 adet)
- [ ] Telefon, WhatsApp numarası, adres
- [ ] Çalışma saatleri
- [ ] Google Maps konum linki
- [ ] Instagram / sosyal medya hesapları
- [ ] Rezervasyon yöntemi tercihi (WhatsApp / e-posta / tam sistem)
- [ ] Müşteri yorumları veya Google puanı

---

## 7. Yapım Sırası (Build Roadmap)

1. HTML iskeleti + CSS değişkenleri + font/renk sistemi
2. Sticky navigasyon + Hero bölümü
3. Menü bölümü (JS `menuData` ile dinamik render + kategori tab'ları)
4. Hikâye / değer kartları bölümü
5. Galeri + lightbox
6. Rezervasyon formu + WhatsApp entegrasyonu
7. Yorumlar + İletişim + harita + footer
8. Scroll animasyonları, mobil ince ayar, SEO/meta, JSON-LD
9. Placeholder içeriklerin gerçek verilerle değişimi
10. Netlify/Vercel dağıtımı

---

*Bu doküman bir yaşayan plandır — içerik netleştikçe güncellenecektir.*
