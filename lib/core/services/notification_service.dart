import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    await Permission.notification.request();
    const AndroidInitializationSettings android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings ios = DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
  }

  static Future<void> showBatteryWarning(int batteryLevel) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'battery_channel',
      'Peringatan Baterai',
      importance: Importance.high,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await _plugin.show(
      0,
      'Baterai Lemah',
      'Baterai tersisa $batteryLevel%. Segera isi daya.',
      details,
    );
  }

  static Future<void> showDeviceOffline(String deviceId) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'offline_channel',
      'Status Alat',
      importance: Importance.defaultImportance,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await _plugin.show(
      1,
      'Alamat Offline',
      'Perangkat $deviceId tidak mengirim data lebih dari 15 menit.',
      details,
    );
  }
}