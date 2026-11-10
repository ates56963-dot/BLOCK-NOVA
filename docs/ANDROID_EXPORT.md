# APK ve AAB üretme kontrol listesi

- Godot editor: Godot 4.5+ normal sürüm.
- Android SDK platform API **36**, build-tools, platform tools.
- Java: önerilen JDK 17.
- Export template Android Godot sürümü ile eşleşmeli.
- `export_presets.cfg`: ARM64, min SDK 26 (Android 8.0), target SDK 36.
- `Project > Install Android Build Template` seçeneğini uygula.
- Testte Android preset kullanıp Debug APK çıkar.
- `adb install -r build/BLOCK_NOVA_Debug.apk` ve `adb logcat` ile açılış hatalarını izle.
- Release için keystore'u kişisel bilgisayarında üret, dizine ZIP'le koyma.
- AAB gerekiyorsa Android exporter `Export Format: AAB` seç. İmzasız paket Play Console'a yüklenmez.
- Play Console gizlilik beyanı / veri güvenliği bilgilerini son sürüme göre doğrula.

Google Play 31 Ağustos 2026 sonrası yeni uygulamalar için target API 36 istiyor.
Kaynak: https://support.google.com/googleplay/android-developer/answer/11926878?hl=tr
