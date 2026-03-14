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
  
  /// FIXED: Login now uses FormData + URL Encoding to stop the 422 Error
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final formData = FormData.fromMap({
        'username': email, 
        'password': password,
      });

      final response = await _dio.post(
        '/auth/login', 
        data: formData,
        options: Options(
          contentType: Headers.formUrlEncodedContentType, 
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
      if (data['user'] != null) {
        await _storage.write(key: 'user_id', value: data['user']['id'].toString());
      }
      return data;
    }
    throw Exception('Authentication failed');
  }
  
  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_id');
  }
  
  // ============= MESSAGE ENDPOINTS =============
  
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
  
  Future<Map<String, dynamic>> sendMessage(Map<String, dynamic> message) async {
    try {
      final response = await _dio.post('/messages', data: message);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<void> updateMessageStatus(String messageId, String status) async {
    try {
      await _dio.patch('/messages/$messageId', data: {'status': status});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // ============= FEED ENDPOINTS =============
  
  Future<List<Map<String, dynamic>>> syncFeed({DateTime? since, int limit = 50, int offset = 0}) async {
    try {
      final response = await _dio.get('/feed/sync', queryParameters: {
        'since': since?.toIso8601String(),
        'limit': limit,
        'offset': offset,
      });
      return List<Map<String, dynamic>>.from(response.data['posts'] ?? []);
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
  
  Future<Map<String, dynamic>> addComment(String postId, String comment) async {
    try {
      final response = await _dio.post('/posts/$postId/comments', data: {'content': comment});
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> sharePost(String postId) async {
    try {
      final response = await _dio.post('/posts/$postId/share');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<void> interactWithPost(String postId, String action) async {
    try {
      await _dio.post('/posts/$postId/interact', data: {'action': action});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // ============= PROFILE ENDPOINTS =============
  
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final response = await _dio.get('/users/$userId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await _dio.patch('/profile', data: profileData);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<void> toggleFollow(String userId) async {
    try {
      await _dio.post('/users/$userId/follow');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final response = await _dio.get('/users/search', queryParameters: {'q': query});
      return List<Map<String, dynamic>>.from(response.data['users'] ?? []);
    } catch (e) {
      return [];
    }
  }
  
  // ============= MEDIA ENDPOINTS =============
  
  Future<String> uploadMediaFile(File file, String type) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
        'type': type,
      });
      final response = await _dio.post('/media/upload', data: formData);
      return response.data['url'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> uploadMedia(FormData formData) async {
    try {
      final response = await _dio.post('/media/upload', data: formData);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<void> deleteMedia(String url) async {
    try {
      final uri = Uri.parse(url);
      final key = uri.pathSegments.last;
      await _dio.delete('/media/$key');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============= ERROR HANDLING =============
  
  Exception _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response?.data;
      if (data is Map && data.containsKey('detail')) {
        return Exception(data['detail'].toString());
      }
    }
    return Exception('Network error: ${error.message}');
  }
}
