import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/theme_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Card Tema
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        context.watch<ThemeCubit>().state is ThemeChanged &&
                                (context.watch<ThemeCubit>().state as ThemeChanged).isDark
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
                        onChanged: (val) {
                          context.read<ThemeCubit>().setDarkMode(val);
                        },
                        activeColor: Theme.of(context).primaryColor,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Informasi Aplikasi
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Versi Aplikasi'),
                  trailing: const Text('1.0.0'),
                  onTap: () {},
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Kebijakan Privasi'),
                  onTap: () {},
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.contact_support_outlined),
                  title: const Text('Hubungi Kami'),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}