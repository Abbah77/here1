import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// Note: Ensure these paths match your actual folder structure
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/views/screens/auth_screen.dart';

class AuthGuard extends ConsumerWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching the AsyncValue from your authStateProvider
    final authState = ref.watch(authStateProvider);
    
    return authState.when(
      data: (status) {
        debugPrint('🛡️ AuthGuard Status: $status');
        
        switch (status) {
          case AuthStatus.authenticated:
            return child;
          
          case AuthStatus.authenticating:
            // If we are currently logging in, we stay on the AuthScreen
            // so the user can see the progress indicator on the button.
            return const AuthScreen();

          case AuthStatus.unauthenticated:
          case AuthStatus.error:
          case AuthStatus.initial:
          default:
            return const AuthScreen();
        }
      },
      // In case of a major provider failure, send them back to login
      error: (error, stack) {
        debugPrint('❌ AuthGuard Error: $error');
        return const AuthScreen();
      },
      // Show this only during the very first app launch (CheckSession)
      loading: () => const _LoadingScreen(),
    );
  }
}

/// A clean, professional loading screen for the initial splash
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Verifying session...', 
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
