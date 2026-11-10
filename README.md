# BLOCK NOVA — Blok Evreni (Geliştirme Kaynağı)

**Durum:** Düzenlenebilir Godot 4.x kaynak projesi. **APK üretilmedi ve cihazda test edilmedi.**
Bu depo, Play Store'a hazır nihai ürün değildir; bazı modlar ve özellikler ilk sürüm
seviyesindedir ve çalışma zamanı testleri yapılmalıdır.

## Kurulum (kod yazmadan)

1. Windows bilgisayarınıza Godot Engine 4.5+ (standart, .NET olmayan) sürümünü kurun.
2. Proje ZIP'ini bir klasöre çıkarın. Godot → **Import** → `project.godot` seçin.
3. Sağ üstte **Çalıştır** (F6 değil, F5) tuşuna basıp oyunu bilgisayarda deneyin.
4. Android için Android Studio/SDK + Java 17 kurup Godot → **Editor Settings** →
   Android → SDK ve Java yollarını tanımlayın.
5. Godot → **Project → Install Android Build Template** (gerekirse).
6. Godot → **Project → Export** → Android → debug sürümü APK üretin.
   Paket kimliğini, ikonları ve imzalama ayarlarını gözden geçirin.
7. Cihaza yükleyip **her bir menüyü, oyunu, ses ve kayıt sistemini ayrı ayrı test edin**.
8. Mağaza dağıtımı için kendi **release keystore** dosyanızı güvenle oluşturun;
   ZIP içine asla özel anahtar veya şifre koymayın. Android AAB paketini aynı ekrandan
   seçerek ve uygun release ayarları ile dışa aktarın.

Komut satırı (Godot binary yolu PATH'e eklenmişse):

```bash
godot --headless --path . --script res://tests/test_logic.gd
godot --headless --path . --export-debug Android build/BLOCK_NOVA_Debug.apk
```

Test için Godot'un Android SDK'ya ihtiyacı yoktur; APK export için vardır.

## Mevcut kaynakta bulunanlar

- 8×8 blok bulmaca kuralları, 30 benzersiz blok şekli, üçlü parça grupları
- Dokunmatik/mouse ile parça taşıma, yerleştirme ve geçersiz hamlelerin reddi
- Satır/sütun eşzamanlı temizleme, puanlama, kombo, en yüksek puan
- Klasik, Zen, Zaman Yarışı (60/120/180 saniye), günün bulmacası
- 100 sayısal macera seviye tanımı, 5 farklı hedef mekanizması, buz, duvar, işaretler
- Güçlendirme çekirdeği: çekiç, satır, sütun, değiştir, geri al, ipucu, bomba
- 8 ayrı özgün prosedürel arka plan ve görsel tema, basit başarımlar/istatistikler
- JSON kayıt, ikinci yedek dosya ve geçici dosya ile güvenli yazma yaklaşımı
- Özgün, yapay olarak sentezlenmiş 5 müzik döngüsü ve 12 ses efekti
- Uygulama görsel kimliği, Android ikon varlıkları ve API 36 dışa aktarma taslağı

## Eksikler ve yayımlama blokajları

- Android SDK / Godot editörü bu üretim ortamında kurulu olmadığından APK/AAB **yok**.
- `tests/test_logic.gd` Godot koşucusunda **henüz çalıştırılamadı**.
- 100 seviye kurallarla üretilir; **her birinin çözülebilirliği doğrulanmadı**.
- Animasyonlar ve sesler başlangıç sürümüdür; profesyonel sanat yönetimi tamamlanmadı.
- Günlük görev ve haftalık görev gibi çok aşamalı ödül/sandık sistemleri bitmedi.
- Tema, grafik ve erişilebilirlik seçeneklerinin tümü cihaz üzerinde doğrulanmadı.
- Kayıt sistemi cihazda kesinti ve yükseltme testlerine ihtiyaç duyar.
- Türkçe metinler vardır, ancak tam erişilebilirlik/çeviri testleri yapılmadı.
- APK 90–100 MB hedefi **henüz doğrulanmadı**; gereksiz dosyalar eklenmemiştir.

## Dosyalar

- `scripts/game_logic.gd`: oyun matematiği, puanlama, seviye, kayıt şeması
- `scripts/main.gd`: oyun ekranı, dokunma, ses, görseller, menüler
- `assets/`: PNG ikonlar + OGG ses varlıkları
- `tests/test_reference.py`: Python'un bağımsız model testleri
- `tests/test_logic.gd`: Godot çalışma zamanında çalıştırılmak üzere hazırlanan testler
- `tools/generate_audio.py`: özgün sentezli varlıkları yeniden oluşturur
- `tools/generate_themes.py`: tema arka planlarını yeniden oluşturur
- `export_presets.cfg`: Godot Android SDK sürüm ve mimari yapılandırması

## Gizlilik

Giriş hesabı, konum, kamera, mikrofon, reklam veya analitik SDK bulunmaz.
Temel oyun internetsiz çalışmak üzere tasarlanmıştır. Ek servis eklemeden önce mağaza
politikaları, veri güvenliği ve yaş derecelendirmesi yeniden kontrol edilmelidir.

## GitHub Actions ile otomatik APK

Bkz: [GITHUB_KURULUMU.md](GITHUB_KURULUMU.md). Bu proje için `Android` debug export preset, kurulu Gradle şablonu gerektirmeyen hazır Android APK export template moduna alınmıştır.
