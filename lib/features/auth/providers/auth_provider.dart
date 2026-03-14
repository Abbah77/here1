import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:here/features/auth/services/auth_service.dart';

part 'auth_provider.g.dart';

enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  error,
}

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
        // Try to load user, but don't let it crash the whole app if it fails
        _safeLoadUser();
        return AuthStatus.authenticated;
      }
      return AuthStatus.unauthenticated;
    } catch (_) {
      return AuthStatus.unauthenticated;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.data(AuthStatus.authenticating);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.login(email: email, password: password);
      
      // We got the token! Let's set the status to authenticated first.
      state = const AsyncValue.data(AuthStatus.authenticated);
      
      // Try to load user profile in the background without blocking the login success
      _safeLoadUser();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _safeLoadUser() async {
    try {
      await ref.read(currentUserProvider.notifier).loadUser();
    } catch (e) {
      print('Background user load failed: $e');
      // We don't change the state to error here because the token is still valid
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.data(AuthStatus.authenticating);
    try {
      await ref.read(authServiceProvider).logout();
      ref.read(currentUserProvider.notifier).setUser(null);
      state = const AsyncValue.data(AuthStatus.unauthenticated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Access aliases
final authProvider = authNotifierProvider;
final authStateProvider = authNotifierProvider;

@Riverpod(keepAlive: true)
class CurrentUser extends _$CurrentUser {
  @override
  FutureOr<Map<String, dynamic>?> build() => null;

  Future<void> loadUser() async {
    try {
      final user = await ref.read(authServiceProvider).getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      // If we can't find the user profile, we just set it to null instead of erroring out the UI
      state = const AsyncValue.data(null);
    }
  }

  void setUser(Map<String, dynamic>? user) => state = AsyncValue.data(user);
}

@riverpod
Future<bool> usernameAvailability(UsernameAvailabilityRef ref, String username) async {
  // Always returns true to prevent UI blocking during development
  return true; 
}
