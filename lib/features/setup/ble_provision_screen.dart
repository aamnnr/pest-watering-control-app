import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/services/ble_provisioning_service.dart';

class BleProvisionScreen extends StatefulWidget {
  final String ssid;
  final String password;

  const BleProvisionScreen({
    super.key,
    required this.ssid,
    required this.password,
  });

  @override
  State<BleProvisionScreen> createState() => _BleProvisionScreenState();
}

class _BleProvisionScreenState extends State<BleProvisionScreen> {
  final BleProvisioningService _bleService =
      GetIt.instance<BleProvisioningService>();

  final List<BleProvisioningDevice> _devices = [];

  StreamSubscription<List<BleProvisioningDevice>>? _scanSubscription;

  bool _loading = true;
  bool _provisioning = false;
  String? _errorMessage;
  BleProvisioningDevice? _selectedDevice;

  @override
  void initState() {
    super.initState();

    _scanSubscription = _bleService.scanResults.listen((devices) {
      if (!mounted) return;

      setState(() {
        _devices
          ..clear()
          ..addAll(devices);
      });
    });

    _startScan();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    unawaited(_bleService.stopScan());
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await _bleService.startScan();
    } on BleProvisioningException catch (error) {
      if (!mounted) return;

      setState(() => _errorMessage = error.message);

      if (error.canOpenSettings) {
        await openAppSettings();
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Gagal memulai scan BLE: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _provisionSelectedDevice() async {
    final device = _selectedDevice;
    if (device == null) return;

    setState(() {
      _provisioning = true;
      _errorMessage = null;
    });

    try {
      final result = await _bleService.provisionWifi(
        target: device,
        ssid: widget.ssid,
        password: widget.password,
      );

      if (!mounted) return;
      Navigator.pop(context, result);
    } on BleProvisioningException catch (error) {
      if (!mounted) return;

      setState(() => _errorMessage = error.message);

      if (error.canOpenSettings) {
        await openAppSettings();
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Gagal mengirim konfigurasi BLE: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _provisioning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provisioning BLE'),
        actions: [
          IconButton(
            onPressed: _loading || _provisioning ? null : _startScan,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // INFO CARD
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WiFi tujuan',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('SSID: ${widget.ssid}'),
                  Text(
                    widget.password.isEmpty
                        ? 'Password: jaringan terbuka'
                        : 'Password: ${'*' * widget.password.length}',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pilih perangkat BLE untuk mengirim konfigurasi WiFi ke firmware.',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ERROR
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          // LOADING
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )

          // EMPTY STATE
          else if (_devices.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Belum ada perangkat BLE ditemukan.'),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _startScan,
                      icon: const Icon(Icons.bluetooth_searching),
                      label: const Text('Scan Ulang'),
                    ),
                  ],
                ),
              ),
            )

          // DEVICE LIST (MODERN CLEAN UI)
          else
            Card(
              child: Column(
                children: _devices.map((device) {
                  final selected = device == _selectedDevice;

                  return ListTile(
                    title: Text(device.displayName),
                    subtitle: Text(
                      'Device ID: ${device.deviceId}\nBLE ID: ${device.remoteId}',
                    ),

                    // indikator selected (tanpa Radio widget)
                    leading: Icon(
                      selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: selected ? Theme.of(context).primaryColor : null,
                    ),

                    onTap: _provisioning
                        ? null
                        : () {
                            setState(() => _selectedDevice = device);
                          },

                    selected: selected,
                  );
                }).toList(),
              ),
            )
        ],
      ),

      // BOTTOM BUTTON
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: (_provisioning || _selectedDevice == null)
              ? null
              : _provisionSelectedDevice,
          icon: _provisioning
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: Text(
            _provisioning
                ? 'Mengirim...'
                : 'Kirim WiFi ke Perangkat',
          ),
        ),
      ),
    );
  }
}