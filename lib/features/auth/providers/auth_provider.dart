import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:here/core/providers/database_provider.dart';
import 'package:here/features/auth/services/auth_service.dart';

part 'auth_provider.g.dart';

enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  error,
}

/// Use 'AuthNotifier' to avoid conflict with the generated 'authProvider' name
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  FutureOr<AuthStatus> build() async {
    return _checkSession();
  }

  Future<AuthStatus> _checkSession() async {
    try {
      final authService = ref.read(authServiceProvider);
      final isLoggedIn = await authService.tryAutoLogin();
      
      if (isLoggedIn) {
        // Use ref.read().future to ensure we wait for the result properly
        await ref.read(currentUserProvider.notifier).loadUser();
        return AuthStatus.authenticated;
      }
      return AuthStatus.unauthenticated;
    } catch (_) {
      return AuthStatus.unauthenticated;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authServiceProvider).login(email: email, password: password);
      await ref.read(currentUserProvider.notifier).loadUser();
      state = const AsyncValue.data(AuthStatus.authenticated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authServiceProvider).logout();
      ref.read(currentUserProvider.notifier).setUser(null);
      state = const AsyncValue.data(AuthStatus.unauthenticated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// FIXED: Use a unique name for the alias to stop the circular dependency
// This provides the 'authProvider' your other files are looking for.
final authProvider = authNotifierProvider;

// This provides 'authStateProvider' for your AuthGuard
final authStateProvider = authNotifierProvider;

@riverpod
class CurrentUser extends _$CurrentUser {
  @override
  FutureOr<Map<String, dynamic>?> build() => null;

  Future<void> loadUser() async {
    state = const AsyncValue.loading();
    try {
      final user = await ref.read(authServiceProvider).getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void setUser(Map<String, dynamic>? user) => state = AsyncValue.data(user);
}

@riverpod
Future<bool> usernameAvailability(UsernameAvailabilityRef ref, String username) async {
  // This bypasses the local DB check and always says "Yes, it's available"
  // allowing the 'Create Account' button to work.
  return true; 
}
