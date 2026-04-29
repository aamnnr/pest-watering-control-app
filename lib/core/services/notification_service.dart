import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const String _batteryChannelId = 'battery_channel';
  static const String _offlineChannelId = 'offline_channel';
  static const String _statusChannelId = 'status_channel';

  static Future<void> init() async {
    await Permission.notification.request();
    
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
        
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // PERUBAHAN: Sekarang menggunakan named parameter 'settings'
    await _plugin.initialize(settings: settings);
  }

  static Future<void> showBatteryWarning(int batteryLevel) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _batteryChannelId,
      'Peringatan Baterai',
      importance: Importance.high,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // PERUBAHAN: Menggunakan named parameters (id, title, body, notificationDetails)
    await _plugin.show(
      id: 0,
      title: 'Baterai Lemah',
      body: 'Baterai tersisa $batteryLevel%. Segera isi daya.',
      notificationDetails: details,
    );
  }

  static Future<void> showDeviceOffline(
    String deviceId, {
    required int thresholdMinutes,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _offlineChannelId,
      'Status Alat',
      importance: Importance.defaultImportance,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // PERUBAHAN: Menggunakan named parameters
    await _plugin.show(
      id: 1,
      title: 'Perangkat Offline',
      body: 'Perangkat $deviceId tidak mengirim data lebih dari $thresholdMinutes menit.',
      notificationDetails: details,
    );
  }

  static Future<void> showDeviceBackOnline(String deviceId) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _statusChannelId,
      'Sinkronisasi Alat',
      importance: Importance.defaultImportance,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // PERUBAHAN: Menggunakan named parameters
    await _plugin.show(
      id: 2,
      title: 'Perangkat Tersambung Kembali',
      body: 'Perangkat $deviceId kembali mengirim telemetry.',
      notificationDetails: details,
    );
  }
}