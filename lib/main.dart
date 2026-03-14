import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:workmanager/workmanager.dart';

// Ensure these paths match your folder structure perfectly
import 'package:here/core/providers/theme_provider.dart';
import 'package:here/core/providers/sync_provider.dart'; 
import 'package:here/core/widgets/auth_guard.dart'; // Updated path to match widget location
import 'package:here/features/home/views/screens/main_screen.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Create a new container for background tasks
    final container = ProviderContainer();
    try {
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
  // 1. Ensure Flutter is ready
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Initialize Background Service
  try {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    await Workmanager().registerPeriodicTask(
      'syncMessages',
      'syncMessages',
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  } catch (e) {
    debugPrint('Workmanager could not initialize: $e');
  }
  
  // 3. Lock Orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // 4. Run App
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
    // Watch ThemeMode (Light/Dark/System)
    final themeMode = ref.watch(appThemeModeProvider);

    return MaterialApp(
      title: 'Social Network',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode, 
      
      // Light Theme Definition
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3), 
          brightness: Brightness.light,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
      ),
      
      // Dark Theme Definition
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.dark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
      ),
      
      // THE GATEKEEPER: This decides if the user sees Login or Home
      home: const AuthGuard(child: MainScreen()),
    );
  }
}
