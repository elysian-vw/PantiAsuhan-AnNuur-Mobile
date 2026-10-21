# annuur_mobile

Aplikasi Mobile Donatur Tetap - Panti Asuhan NU An-Nuur 2 Kota Kediri

Project Flutter ini terpisah dari Laravel:

- Mobile: `D:\apps\laragon\www\annuur_mobile`
- Web dan API: `D:\apps\laragon\www\projectTA`

## Menjalankan

```powershell
Set-Location D:\apps\laragon\www\annuur_mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=https://HOST-BACKEND/api/v1
```

Ganti `HOST-BACKEND` dengan alamat Laravel yang dapat diakses HP/emulator.
Untuk HP Android melalui USB, alamat bawaan adalah `http://127.0.0.1:8000/api/v1`.
Jalankan backend di terminal terpisah, lalu teruskan port ke HP sebelum menjalankan Flutter:

```powershell
# Terminal backend (folder projectTA)
php artisan serve --host=127.0.0.1 --port=8000

# Terminal mobile (folder annuur_mobile), setelah HP terhubung USB debugging
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:8000 tcp:8000
flutter run
```

Ulangi `adb reverse` setelah HP terputus atau restart. Untuk emulator Android,
gunakan `--dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1`.
Alamat ngrok lama tidak dipakai sebagai nilai bawaan karena dapat kedaluwarsa.
Perubahan `API_BASE_URL` memerlukan aplikasi dijalankan ulang dengan `flutter run`.

Alamat API ditentukan melalui `API_BASE_URL`; perubahan lokasi source tidak mengubah
alamat API. Jangan mengandalkan alamat tunnel bawaan yang mungkin sudah tidak aktif.
Tailwind digunakan di web; antarmuka Flutter menggunakan widget dan tema Dart.

## Pemeriksaan

```powershell
flutter analyze
flutter test
```

Tes unit/widget belum membuktikan alur terintegrasi dengan Laravel berjalan.
Temuan kontrak API dicatat di `..\projectTA\docs\review-revisi-2026-10-20.md`.
Folder ini berada di luar repository Git web; cadangkan/versioning secara terpisah.

## Jika daemon Gradle berhenti karena memori habis

Periksa `android/hs_err_pid*.log`. Pesan `There is insufficient memory` menunjukkan
Java kehabisan memori sistem. Konfigurasi `android/gradle.properties` membatasi
heap Gradle menjadi 768 MB, satu worker, dan kompilasi Kotlin dalam proses Gradle
agar kebutuhan memori lebih kecil pada komputer dengan RAM 6 GB.

Tutup aplikasi berat yang tidak diperlukan, lalu ulangi `flutter run`.
Jika log masih menunjukkan `AvailPageFile` hampir nol, sediakan memori tambahan
atau perbesar virtual memory/pagefile Windows sebelum mencoba lagi.
