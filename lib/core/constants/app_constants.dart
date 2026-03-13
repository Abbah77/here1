import 'package:flutter/material.dart';

class AppConstants {
  // Database
  static const String databaseName = 'social_network_encrypted.db';
  static const int databaseVersion = 1;
  
  // Pagination
  static const int messagesPerChat = 100;
  static const int feedPageSize = 20;
  
  // Media Limits
  static const int thumbnailMaxWidth = 200;
  static const int thumbnailMaxHeight = 200;
  static const int thumbnailQuality = 85;
  static const int videoPreviewMaxDurationSeconds = 15;
  static const int videoPreviewMaxSizeMB = 1;
  
  // Cache Limits
  static const int maxCacheSizeMB = 100;
  static const int maxPostsInViewCache = 50;
  
  // Sync
  static const int syncIntervalMinutes = 15;
  static const int maxSyncRetries = 3;
  static const Duration syncRetryDelay = Duration(seconds: 30);
  
  // Message Status
  static const String messageStatusPending = 'pending';
  static const String messageStatusSending = 'sending'; // ADDED: Missing constant
  static const String messageStatusSent = 'sent';
  static const String messageStatusDelivered = 'delivered';
  static const String messageStatusRead = 'read';
  
  // Heat Score Decay
  static const double heatDecayFactor = 0.5; // Exponential decay
  static const Duration heatTimeUnit = Duration(hours: 1);
}

class AppColors {
  // Primary Colors - Clean & Modern
  static const Color primary = Color(0xFF2563EB); // Vibrant Blue
  static const Color secondary = Color(0xFF7C3AED); // Purple
  static const Color accent = Color(0xFFF59E0B); // Amber
  
  // Neutrals - FIXED: Replaced deprecated 'background' with 'surface'
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color surfaceDark = Color(0xFF1E293B);
  
  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);
  
  // Status
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  
  // Message Ticks
  static const Color tickPending = Color(0xFF94A3B8);
  static const Color tickSent = Color(0xFF64748B);
  static const Color tickDelivered = Color(0xFF3B82F6);
  static const Color tickRead = Color(0xFF10B981);
}

class AppTheme {
  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        surfaceContainerHighest: AppColors.backgroundLight, // FIXED: Replaced deprecated surfaceVariant
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.textHint),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.textHint.withValues(alpha: 0.2)), // FIXED: Replaced withOpacity
        ),
        clipBehavior: Clip.antiAlias,
      ),
    );
  }

  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceDark,
        surfaceContainerHighest: Color(0xFF334155), // FIXED: Replaced deprecated surfaceVariant
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF334155),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: const TextStyle(color: AppColors.textHint),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)), // FIXED: Replaced withOpacity
        ),
        clipBehavior: Clip.antiAlias,
      ),
    );
  }
}