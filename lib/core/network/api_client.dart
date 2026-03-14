import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';

part 'api_client.g.dart';

@Riverpod(keepAlive: true)
ApiClient apiClient(ApiClientRef ref) {
  return ApiClient();
}

class ApiClient {
  static const String _baseUrl = 'https://here-backend-fgw2.onrender.com/api/v1';
 
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();
  
  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }
  
  Future<void> _onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
  
  void _onError(DioException error, ErrorInterceptorHandler handler) {
    debugPrint('❌ API Error: ${error.response?.statusCode}');
    handler.next(error);
  }

  // ============= AUTH ENDPOINTS =============

  Future<bool> checkUsername(String username) async {
    try {
      final response = await _dio.get('/auth/check-username/$username');
      return response.data['available'] ?? false;
    } catch (e) {
      return false; 
    }
  }
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'username': email,
        'password': password,
      });
      return await _handleAuthResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'username': username,
        'password': password,
      });
      return await _handleAuthResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> _handleAuthResponse(Response response) async {
    final data = response.data;
    final token = data['access_token'] ?? data['token'];
    
    if (token != null) {
      await _storage.write(key: 'auth_token', value: token);
      // We return the whole data map so AuthService can find ['user']
      return data;
    }
    throw Exception('No token received');
  }
  
  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_id');
  }

  // ============= MESSAGES =============
  
  Future<List<Map<String, dynamic>>> syncMessages({required String chatId, DateTime? since}) async {
    try {
      final response = await _dio.get('/messages/sync', queryParameters: {
        'chatId': chatId,
        'since': since?.toIso8601String(),
      });
      return List<Map<String, dynamic>>.from(response.data['messages'] ?? []);
    } catch (e) {
      return [];
    }
  }

  // ============= PROFILE =============

  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final response = await _dio.get('/users/$userId');
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    final response = await _dio.patch('/profile', data: profileData);
    return response.data;
  }

  // ============= MEDIA =============

  Future<Map<String, dynamic>> uploadMedia(FormData formData) async {
    final response = await _dio.post('/media/upload', data: formData);
    return response.data;
  }

  Future<void> deleteMedia(String url) async {
    final uri = Uri.parse(url);
    final key = uri.pathSegments.last;
    await _dio.delete('/media/$key');
  }

  // ============= ERROR HANDLING =============
  
  Exception _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response?.data;
      if (data is Map && data.containsKey('detail')) {
        return Exception(data['detail']);
      }
    }
    return Exception('Network Error: ${error.message}');
  }
}
