import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_provider.g.dart';

enum AppTheme { light, dark, system }

@riverpod
class AppThemeNotifier extends _$AppThemeNotifier {
  @override
  AppTheme build() => AppTheme.system;

  void setTheme(AppTheme theme) => state = theme;

  void toggleTheme() {
    state = (state == AppTheme.light) ? AppTheme.dark : AppTheme.light;
  }
}

@riverpod
ThemeMode appThemeMode(AppThemeModeRef ref) {
  final theme = ref.watch(appThemeNotifierProvider);
  switch (theme) {
    case AppTheme.light: return ThemeMode.light;
    case AppTheme.dark: return ThemeMode.dark;
    case AppTheme.system: return ThemeMode.system;
  }
}

// FIXED: Using the lowercase generated name for the alias.
// In Riverpod 2.0, the variable is always lowercase.
final themeProvider = appThemeNotifierProvider;