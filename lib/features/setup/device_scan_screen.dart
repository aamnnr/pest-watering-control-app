import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/ble_provisioning_service.dart';
import '../../models/device_model.dart';
import '../../models/mqtt_settings.dart';
import '../dashboard/dashboard_screen.dart';
import 'ble_provision_screen.dart';

class DeviceScanScreen extends StatefulWidget {
  final DeviceModel? existingDevice;
  final bool returnResultOnly;

  const DeviceScanScreen({
    super.key,
    this.existingDevice,
    this.returnResultOnly = false,
  });

  @override
  State<DeviceScanScreen> createState() => _DeviceScanScreenState();
}

class _DeviceScanScreenState extends State<DeviceScanScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _deviceNameController;
  late final TextEditingController _deviceIdController;
  late final TextEditingController _brokerController;
  late final TextEditingController _portController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _telemetryTopicController;
  late final TextEditingController _commandTopicController;
  late final TextEditingController _wifiSsidController;
  late final TextEditingController _wifiPasswordController;
  bool _useTls = false;
  bool _saving = false;
  BleProvisioningResult? _lastProvisioningResult;

  @override
  void initState() {
    super.initState();
    final storage = GetIt.instance<StorageService>();
    final baseDevice = widget.existingDevice ?? storage.getActiveDevice();
    final settings = storage.getMqttSettings();

    _deviceNameController = TextEditingController(
      text: baseDevice?.name ?? 'PestMist Trap 1',
    );
    _deviceIdController = TextEditingController(
      text: baseDevice?.deviceId ?? 'esp32-trap-01',
    );
    _brokerController = TextEditingController(text: settings.host);
    _portController = TextEditingController(text: settings.port.toString());
    _usernameController = TextEditingController(text: settings.username);
    _passwordController = TextEditingController(text: settings.password);
    _telemetryTopicController = TextEditingController(
      text: settings.telemetryTopicTemplate,
    );
    _commandTopicController = TextEditingController(
      text: settings.commandTopicTemplate,
    );
    _wifiSsidController = TextEditingController();
    _wifiPasswordController = TextEditingController();
    _useTls = settings.useTls;
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    _deviceIdController.dispose();
    _brokerController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _telemetryTopicController.dispose();
    _commandTopicController.dispose();
    _wifiSsidController.dispose();
    _wifiPasswordController.dispose();
    super.dispose();
  }

  Future<void> _openBleProvisioning() async {
    final ssid = _wifiSsidController.text.trim();
    if (ssid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SSID WiFi wajib diisi untuk provisioning BLE')),
      );
      return;
    }

    final result = await Navigator.push<BleProvisioningResult>(
      context,
      MaterialPageRoute(
        builder: (_) => BleProvisionScreen(
          ssid: ssid,
          password: _wifiPasswordController.text,
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _lastProvisioningResult = result;
      _deviceIdController.text = result.deviceId;
      if (_deviceNameController.text.trim().isEmpty ||
          _deviceNameController.text.trim() == 'PestMist Trap 1') {
        _deviceNameController.text = 'PestMist Trap ${result.deviceId}';
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Provisioning BLE berhasil untuk device ${result.deviceId}.',
        ),
      ),
    );
  }

  Future<void> _saveDeviceConfiguration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);
    final storage = GetIt.instance<StorageService>();
    final previousDevice = widget.existingDevice ?? storage.getActiveDevice();

    final device = DeviceModel(
      deviceId: _deviceIdController.text.trim(),
      name: _deviceNameController.text.trim(),
      lastSeen: previousDevice?.lastSeen ??
          DateTime.now().subtract(const Duration(days: 1)),
      lastBattery: previousDevice?.lastBattery ?? 0,
      uvStartHour: previousDevice?.uvStartHour ?? 18,
      uvEndHour: previousDevice?.uvEndHour ?? 23,
    );

    final mqttSettings = MqttSettings.defaults().copyWith(
      host: _brokerController.text.trim(),
      port: int.tryParse(_portController.text.trim()) ??
          MqttSettings.defaults().port,
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      useTls: _useTls,
      telemetryTopicTemplate: _telemetryTopicController.text.trim(),
      commandTopicTemplate: _commandTopicController.text.trim(),
    );

    if (widget.existingDevice != null &&
        widget.existingDevice!.deviceId != device.deviceId) {
      await storage.deleteDevice(widget.existingDevice!.deviceId);
    }

    await storage.saveDevice(device);
    await storage.saveMqttSettings(mqttSettings);

    if (!mounted) {
      return;
    }

    if (widget.returnResultOnly) {
      Navigator.pop(context, device);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => DashboardScreen(device: device)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingDevice != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Perangkat MQTT' : 'Daftarkan Perangkat MQTT',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Isi identitas perangkat ESP32 dan konfigurasi broker MQTT '
                      'yang digunakan firmware.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Provisioning WiFi via BLE',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Gunakan bagian ini saat ESP32 baru dinyalakan dan belum punya konfigurasi WiFi. Firmware akan muncul sebagai BLE bernama Alburdat_Setup_xxxx.',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _wifiSsidController,
                      decoration: const InputDecoration(
                        labelText: 'SSID WiFi',
                        hintText: 'Nama jaringan WiFi',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _wifiPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Password WiFi',
                        hintText: 'Kosongkan jika jaringan terbuka',
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _openBleProvisioning,
                      icon: const Icon(Icons.bluetooth_searching),
                      label: const Text('Scan dan Provision via BLE'),
                    ),
                    if (_lastProvisioningResult != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Terakhir terprovisi: ${_lastProvisioningResult!.bleName}\nDevice ID: ${_lastProvisioningResult!.deviceId}',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Identitas Perangkat',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _deviceNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama perangkat',
                        hintText: 'Contoh: Trap Gudang A',
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Nama perangkat wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _deviceIdController,
                      decoration: const InputDecoration(
                        labelText: 'Device ID',
                        hintText: 'Harus sama dengan ID di firmware',
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Device ID wajib diisi'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Konfigurasi MQTT',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _brokerController,
                      decoration: const InputDecoration(
                        labelText: 'Broker host',
                        hintText: 'broker.hivemq.com',
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Broker host wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _portController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Port',
                        hintText: '1883',
                      ),
                      validator: (value) {
                        final port = int.tryParse(value ?? '');
                        if (port == null || port <= 0) {
                          return 'Port tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Gunakan TLS / SSL'),
                      subtitle: const Text(
                        'Aktifkan jika broker memakai koneksi terenkripsi.',
                      ),
                      value: _useTls,
                      onChanged: (value) => setState(() => _useTls = value),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username broker',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password broker',
                      ),
                      obscureText: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Template Topic',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Gunakan placeholder {deviceId} agar topic menyesuaikan '
                      'ID perangkat secara otomatis.',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _telemetryTopicController,
                      decoration: const InputDecoration(
                        labelText: 'Topic telemetry',
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Topic telemetry wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _commandTopicController,
                      decoration: const InputDecoration(
                        labelText: 'Topic command',
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Topic command wajib diisi'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _saving ? null : _saveDeviceConfiguration,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Menyimpan...' : 'Simpan dan Lanjutkan'),
            ),
          ],
        ),
      ),
    );
  }
}
