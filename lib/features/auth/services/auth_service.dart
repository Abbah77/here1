import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Core imports
import 'package:here/core/network/api_client.dart';
import 'package:here/core/database/database.dart';
import 'package:here/core/providers/database_provider.dart';
import 'package:here/core/security/encryption_service.dart';
import 'package:here/core/providers/security_provider.dart';

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
      
      await _saveAuthData(response);
      await _syncUserProfile(response['user']);
      
      await _ref.read(encryptionServiceProvider).initialize();
      
      return response;
    } catch (e) {
      throw Exception('Login failed: $e');
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
      await _syncUserProfile(response['user']);
      await _ref.read(encryptionServiceProvider).initialize();
      
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
    await _storage.write(key: _tokenKey, value: response['token']);
    await _storage.write(key: _userIdKey, value: response['user']['id']);
    await _storage.write(
      key: _userDataKey, 
      value: json.encode(response['user']),
    );
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
    if (userData != null) return json.decode(userData);
    return null;
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // ============= PROFILE SYNC =============

  Future<void> _syncUserProfile(Map<String, dynamic> userData) async {
    try {
      final profileRepo = _ref.read(profileRepositoryProvider);
      await profileRepo.saveRemoteProfile(userData);
      debugPrint('✅ Synced user profile to local DB');
    } catch (e) {
      debugPrint('❌ Failed to sync user profile: $e');
    }
  }

  // ============= AUTO-LOGIN =============

  Future<bool> tryAutoLogin() async {
    try {
      final isLoggedIn = await this.isLoggedIn();
      if (!isLoggedIn) return false;
      
      final userId = await getCurrentUserId();
      if (userId == null) return false;
      
      await _ref.read(encryptionServiceProvider).initialize();
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

  // ============= PROFILE UPDATES =============

  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? profilePicUrl,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not logged in');
      
      final api = _ref.read(apiClientProvider);
      
      final updateData = <String, dynamic>{};
      if (displayName != null) updateData['displayName'] = displayName;
      if (bio != null) updateData['bio'] = bio;
      if (profilePicUrl != null) updateData['avatarUrl'] = profilePicUrl;
      if (settings != null) updateData['settings'] = settings;
      
      final updatedUser = await api.updateProfile(updateData);
      await _syncUserProfile(updatedUser);
      
      final currentUser = await getCurrentUser();
      if (currentUser != null) {
        currentUser.addAll(updatedUser);
        await _storage.write(
          key: _userDataKey,
          value: json.encode(currentUser),
        );
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // ============= PASSWORD MANAGEMENT =============
  // FIXED: These methods now use a generic API call or throw a clear error
  // until the API client is updated with these methods

  Future<void> resetPassword(String email) async {
    try {
      final api = _ref.read(apiClientProvider);
      // FIXED: Use a generic post request instead of undefined method
      // This assumes your API has an endpoint for password reset
      await api.post('/auth/reset-password', {'email': email});
      debugPrint('Password reset email sent to $email');
    } catch (e) {
      debugPrint('Password reset failed: $e');
      throw Exception('Password reset failed. Please try again later.');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final api = _ref.read(apiClientProvider);
      final token = await getToken();
      
      if (token == null) {
        throw Exception('Not authenticated');
      }
      
      // FIXED: Use a generic post request with authorization
      await api.post(
        '/auth/change-password',
        {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
        headers: {'Authorization': 'Bearer $token'},
      );
      
      debugPrint('Password changed successfully');
    } catch (e) {
      debugPrint('Password change failed: $e');
      throw Exception('Failed to change password. Please check your current password.');
    }
  }
}

// Extension to add post method to ApiClient if it doesn't exist
// This is a temporary fix - you should add these methods to ApiClient properly
extension ApiClientExtension on ApiClient {
  Future<dynamic> post(String path, Map<String, dynamic> data, {Map<String, String>? headers}) async {
    // This assumes your ApiClient has a dio or http client
    // You'll need to implement this based on your actual ApiClient structure
    throw UnimplementedError('post method needs to be implemented in ApiClient');
  }
}