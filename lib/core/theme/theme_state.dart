part of 'theme_cubit.dart';

abstract class ThemeState extends Equatable {
  const ThemeState();
  @override
  List<Object> get props => [];
}

class ThemeInitial extends ThemeState {
  final ThemeData themeData;
  final bool isDark;
  const ThemeInitial({required this.themeData, required this.isDark});
  @override
  List<Object> get props => [themeData, isDark];
}

class ThemeChanged extends ThemeState {
  final ThemeData themeData;
  final bool isDark;
  const ThemeChanged({required this.themeData, required this.isDark});
  @override
  List<Object> get props => [themeData, isDark];
}