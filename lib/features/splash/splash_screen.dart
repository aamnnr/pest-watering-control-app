import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'splash_cubit.dart';
import '../setup/device_scan_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../../core/services/storage_service.dart';
import '../../models/device_model.dart';
import '../../core/services/mqtt_service.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SplashCubit(GetIt.instance<StorageService>())..checkDevice(),
      child: BlocListener<SplashCubit, SplashState>(
        listener: (context, state) {
          if (state is SplashNoDevice) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DeviceScanScreen()),
            );
          } else if (state is SplashHasDevice) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DashboardScreen(device: state.device),
              ),
            );
          }
        },
        child: const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FlutterLogo(size: 100),
                SizedBox(height: 24),
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('TaniSolution', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}