import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'core/constants/app_constants.dart';
import 'core/services/ble_provisioning_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/theme_cubit.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';

final getIt = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  final storage = StorageService();
  await storage.init();
  getIt.registerSingleton<StorageService>(storage);
  getIt.registerLazySingleton<BleProvisioningService>(
    BleProvisioningService.new,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ThemeCubit(),
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          ThemeData currentTheme;
          if (themeState is ThemeChanged) {
            currentTheme = themeState.themeData;
          } else if (themeState is ThemeInitial) {
            currentTheme = themeState.themeData;
          } else {
            currentTheme = AppTheme.lightTheme;
          }
          return MaterialApp(
            title: AppConstants.appName,
            theme: currentTheme,
            debugShowCheckedModeBanner: false,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
