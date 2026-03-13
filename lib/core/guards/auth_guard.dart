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
        switch (status) {
          case AuthStatus.authenticated:
            return child;
          case AuthStatus.unauthenticated:
          case AuthStatus.error: // Added missing error case
            return const AuthScreen();
          case AuthStatus.authenticating:
          case AuthStatus.initial:
            return const _LoadingScreen();
        }
      },
      // If there's an error (like a DB failure), default to AuthScreen so they can try logging in again
      error: (error, stack) {
        debugPrint('AuthGuard Error: $error');
        return const AuthScreen();
      },
      loading: () => const _LoadingScreen(),
    );
  }
}

/// Extracted loading UI to keep the build method clean
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
            SizedBox(height: 16),
            Text('Verifying session...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}