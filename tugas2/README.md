# Tugas 2: Widget & State

Aplikasi ini diciptakan menggunakan banyak Widget yang secara garis besar dibagi menjadi tiga kelas, yaitu kelas MyApp, kelas RowColumnPage, dan kelas CounterCard. Script secara langsung memanggil MyApp yang menjalankan RowColumnPage pada MaterialApp sebagai home, sedangkan CounterCard dipanggil di dalam RowColumnPage.

#### A. MyApp
MyApp adalah sebuah StatelessWidget yang menginisialisi aplikasi. Custom StatelessWidget ini memuat tampilan statis yang terdiri dari beberapa widget lain, yaitu:
- MaterialApp: Widget yang sangat penting dalam aplikasi Flutter. MaterialApp mengatur fungsi-fungsi penting dalam sebuah aplikasi, seperti navigasi app, tema app, dan juga sebagai wrapper utama dari widget lain di dalamnya.
- RowColumnPage: Ini adalah Custom StatelessWidget juga yang akan dijelaskan lebih lanjut pada bagian B.
- ThemeData: ThemeData bukanlah sebuah Widget, namun tetap penting karena menyediakan warna, font, dan properti-properti komponen bagi aplikasi.

#### B. RowColumnPage
Custom StatelessWidget yang memiliki semua konten visual aplikasi. Widget ini dimuat oleh MyApp sebagai home page yang statis dan memiliki beberapa Widget lain di dalamnya:
- Scaffold: Widget ini menyediakan struktur komponen aplikasi yang umum dipakai. Bagian Scaffold yang digunakan pada RowColumnPage adalah appBar dan body.
- AppBar: Merupakan bagian yang biasanya merupakan bagian paling atas aplikasi pada layar. AppBar seringkali memuat toolbar dan juga beberapa tombol umum lainnya.
- Text: Widget yang dapat menampilkan teks pada layar.
- Column: Widget yang menyusun Widget childrennya secara vertikal. Secara sederhana, penggunaan widget ini menyatakan bahwa semua hal dalam dirinya adalah sebuah (hanya 1) kolom. Widget ini pertama kali digunakan pada aplikasi sebagai body dari Scaffold karena keperluan menata banyak Widget yang ditumpuk. Setelah itu, Widget Column digunakan untuk menata tiga ikon sebagai tiga kolom berbeda.
- Container: Widget yang berguna untuk dapat memberikan margin, padding, dan warna yang mudah bagi Widget childrennya. Pada RowColumnPage digunakan untuk menampilkan sebuah gambar secara lebih rapi.
- AspectRatio: Widget yang memaksa Widget childrennya (seperti gambar) untuk mengikuti suatu rasio yang ditentukan.
- Image: Digunakan untuk mengambil dan menampilkan suatu gambar. Pada aplikasi menggunakan Image.network yang mengambil gambar langsung dari sebuah URL.
- Row: Kebalikan dari Column, Widget ini menyusun Widget childrennya secara horizontal. Secara sederhana, penggunaan widget ini menyatakan bahwa semua hal dalam dirinya adalah sebuah (hanya 1) baris. Pada RowColumnPage, Row digunakan untuk memastikan bahwa tiga ikon di dalamnya berada dalam satu baris. 
- Icon: Widget yang dapat menampilkan sebuah ikon, simbol, atau logo.

#### C. CounterCard
Berbeda dengan MyApp dan RowColumnPage, kelas CounterCard merupakan sebuah Custom StatefulWidget yang dapat mengubah kontennya. Secara lebih spesifik, kelas ini memiliki sebuah teks angka yang akan berubah setiap kali sebuah tombol ditekan. 
- Container: Widget yang berguna untuk dapat memberikan margin, padding, dan warna yang mudah bagi Widget childrennya. Pada CounterCard digunakan untuk memuat keseluruhan dari tampilan kartu.
- IconButton: Widget yang menampilkan sebuah ikon, simbol, atau logo yang dapat ditekan. Pada aplikasi, tombol ini akan memanggil fungsi bernama _incrementCounter.
- Text: Widget yang dapat menampilkan teks pada layar.
- Icon: Widget yang dapat menampilkan sebuah ikon, simbol, atau logo.

