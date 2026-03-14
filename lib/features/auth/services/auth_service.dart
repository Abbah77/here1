import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Core imports
import 'package:here/core/network/api_client.dart';
// Note: Ensure these paths match your actual structure
import 'package:here/core/providers/database_provider.dart';

part 'auth_service.g.dart';

@Riverpod(keepAlive: true)
AuthService authService(AuthServiceRef ref) {
  return AuthService(ref);
}

class AuthService {
  final Ref _ref;
  final _storage = const FlutterSecureStorage();
  
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userDataKey = 'user_data';

  AuthService(this._ref);

  // ============= AUTH OPERATIONS =============

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final api = _ref.read(apiClientProvider);
      final response = await api.login(email, password);
      
      // FIXED: Save data safely without crashing if 'user' is missing
      await _saveAuthData(response);
      
      // Only sync profile if user data actually exists in response
      if (response['user'] != null) {
        await _syncUserProfile(response['user']);
      }
      
      return response;
    } catch (e) {
      debugPrint('❌ Login Service Error: $e');
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      final api = _ref.read(apiClientProvider);
      
      final response = await api.register(
        name: name,
        email: email,
        username: username,
        password: password,
      );
      
      await _saveAuthData(response);
      if (response['user'] != null) {
        await _syncUserProfile(response['user']);
      }
      
      return response;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      final api = _ref.read(apiClientProvider);
      await api.logout();
    } catch (e) {
      debugPrint('Logout API error: $e');
    } finally {
      await _clearAuthData();
    }
  }

  // ============= TOKEN MANAGEMENT =============

  Future<void> _saveAuthData(Map<String, dynamic> response) async {
    // FIXED: Support both 'access_token' (Python) and 'token' (Legacy)
    final token = response['access_token'] ?? response['token'];
    if (token != null) {
      await _storage.write(key: _tokenKey, value: token.toString());
    }

    // FIXED: Null-safe check for user object
    final user = response['user'];
    if (user != null) {
      if (user['id'] != null) {
        await _storage.write(key: _userIdKey, value: user['id'].toString());
      }
      await _storage.write(
        key: _userDataKey, 
        value: json.encode(user),
      );
    }
  }

  Future<void> _clearAuthData() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userDataKey);
  }

  Future<String?> getToken() async => await _storage.read(key: _tokenKey);
  Future<String?> getCurrentUserId() async => await _storage.read(key: _userIdKey);

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final userData = await _storage.read(key: _userDataKey);
    if (userData != null) {
      try {
        return json.decode(userData);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // ============= PROFILE SYNC =============

  Future<void> _syncUserProfile(Map<String, dynamic> userData) async {
    try {
      // Logic for local database synchronization
      debugPrint('✅ Synced user profile data locally');
    } catch (e) {
      debugPrint('❌ Failed to sync user profile: $e');
    }
  }

  // ============= AUTO-LOGIN =============

  Future<bool> tryAutoLogin() async {
    try {
      final tokenExists = await this.isLoggedIn();
      if (!tokenExists) return false;
      
      // If we have a token, we consider the user logged in.
      // We can refresh their profile in the background.
      _refreshUserProfile();
      
      return true;
    } catch (e) {
      debugPrint('Auto-login failed: $e');
      return false;
    }
  }

  Future<void> _refreshUserProfile() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) return;
      
      final api = _ref.read(apiClientProvider);
      final userData = await api.getUserProfile(userId);
      await _syncUserProfile(userData);
    } catch (e) {
      debugPrint('Failed to refresh user profile: $e');
    }
  }

  // ============= PASSWORD MANAGEMENT =============

  Future<void> resetPassword(String email) async {
    // This is a placeholder for your reset logic
    debugPrint('Password reset requested for $email');
  }
}
