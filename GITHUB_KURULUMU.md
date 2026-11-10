# BLOCK NOVA — GitHub üzerinden otomatik APK oluşturma

**Durum:** İş akışı hazırlığı; Android APK henüz bu ortamda derlenmedi. Godot/Android çalışma zamanı doğrulaması GitHub Actions'ta yapılacaktır. Derleme başarısız olursa logları kontrol edin; otomatik iş akışı başarılı olana kadar APK var saymayın.

## En kolay yöntem (iki dosya)

1. GitHub'da yeni, boş bir depo oluştur: `BLOCK-NOVA` (adres: https://github.com/new). `Public` veya `Private` olabilir.
2. `BLOCK_NOVA_Source.zip` dosyasını **açmadan** deponun ana dizinine `Add file > Upload files` ile yükle, `Commit changes` seç.
3. `Add file > Create new file` seç. Dosya adı olarak **tam** `.github/workflows/android-apk.yml` yaz.
4. `BLOCK_NOVA_GitHub_Workflow.yml` içeriğini yeni dosyaya yapıştır ve `Commit changes` seç.
5. Depodaki **Actions > BLOCK NOVA - APK Olustur > Run workflow > Run workflow** yolunu kullan.
6. İşlem başarılıysa ilgili çalışmanın altında **Artifacts > BLOCK_NOVA_Android_APK** dosyasını indir. ZIP'in içinden `BLOCK_NOVA_Debug.apk` çıkar.
7. APK'yı telefonda kurup açılış, oyun, dokunma, kaydetme ve menüler için gerçek cihaz testi yap.

## Alternatif yöntem (tek kaynak paketi)

`BLOCK_NOVA_GitHub_Tum_Proje.zip` paketini çıkarıp içindeki klasör ve dosyaların tamamını depo ana dizinine yükle. Gizli `.github/` dizininin de yüklendiğinden emin ol. `push` sonrası iş akışı otomatik başlayabilir; başlamazsa Actions'tan elle çalıştır.

## Güvenlik ve sınırlar

- Paket sadece **test amaçlı debug APK** üretir; Google Play üretim AAB dosyası değildir.
- Debug anahtarı GitHub derleme makinesinde geçici oluşturulur. Özel yayın anahtarını asla herkese açık depoya yükleme.
- Kurulum sırasında kod/test hatası çıkarsa iş akışı kırmızı olur ve APK yayımlanmaz.
- APK boyutu kaydedilir ve 100 MB üst sınırı aşarsa başarısız sayılır. Asgari 90 MB boyutu garanti edilmez; gereksiz veri eklenmez.
- Bu kaynak geliştirme sürümüdür; 100 seviyenin oynanabilirliği ve cihazdaki kararlılık henüz doğrulanmadı.
