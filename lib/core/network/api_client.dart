import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:io';
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
    
    debugPrint('🌐 API Request: ${options.method} ${options.path}');
    handler.next(options);
  }
  
  void _onError(DioException error, ErrorInterceptorHandler handler) {
    debugPrint('❌ API Error: ${error.message}');
    if (error.response != null) {
      debugPrint('📦 Response Data: ${error.response?.data}');
    }
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
  
  /// FIXED: Login now uses FormData to satisfy FastAPI's OAuth2PasswordRequestForm
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final formData = FormData.fromMap({
        'username': email, // OAuth2 specifically looks for 'username'
        'password': password,
      });

      final response = await _dio.post(
        '/auth/login', 
        data: formData,
        options: Options(
          contentType: Headers.formUrlEncodedContentType, // Crucial for 422 fix
        ),
      );
      
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
      // Registration still uses JSON
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
    // Python returns 'access_token', we check both for safety
    final token = data['access_token'] ?? data['token'];
    
    if (token != null) {
      await _storage.write(key: 'auth_token', value: token);
      
      // Save user details for offline/quick access
      if (data['user'] != null) {
        final userId = data['user']['id'].toString();
        await _storage.write(key: 'user_id', value: userId);
        await _storage.write(key: 'user_data', value: jsonEncode(data['user']));
      }
      return data;
    }
    throw Exception('No token received from server');
  }
  
  Future<void> logout() async {
    await _storage.deleteAll();
  }
  
  // ============= FEED & POSTS =============
  
  Future<List<Map<String, dynamic>>> syncFeed({DateTime? since, int limit = 50}) async {
    try {
      final response = await _dio.get('/feed/sync', queryParameters: {
        'since': since?.toIso8601String(),
        'limit': limit,
      });
      final List data = response.data['posts'] ?? [];
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }
  
  Future<Map<String, dynamic>> createPost(Map<String, dynamic> postData) async {
    try {
      final response = await _dio.post('/posts', data: postData);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============= PROFILE & USERS =============
  
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final response = await _dio.get('/auth/me'); // Using /me for current user info
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final response = await _dio.get('/auth/search', queryParameters: {'q': query});
      final List data = response.data['users'] ?? [];
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }
  
  // ============= MEDIA =============
  
  Future<String> uploadMedia(File file) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _dio.post('/media/upload', data: formData);
      return response.data['url'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============= ERROR HANDLING =============
  
  Exception _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response?.data;
      if (data is Map && data.containsKey('detail')) {
        // FastAPI validation errors are often a list in 'detail'
        if (data['detail'] is List) {
          return Exception(data['detail'][0]['msg'] ?? 'Validation Error');
        }
        return Exception(data['detail'].toString());
      }
    }
    return Exception(error.message ?? 'Unknown connection error');
  }
}
