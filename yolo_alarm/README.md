Nama: Basten Andika Salim
NRP : 5025231132

# YOLO Alarm

Aplikasi alarm Android yang mengharuskan pengguna **memindai objek nyata** menggunakan kamera untuk mematikan alarm, bukan hanya menggeser layar, dengan bantuan model YOLOv8n yang berjalan langsung di perangkat via TFLite.

## Fitur

- **Scan to dismiss**: pilih objek dari daftar COCO (80 kelas: botol, kucing, laptop, dll.), lalu alarm hanya bisa dimatikan setelah kamera mendeteksi objek tersebut dengan keyakinan ≥ 65%.
- **Math fallback**: jika kondisi tidak memungkinkan untuk scan (gelap, objek tidak tersedia), pengguna bisa memilih menjawab soal matematika sebagai gantinya. Tersedia tiga tingkat kesulitan:
  - *Easy*: penjumlahan/pengurangan hingga 20
  - *Medium*: perkalian tabel 2–12
  - *Hard*: soal dua langkah: `(a + b) × c`
- **Alarm berulang**: atur hari pengulangan (Sen–Min) secara bebas.


> Berhasil diuji pada Android 16. Minimum Android yang didukung menyesuaikan konfigurasi `flutter_local_notifications` (androidScheduleMode: alarmClock memerlukan Android 12+).

## Screenshot

