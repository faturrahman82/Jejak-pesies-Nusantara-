# Jejak Spesies Nusantara

Aplikasi Flutter untuk menjelajahi catatan kemunculan spesies di Indonesia dari GBIF. Data ditampilkan per halaman agar pencarian tetap ringan. Catatan yang memiliki koordinat dapat dilihat pada peta, sementara favorit disimpan di perangkat.

## Fitur

- Pencarian catatan spesies di Indonesia.
- Kartu berfoto dengan nama ilmiah, nama lokal Indonesia jika tersedia, kelompok, lokasi, dan tanggal.
- Detail klasifikasi, lokasi, koordinat, kategori IUCN, jenis catatan, dataset, sumber, serta kredit dan lisensi foto jika tersedia.
- Peta marker dari catatan yang sudah dimuat dan memiliki koordinat.
- Favorit lokal yang tetap tersedia setelah aplikasi dibuka kembali.
- Loading, error, hasil kosong, tarik untuk memuat ulang, dan pagination.

## Teknologi

- Flutter dan Dart.
- API Jejak Spesies Nusantara buatan sendiri sebagai perantara GBIF. API mengunci pencarian ke Indonesia, membatasi pagination, menyediakan filter provinsi, dan menyimpan cache respons selama 45 detik.
- GBIF Occurrence API sebagai sumber catatan dan GBIF Species API untuk nama lokal Indonesia.
- `http` untuk permintaan API, `flutter_map` dan `latlong2` untuk peta, `cached_network_image` untuk foto, `shared_preferences` untuk ID favorit, `intl` untuk tanggal Indonesia, dan `url_launcher` untuk tautan sumber.
- Peta menggunakan tile OpenStreetMap dan menampilkan atribusinya.

GBIF menyediakan catatan dari banyak sumber. Setiap catatan dapat memiliki field yang berbeda; informasi yang tidak tersedia tidak ditampilkan. Foto tetap mengikuti lisensi dan atribusi yang diberikan sumbernya.

## Menjalankan aplikasi

1. Pasang Flutter SDK dan Dart SDK, lalu siapkan emulator Android atau perangkat.
2. Dari folder project jalankan `dart run api/bin/server.dart` untuk menyalakan API lokal.
3. Di terminal lain, jalankan `flutter pub get`, lalu `flutter run`.

Aplikasi secara bawaan langsung memakai GBIF agar tidak bergantung pada server lokal. Untuk memakai API sendiri, tentukan SPECIES_API_BASE_URL. Emulator Android menggunakan http://10.0.2.2:8080/api, web menggunakan http://localhost:8080/api. Untuk perangkat fisik, gunakan alamat IP komputer:

```sh
flutter run --dart-define=SPECIES_API_BASE_URL=http://192.168.1.10:8080/api
```

Ganti `192.168.1.10` dengan alamat IP komputer pada jaringan Wi-Fi yang sama.

### Endpoint API

- `GET /api/health` — status server.
- `GET /api/occurrence/search?q=belangkas&offset=0&limit=20` — pencarian catatan di Indonesia.
- `GET /api/occurrence/search?q=burung&stateProvince=Jawa%20Timur` — pencarian berdasarkan provinsi.
- `GET /api/provinces?q=jawa` — saran provinsi dari GBIF.
- `GET /api/occurrence/{gbifId}` — detail catatan.
- `GET /api/species/{speciesKey}/vernacularNames` — nama lokal dari GBIF Species API.

## Menjalankan pemeriksaan

Jalankan `flutter analyze` dan `flutter test` dari folder project. Test memakai respons API simulasi agar tidak bergantung pada koneksi internet atau layanan GBIF.
