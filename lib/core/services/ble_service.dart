import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:typed_data';
import 'dart:convert';

class BleService {
  static const String serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const String charUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';

  Future<List<BluetoothDevice>> scanDevices() async {
    List<BluetoothDevice> devices = [];
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    final subscription = FlutterBluePlus.scanResults.listen((results) {
      for (var result in results) {
        if (result.device.platformName.startsWith('Alburdat_Setup_')) {
          if (!devices.contains(result.device)) devices.add(result.device);
        }
      }
    });
    await Future.delayed(const Duration(seconds: 10));
    await FlutterBluePlus.stopScan();
    await subscription.cancel();
    return devices;
  }

  Future<void> sendWifiCredentials(BluetoothDevice device, String ssid, String password) async {
    await device.connect();
    await device.discoverServices();
    
    // Gunakan await karena services adalah Stream
    final services = await device.services;
    BluetoothCharacteristic? targetChar;
    
    for (var service in services) {
      if (service.uuid.toString() == serviceUuid) {
        for (var char in service.characteristics) {
          if (char.uuid.toString() == charUuid) {
            targetChar = char;
            break;
          }
        }
        break;
      }
    }
    
    if (targetChar == null) throw Exception('Characteristic not found');
    final json = {'ssid': ssid, 'pass': password};
    final data = Uint8List.fromList(utf8.encode(jsonEncode(json)));
    await targetChar.write(data);
    await device.disconnect();
  }
}