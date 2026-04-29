import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../core/services/storage_service.dart';
import '../../core/theme/theme_cubit.dart';
import '../../models/device_model.dart';
import '../../models/mqtt_settings.dart';
import '../setup/device_scan_screen.dart';

class SettingsScreenResult {
  final bool reloadConfiguration;
  final DeviceModel? nextDevice;

  const SettingsScreenResult._({
    required this.reloadConfiguration,
    required this.nextDevice,
  });

  const SettingsScreenResult.reload()
      : this._(reloadConfiguration: true, nextDevice: null);

  const SettingsScreenResult.switchDevice(DeviceModel device)
      : this._(reloadConfiguration: true, nextDevice: device);
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _telemetryTopicController;
  late final TextEditingController _commandTopicController;
  late final TextEditingController _batteryThresholdController;
  late final TextEditingController _offlineMinutesController;
  bool _useTls = false;
  List<DeviceModel> _devices = const <DeviceModel>[];
  String? _selectedDeviceId;

  StorageService get _storage => GetIt.instance<StorageService>();

  DeviceModel? get _selectedDevice {
    if (_selectedDeviceId == null) {
      return null;
    }
    return _storage.getDevice(_selectedDeviceId!);
  }

  @override
  void initState() {
    super.initState();
    final settings = _storage.getMqttSettings();
    _hostController = TextEditingController(text: settings.host);
    _portController = TextEditingController(text: settings.port.toString());
    _usernameController = TextEditingController(text: settings.username);
    _passwordController = TextEditingController(text: settings.password);
    _telemetryTopicController = TextEditingController(
      text: settings.telemetryTopicTemplate,
    );
    _commandTopicController = TextEditingController(
      text: settings.commandTopicTemplate,
    );
    _batteryThresholdController = TextEditingController(
      text: settings.batteryAlertThreshold.toString(),
    );
    _offlineMinutesController = TextEditingController(
      text: settings.offlineThresholdMinutes.toString(),
    );
    _useTls = settings.useTls;
    _loadDevices();
  }

  void _loadDevices() {
    _devices = _storage.getDevices();
    _selectedDeviceId = _storage.getActiveDeviceId() ??
        (_devices.isEmpty ? null : _devices.first.deviceId);
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _telemetryTopicController.dispose();
    _commandTopicController.dispose();
    _batteryThresholdController.dispose();
    _offlineMinutesController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final settings = MqttSettings.defaults().copyWith(
      host: _hostController.text.trim(),
      port: int.parse(_portController.text.trim()),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      useTls: _useTls,
      telemetryTopicTemplate: _telemetryTopicController.text.trim(),
      commandTopicTemplate: _commandTopicController.text.trim(),
      batteryAlertThreshold: int.parse(_batteryThresholdController.text.trim()),
      offlineThresholdMinutes: int.parse(_offlineMinutesController.text.trim()),
    );

    await _storage.saveMqttSettings(settings);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengaturan MQTT berhasil disimpan')),
    );
    Navigator.pop(context, const SettingsScreenResult.reload());
  }

  Future<void> _openDeviceEditor({DeviceModel? device}) async {
    final savedDevice = await Navigator.push<DeviceModel>(
      context,
      MaterialPageRoute(
        builder: (_) => DeviceScanScreen(
          existingDevice: device,
          returnResultOnly: true,
        ),
      ),
    );

    if (!mounted || savedDevice == null) {
      return;
    }

    Navigator.pop(context, SettingsScreenResult.switchDevice(savedDevice));
  }

  Future<void> _switchActiveDevice() async {
    final selectedDevice = _selectedDevice;
    if (selectedDevice == null) {
      return;
    }

    await _storage.setActiveDevice(selectedDevice.deviceId);
    if (!mounted) {
      return;
    }
    Navigator.pop(context, SettingsScreenResult.switchDevice(selectedDevice));
  }

  Future<void> _resetDevice() async {
    final selectedDevice = _selectedDevice;
    if (selectedDevice == null) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus perangkat?'),
        content: Text(
          'Riwayat telemetry dan log untuk ${selectedDevice.name} akan dihapus dari aplikasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    await _storage.deleteDevice(selectedDevice.deviceId);
    final nextDevice = _storage.getActiveDevice();
    if (!mounted) {
      return;
    }

    if (nextDevice == null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DeviceScanScreen()),
        (_) => false,
      );
      return;
    }

    Navigator.pop(context, SettingsScreenResult.switchDevice(nextDevice));
  }

  @override
  Widget build(BuildContext context) {
    final activeDevice = _storage.getActiveDevice();
    final selectedDevice = _selectedDevice;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          context.watch<ThemeCubit>().state is ThemeChanged &&
                                  (context.watch<ThemeCubit>().state
                                          as ThemeChanged)
                                      .isDark
                              ? Icons.dark_mode
                              : Icons.light_mode,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Mode Gelap',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    BlocBuilder<ThemeCubit, ThemeState>(
                      builder: (context, state) {
                        bool isDark = false;
                        if (state is ThemeChanged) {
                          isDark = state.isDark;
                        } else if (state is ThemeInitial) {
                          isDark = state.isDark;
                        }
                        return Switch(
                          value: isDark,
                          onChanged: (value) {
                            context.read<ThemeCubit>().setDarkMode(value);
                          },
                          activeThumbColor: Theme.of(context).primaryColor,
                        );
                      },
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
                      'Perangkat',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (_devices.isEmpty)
                      const Text('Belum ada perangkat tersimpan.')
                    else
                      DropdownButtonFormField<String>(
                        key: ValueKey<String?>(_selectedDeviceId),
                        initialValue: _selectedDeviceId,
                        decoration: const InputDecoration(
                          labelText: 'Perangkat tersimpan',
                        ),
                        items: _devices
                            .map(
                              (device) => DropdownMenuItem<String>(
                                value: device.deviceId,
                                child: Text('${device.name} (${device.deviceId})'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedDeviceId = value);
                        },
                      ),
                    const SizedBox(height: 12),
                    if (selectedDevice != null)
                      Text(
                        activeDevice?.deviceId == selectedDevice.deviceId
                            ? 'Perangkat aktif saat ini.'
                            : 'Pilih "Gunakan perangkat ini" untuk berpindah.',
                      ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: selectedDevice == null ||
                                  activeDevice?.deviceId == selectedDevice.deviceId
                              ? null
                              : _switchActiveDevice,
                          icon: const Icon(Icons.swap_horiz),
                          label: const Text('Gunakan perangkat ini'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _openDeviceEditor(device: selectedDevice),
                          icon: const Icon(Icons.edit),
                          label: Text(
                            selectedDevice == null
                                ? 'Tambah perangkat'
                                : 'Edit perangkat',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _openDeviceEditor(),
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah baru'),
                        ),
                        TextButton.icon(
                          onPressed: selectedDevice == null ? null : _resetDevice,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Hapus perangkat'),
                        ),
                      ],
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
                      'Broker MQTT',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _hostController,
                      decoration: const InputDecoration(labelText: 'Host'),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Host wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _portController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Port'),
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
                      value: _useTls,
                      onChanged: (value) => setState(() => _useTls = value),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
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
                      'Topic & Notifikasi',
                      style: Theme.of(context).textTheme.titleMedium,
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
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _batteryThresholdController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Batas notifikasi baterai (%)',
                      ),
                      validator: (value) {
                        final threshold = int.tryParse(value ?? '');
                        if (threshold == null ||
                            threshold < 1 ||
                            threshold > 100) {
                          return 'Isi antara 1 sampai 100';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _offlineMinutesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Batas offline (menit)',
                      ),
                      validator: (value) {
                        final minutes = int.tryParse(value ?? '');
                        if (minutes == null || minutes < 1) {
                          return 'Minimal 1 menit';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text('Simpan Pengaturan'),
            ),
          ],
        ),
      ),
    );
  }
}
