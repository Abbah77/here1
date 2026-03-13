import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:workmanager/workmanager.dart';

// Package Imports - Absolute paths ensure stability
import 'package:here/core/providers/theme_provider.dart';
import 'package:here/core/providers/sync_provider.dart'; // Ensure correct sync provider import
import 'package:here/core/guards/auth_guard.dart';
import 'package:here/features/home/views/screens/main_screen.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final container = ProviderContainer();
    try {
      // FIXED: Using the likely generated provider name from sync_provider.dart
      final syncService = container.read(syncProvider.notifier);
      
      if (task == 'syncMessages') {
        await syncService.syncMessages();
      } else if (task == 'syncFeed') {
        await syncService.syncFeed();
      }
      return true;
    } catch (e) {
      debugPrint('Background Task Error: $e');
      return false;
    } finally {
      container.dispose();
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Background Service Setup
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  
  Workmanager().registerPeriodicTask(
    'syncMessages',
    'syncMessages',
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
  );
  
  // UI Constraints
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // FIXED: Watch the specific provider that returns ThemeMode (not AppTheme)
    // This matches the appThemeModeProvider we defined in theme_provider.dart
    final themeMode = ref.watch(appThemeModeProvider);

    return MaterialApp(
      title: 'Social Network',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode, // Now receives ThemeMode.light/dark/system
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3), 
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.dark,
        ),
      ),
      home: const AuthGuard(child: MainScreen()),
    );
  }
}
