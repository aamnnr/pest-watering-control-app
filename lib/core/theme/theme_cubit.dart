import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  static const String themePrefKey = 'is_dark_mode';
  
  ThemeCubit() : super(ThemeInitial(themeData: AppTheme.lightTheme, isDark: false)) {
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(themePrefKey) ?? false;
    emit(ThemeChanged(
      themeData: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      isDark: isDark,
    ));
  }

  Future<void> toggleTheme() async {
    final currentState = state;
    bool newIsDark;
    if (currentState is ThemeChanged) {
      newIsDark = !currentState.isDark;
    } else if (currentState is ThemeInitial) {
      newIsDark = !currentState.isDark;
    } else {
      newIsDark = false;
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(themePrefKey, newIsDark);
    
    emit(ThemeChanged(
      themeData: newIsDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      isDark: newIsDark,
    ));
  }

  void setDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(themePrefKey, isDark);
    emit(ThemeChanged(
      themeData: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      isDark: isDark,
    ));
  }
}