import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../core/services/ble_service.dart';

class DeviceScanScreen extends StatefulWidget {
  const DeviceScanScreen({super.key});

  @override
  State<DeviceScanScreen> createState() => _DeviceScanScreenState();
}

class _DeviceScanScreenState extends State<DeviceScanScreen> {
  final BleService ble = BleService();
  List<BluetoothDevice> devices = [];
  bool scanning = false;

  @override
  void initState() {
    super.initState();
    scan();
  }

  Future<void> scan() async {
    if (!mounted) return;
    setState(() => scanning = true);
    final results = await ble.scanDevices();
    if (mounted) {
      setState(() {
        devices = results;
        scanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cari Perangkat TaniSolution')),
      body: scanning
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Memindai perangkat BLE...')],
            ))
          : devices.isEmpty
              ? const Center(child: Text('Tidak ditemukan perangkat. Pastikan ESP32 dalam mode setup.'))
              : ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (_, i) => ListTile(
                    leading: const Icon(Icons.bluetooth),
                    title: Text(devices[i].platformName),
                    subtitle: Text(devices[i].remoteId.toString()),
                    onTap: () => _showWifiDialog(devices[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: scan,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  void _showWifiDialog(BluetoothDevice device) {
    showDialog(
      context: context,
      builder: (_) => WifiCredentialsDialog(device: device, ble: ble),
    );
  }
}

class WifiCredentialsDialog extends StatefulWidget {
  final BluetoothDevice device;
  final BleService ble;
  const WifiCredentialsDialog({super.key, required this.device, required this.ble});

  @override
  State<WifiCredentialsDialog> createState() => _WifiCredentialsDialogState();
}

class _WifiCredentialsDialogState extends State<WifiCredentialsDialog> {
  final _ssidCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Konfigurasi WiFi'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _ssidCtrl, decoration: const InputDecoration(labelText: 'Nama WiFi (SSID)')),
          const SizedBox(height: 8),
          TextField(controller: _passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: _loading ? null : () async {
            setState(() => _loading = true);
            await widget.ble.sendWifiCredentials(widget.device, _ssidCtrl.text, _passCtrl.text);
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pengaturan dikirim. ESP32 akan restart dan terhubung.')),
              );
              // Kembali ke splash screen setelah delay
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
              });
            }
          },
          child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Kirim'),
        ),
      ],
    );
  }
}