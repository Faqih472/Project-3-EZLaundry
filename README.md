# 🧺 EZLaundry

EZLaundry adalah aplikasi mobile berbasis **Flutter + Firebase** yang dirancang untuk mempermudah manajemen layanan laundry secara online, khususnya bagi pelaku usaha laundry kecil hingga menengah. Aplikasi ini mendukung proses pemesanan jasa laundry oleh pelanggan serta pengelolaan pesanan, pengeluaran, dan laporan oleh admin.

---

## 📱 Fitur Utama

### 👤 **User (Pelanggan)**
- Registrasi dan login menggunakan email & password
- Melakukan pemesanan laundry secara online
- Melihat status pesanan secara real-time
- Melihat riwayat pesanan

### 🧑‍💼 **Admin (Pengelola Laundry)**
- Login sebagai admin
- Mengelola dan memverifikasi data order pelanggan
- Mencatat dan mengedit data pengeluaran
- Mencetak laporan transaksi dan laporan pengeluaran (PDF)

---

## 🛠️ Teknologi yang Digunakan

| Komponen | Teknologi |
|----------|-----------|
| **Frontend** | Flutter (Dart) |
| **Backend** | Firebase (Firestore, Auth, Storage) |
| **Platform** | Android |
| **State Management** | SetState (basic), Provider / GetX (opsional) |
| **PDF Generation** | `pdf` + `printing` package (Flutter) |

---

👥 Tim Pengembang

Muhammad Izzudin Al Faqih	1122140139	Backend Developer (Firebase, integrasi data)
Ardiansyah	1122140155	Frontend Developer (Tampilan UI/UX Flutter)
Budi Prasetyo	1122140096	Data Analyst / SRS Author (Perancang kebutuhan sistem)

---

🚀 Cara Menjalankan Aplikasi

1. Clone repositori ini:

git clone [https://github.com/username/ezlaundry.git cd ezlaundry](https://github.com/Faqih472/Project3Kampus-EZLaundry.git)
cd ezlaundry


2. Install dependencies:

flutter pub get


3. Jalankan di emulator atau perangkat Android:

flutter run


4. Pastikan kamu sudah mengatur Firebase dengan benar:

File google-services.json sudah ada di direktori android/app

Firebase Authentication diaktifkan (Email/Password)

Firestore database sudah terkonfigurasi





---

📦 Dependensi Penting

firebase_core

firebase_auth

cloud_firestore

firebase_storage

flutter_pdfview

pdf

printing



---

📄 Dokumen Terkait

SRS EZLaundry (PDF) 


---

🔒 Lisensi

Proyek ini dikembangkan untuk keperluan akademik dan tidak untuk dikomersialkan tanpa izin semua anggota tim.


---

✨ Catatan Tambahan

> EZLaundry adalah langkah awal digitalisasi layanan laundry, yang dapat terus dikembangkan ke depannya, misalnya dengan penambahan:

Fitur payment gateway (e-wallet)

Dukungan multiplatform (iOS/web)

Integrasi notifikasi (Firebase Messaging)
