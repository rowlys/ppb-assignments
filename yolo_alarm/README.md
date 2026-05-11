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

### Home Screen
<img width="738" height="1600" alt="image" src="https://github.com/user-attachments/assets/fd9177b6-5603-4352-bf8f-0166155c59b3" />

### Camera Screen
<img width="738" height="1600" alt="image" src="https://github.com/user-attachments/assets/8431e183-958b-40ab-9808-6c7e0be0ecc4" />

### Alarm Screen
<img width="738" height="1600" alt="image" src="https://github.com/user-attachments/assets/e3643f61-89ac-4462-88cb-66a119c8b500" />

### Math Fallback
<img width="738" height="1600" alt="image" src="https://github.com/user-attachments/assets/50421d0a-f7d7-4e51-be4f-ceeb19b01b61" />
