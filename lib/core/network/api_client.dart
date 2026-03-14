import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

part 'api_client.g.dart';

@Riverpod(keepAlive: true)
ApiClient apiClient(ApiClientRef ref) => ApiClient();

class ApiClient {
  static const String _baseUrl = 'https://here-backend-fgw2.onrender.com/api/v1';
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();
  
  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ));
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onError: _onError,
    ));
  }
  
  Future<void> _onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    debugPrint('🌐 API: ${options.method} ${options.path}');
    handler.next(options);
  }
  
  void _onError(DioException error, ErrorInterceptorHandler handler) {
    debugPrint('❌ API Error: ${error.message} | Response: ${error.response?.data}');
    handler.next(error);
  }
  
  // ============= AUTH ENDPOINTS =============

  Future<bool> checkUsername(String username) async {
    try {
      final response = await _dio.get('/auth/check-username/$username');
      return response.data['available'] ?? false;
    } catch (_) { return false; }
  }
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final formData = FormData.fromMap({
        'username': email, 
        'password': password,
      });

      final response = await _dio.post(
        '/auth/login', 
        data: formData,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      
      return await _handleAuthResponse(response);
    } on DioException catch (e) { throw _handleError(e); }
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
    } on DioException catch (e) { throw _handleError(e); }
  }

  Future<Map<String, dynamic>> _handleAuthResponse(Response response) async {
    final data = response.data;
    final token = data['access_token'] ?? data['token'];
    
    if (token != null) {
      await _storage.write(key: 'auth_token', value: token);
      
      // Pull user data safely from nested or flat response
      final userData = data['user'] ?? data;
      if (userData != null && userData['id'] != null) {
        await _storage.write(key: 'user_id', value: userData['id'].toString());
        await _storage.write(key: 'user_data', value: jsonEncode(userData));
      }
      return data;
    }
    throw Exception('Authentication failed: No token received');
  }
  
  Future<void> logout() async {
    await _storage.deleteAll();
  }
  
  // ============= FEATURES =============
  
  Future<List<Map<String, dynamic>>> syncMessages({required String chatId, DateTime? since}) async {
    try {
      final response = await _dio.get('/messages/sync', queryParameters: {
        'chatId': chatId,
        'since': since?.toIso8601String(),
      });
      return List<Map<String, dynamic>>.from(response.data['messages'] ?? []);
    } catch (_) { return []; }
  }
  
  Future<Map<String, dynamic>> sendMessage(Map<String, dynamic> msg) async {
    try {
      final response = await _dio.post('/messages', data: msg);
      return response.data;
    } on DioException catch (e) { throw _handleError(e); }
  }

  Future<List<Map<String, dynamic>>> syncFeed({DateTime? since, int limit = 50}) async {
    try {
      final response = await _dio.get('/feed/sync', queryParameters: {
        'since': since?.toIso8601String(),
        'limit': limit,
      });
      return List<Map<String, dynamic>>.from(response.data['posts'] ?? []);
    } catch (_) { return []; }
  }
  
  Future<void> interactWithPost(String postId, String action) async {
    try {
      await _dio.post('/posts/$postId/interact', data: {'action': action});
    } on DioException catch (e) { throw _handleError(e); }
  }

  // ============= PROFILE & MEDIA =============
  
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final response = await _dio.get('/users/$userId');
      return response.data;
    } on DioException catch (e) { throw _handleError(e); }
  }
  
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('/profile', data: data);
      return response.data;
    } on DioException catch (e) { throw _handleError(e); }
  }

  Future<void> toggleFollow(String userId) async {
    try {
      await _dio.post('/users/$userId/follow');
    } on DioException catch (e) { throw _handleError(e); }
  }

  Future<Map<String, dynamic>> uploadMedia(FormData formData) async {
    try {
      final response = await _dio.post('/media/upload', data: formData);
      return response.data;
    } on DioException catch (e) { throw _handleError(e); }
  }

  Future<void> deleteMedia(String url) async {
    try {
      final key = Uri.parse(url).pathSegments.last;
      await _dio.delete('/media/$key');
    } on DioException catch (e) { throw _handleError(e); }
  }

  // ============= ERROR HANDLER =============
  
  Exception _handleError(DioException error) {
    if (error.response?.data is Map) {
      final detail = error.response?.data['detail'];
      return Exception(detail?.toString() ?? 'Server Error');
    }
    return Exception('Network error: ${error.message}');
  }
}
