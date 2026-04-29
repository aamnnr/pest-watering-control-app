import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../protocol/firmware_protocol.dart';

class BleProvisioningException implements Exception {
  final String message;
  final bool canOpenSettings;

  const BleProvisioningException(
    this.message, {
    this.canOpenSettings = false,
  });

  @override
  String toString() => message;
}

class BleProvisioningDevice extends Equatable {
  final String remoteId;
  final String bleName;
  final String deviceId;

  const BleProvisioningDevice({
    required this.remoteId,
    required this.bleName,
    required this.deviceId,
  });

  String get displayName => bleName.isNotEmpty ? bleName : remoteId;

  @override
  List<Object?> get props => [remoteId, bleName, deviceId];
}

class BleProvisioningResult extends Equatable {
  final String deviceId;
  final String bleName;
  final String remoteId;

  const BleProvisioningResult({
    required this.deviceId,
    required this.bleName,
    required this.remoteId,
  });

  @override
  List<Object?> get props => [deviceId, bleName, remoteId];
}

class BleProvisioningService {
  static const Duration defaultScanTimeout = Duration(seconds: 10);
  static final Guid _serviceGuid =
      Guid(FirmwareProtocol.bleProvisioningServiceUuid);
  static final Guid _characteristicGuid =
      Guid(FirmwareProtocol.bleProvisioningCharacteristicUuid);

  // Change to License.commercial if your organization uses a commercial FBP license.
  static const License _bleLicense = License.free;

  bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get _isIos => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Stream<List<BleProvisioningDevice>> get scanResults =>
      FlutterBluePlus.scanResults.map(_mapScanResults);

  Future<void> ensureReady() async {
    if (!_isAndroid && !_isIos) {
      throw const BleProvisioningException(
        'Provisioning BLE saat ini difokuskan untuk Android dan iOS.',
      );
    }

    final supported = await FlutterBluePlus.isSupported;
    if (!supported) {
      throw const BleProvisioningException(
        'Perangkat ini tidak mendukung Bluetooth Low Energy.',
      );
    }

    await _requestPermissions();

    if (_isAndroid && FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
      try {
        await FlutterBluePlus.turnOn();
      } catch (_) {
        // User may reject the system request. We validate below.
      }
    }

    final state = await FlutterBluePlus.adapterState.firstWhere(
      (value) => value != BluetoothAdapterState.unknown,
      orElse: () => FlutterBluePlus.adapterStateNow,
    );

    if (state != BluetoothAdapterState.on) {
      throw const BleProvisioningException(
        'Bluetooth belum aktif. Nyalakan Bluetooth lalu coba lagi.',
      );
    }
  }

  Future<void> _requestPermissions() async {
    final permissions = <Permission>[
      Permission.bluetooth,
      if (_isAndroid) ...[
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ],
    ];

    final statuses = await permissions.request();
    final deniedPermanently = statuses.values.any(
      (status) => status.isPermanentlyDenied,
    );
    if (deniedPermanently) {
      throw const BleProvisioningException(
        'Izin Bluetooth ditolak permanen. Buka pengaturan aplikasi untuk mengaktifkannya.',
        canOpenSettings: true,
      );
    }

    final notGranted = statuses.values.any((status) => !status.isGranted);
    if (notGranted) {
      throw const BleProvisioningException(
        'Izin Bluetooth belum diberikan.',
      );
    }
  }

  Future<void> startScan({
    Duration timeout = defaultScanTimeout,
  }) async {
    await ensureReady();
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }

    await FlutterBluePlus.startScan(
      withServices: <Guid>[_serviceGuid],
      timeout: timeout,
    );
  }

  Future<void> stopScan() async {
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }
  }

  Future<BleProvisioningResult> provisionWifi({
    required BleProvisioningDevice target,
    required String ssid,
    required String password,
  }) async {
    await ensureReady();
    await stopScan();

    final device = BluetoothDevice.fromId(target.remoteId);
    final payload = utf8.encode(
      jsonEncode(<String, dynamic>{
        'ssid': ssid,
        'pass': password,
      }),
    );

    try {
      await device.connect(
        license: _bleLicense,
        timeout: const Duration(seconds: 20),
      );

      final services = await device.discoverServices();
      final characteristic = _findProvisioningCharacteristic(services);
      if (characteristic == null) {
        throw const BleProvisioningException(
          'Characteristic provisioning BLE tidak ditemukan pada perangkat.',
        );
      }

      await characteristic.write(payload);
      return BleProvisioningResult(
        deviceId: target.deviceId,
        bleName: target.bleName,
        remoteId: target.remoteId,
      );
    } on BleProvisioningException {
      rethrow;
    } catch (error) {
      throw BleProvisioningException(
        'Provisioning BLE gagal: $error',
      );
    } finally {
      if (device.isConnected) {
        try {
          await device.disconnect();
        } catch (_) {
          // Ignore best-effort disconnect after sending provisioning payload.
        }
      }
    }
  }

  List<BleProvisioningDevice> _mapScanResults(List<ScanResult> results) {
    final devices = results
        .map(_toProvisioningDevice)
        .whereType<BleProvisioningDevice>()
        .toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    return devices;
  }

  BleProvisioningDevice? _toProvisioningDevice(ScanResult result) {
    final bleName = _resolveBleName(result);
    final deviceId = FirmwareProtocol.extractDeviceIdFromBleName(bleName);
    if (deviceId == null) {
      return null;
    }

    return BleProvisioningDevice(
      remoteId: result.device.remoteId.str,
      bleName: bleName,
      deviceId: deviceId,
    );
  }

  String _resolveBleName(ScanResult result) {
    final advertisementName = result.advertisementData.advName.trim();
    if (advertisementName.isNotEmpty) {
      return advertisementName;
    }

    final platformName = result.device.platformName.trim();
    if (platformName.isNotEmpty) {
      return platformName;
    }

    final cachedAdvertisementName = result.device.advName.trim();
    if (cachedAdvertisementName.isNotEmpty) {
      return cachedAdvertisementName;
    }

    return result.device.remoteId.str;
  }

  BluetoothCharacteristic? _findProvisioningCharacteristic(
    List<BluetoothService> services,
  ) {
    for (final service in services) {
      if (service.uuid != _serviceGuid) {
        continue;
      }

      for (final characteristic in service.characteristics) {
        if (characteristic.uuid == _characteristicGuid) {
          return characteristic;
        }
      }
    }
    return null;
  }
}
