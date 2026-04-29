# PestMist Control

Aplikasi Flutter untuk mengontrol perangkat PestMist berbasis ESP32 melalui MQTT.

## Fitur

- Monitoring status lampu UV dari telemetry perangkat
- Kontrol semprot pompa berdurasi 5/10/15 detik
- Monitoring kapasitas baterai
- Penjadwalan UV harian
- Indikator `last seen` / terakhir sinkronisasi
- Log aktivitas dan grafik historis baterai
- Notifikasi baterai rendah dan perangkat offline
- Penyimpanan banyak perangkat dan pergantian perangkat aktif
- Provisioning WiFi perangkat lewat BLE saat ESP32 berada di mode setup

## Alur Aplikasi

1. Registrasikan `deviceId` dan konfigurasi broker MQTT.
2. Jika perangkat belum punya WiFi, aplikasi dapat mengirim `ssid` dan `pass` lewat BLE setup.
3. Aplikasi subscribe ke topic telemetry perangkat.
4. Dashboard dipakai untuk menjalankan semprot pompa, mengatur jadwal UV, dan melihat status sinkronisasi.
5. Riwayat telemetry dan log disimpan terpisah per perangkat.

## Catatan Integrasi Firmware

- Default topic telemetry: `tanisolution/{deviceId}/telemetry`
- Default topic command: `tanisolution/{deviceId}/command`
- Placeholder `{deviceId}` bisa diubah dari menu pengaturan.
- BLE setup firmware menggunakan nama perangkat `Alburdat_Setup_{deviceId}`.
- BLE service UUID: `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
- BLE characteristic UUID: `beb5483e-36e1-4688-b7f5-ea07361b26a8`
- Firmware menerima perintah pompa berdurasi melalui key `pump_action` dan `duration_sec`.
- Firmware menerima update jadwal UV melalui key `uv_start` dan `uv_stop`.
- Payload telemetry yang didukung fleksibel, misalnya:

```json
{
  "bat": 87,
  "uv": 1,
  "pump": 0,
  "is_night": true,
  "time": "2026-04-29T10:15:00Z"
}
```

## Sebelum Menjalankan

- Jalankan `flutter pub get` setelah perubahan dependensi.
- Jika model firmware memakai key JSON berbeda, sesuaikan parser di `lib/models/telemetry_model.dart`.
