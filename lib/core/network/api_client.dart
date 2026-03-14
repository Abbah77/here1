import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../constants/app_constants.dart';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';

part 'api_client.g.dart';

@Riverpod(keepAlive: true)
ApiClient apiClient(ApiClientRef ref) {
  return ApiClient();
}

class ApiClient {
  static const String _baseUrl = 'https://here-backend-fgw2.onrender.com';
 
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
    
    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }
  
  Future<void> _onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Add auth token if available
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    // Log request in debug mode
    debugPrint('🌐 API Request: ${options.method} ${options.path}');
    if (options.data != null) {
      debugPrint('📦 Data: ${options.data}');
    }
    
    handler.next(options);
  }
  
  void _onError(DioException error, ErrorInterceptorHandler handler) {
    debugPrint('❌ API Error: ${error.message}');
    debugPrint('📍 Path: ${error.requestOptions.path}');
    if (error.response != null) {
      debugPrint('📦 Response: ${error.response?.data}');
    }
    handler.next(error);
  }
  
  // ============= AUTH ENDPOINTS =============
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      if (response.statusCode == 200) {
        final data = response.data;
        await _storage.write(key: 'auth_token', value: data['token']);
        await _storage.write(key: 'user_id', value: data['user']['id']);
        return data;
      }
      throw Exception('Login failed');
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
      
      if (response.statusCode == 201) {
        final data = response.data;
        await _storage.write(key: 'auth_token', value: data['token']);
        await _storage.write(key: 'user_id', value: data['user']['id']);
        return data;
      }
      throw Exception('Registration failed');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_id');
  }
  
  // ============= MESSAGE ENDPOINTS =============
  
  // Delta sync for messages - get messages after timestamp
  Future<List<Map<String, dynamic>>> syncMessages({
    required String chatId,
    DateTime? since,
  }) async {
    try {
      final response = await _dio.get(
        '/messages/sync',
        queryParameters: {
          'chatId': chatId,
          'since': since?.toIso8601String(),
        },
      );
      
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['messages'] ?? []);
      }
      return [];
    } on DioException catch (e) {
      debugPrint('❌ Failed to sync messages: $e');
      return [];
    }
  }
  
  // Send message to backend
  Future<Map<String, dynamic>> sendMessage(Map<String, dynamic> message) async {
    try {
      final response = await _dio.post('/messages', data: message);
      
      if (response.statusCode == 201) {
        return response.data;
      }
      throw Exception('Failed to send message');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Mark messages as delivered/read
  Future<void> updateMessageStatus(String messageId, String status) async {
    try {
      await _dio.patch('/messages/$messageId', data: {
        'status': status,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // ============= FEED ENDPOINTS =============
  
  // Delta sync for feed
  Future<List<Map<String, dynamic>>> syncFeed({
    DateTime? since,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/feed/sync',
        queryParameters: {
          'since': since?.toIso8601String(),
          'limit': limit,
          'offset': offset,
        },
      );
      
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['posts'] ?? []);
      }
      return [];
    } on DioException catch (e) {
      debugPrint('❌ Failed to sync feed: $e');
      return [];
    }
  }
  
  // Create post
  Future<Map<String, dynamic>> createPost(Map<String, dynamic> postData) async {
    try {
      final response = await _dio.post('/posts', data: postData);
      
      if (response.statusCode == 201) {
        return response.data;
      }
      throw Exception('Failed to create post');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // NEW: Add comment to post
  Future<Map<String, dynamic>> addComment(String postId, String comment) async {
    try {
      final response = await _dio.post('/posts/$postId/comments', data: {
        'content': comment,
      });
      
      if (response.statusCode == 201) {
        return response.data;
      }
      throw Exception('Failed to add comment');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // NEW: Share post
  Future<Map<String, dynamic>> sharePost(String postId) async {
    try {
      final response = await _dio.post('/posts/$postId/share');
      
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to share post');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Like/unlike post
  Future<void> interactWithPost(String postId, String action) async {
    try {
      await _dio.post('/posts/$postId/interact', data: {
        'action': action, // 'like', 'unlike', 'comment', 'share'
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // ============= PROFILE ENDPOINTS =============
  
  // Get user profile
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final response = await _dio.get('/users/$userId');
      
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to get profile');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Update profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await _dio.patch('/profile', data: profileData);
      
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to update profile');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Follow/unfollow user
  Future<void> toggleFollow(String userId) async {
    try {
      await _dio.post('/users/$userId/follow');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Search users
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final response = await _dio.get(
        '/users/search',
        queryParameters: {'q': query},
      );
      
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['users'] ?? []);
      }
      return [];
    } on DioException catch (e) {
      debugPrint('❌ Failed to search users: $e');
      return [];
    }
  }
  
  // ============= MEDIA ENDPOINTS =============
  
  // Upload media file (original method - kept for backward compatibility)
  Future<String> uploadMediaFile(File file, String type) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        'type': type,
      });
      
      final response = await _dio.post('/media/upload', data: formData);
      
      if (response.statusCode == 201) {
        return response.data['url'];
      }
      throw Exception('Failed to upload media');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Upload media with FormData (for multiple files)
  Future<Map<String, dynamic>> uploadMedia(FormData formData) async {
    try {
      final response = await _dio.post(
        '/media/upload',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
        onSendProgress: (sent, total) {
          if (total > 0) {
            debugPrint('Upload progress: ${(sent/total*100).toStringAsFixed(0)}%');
          }
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
      throw Exception('Upload failed');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Upload multiple media
  Future<Map<String, dynamic>> uploadMultipleMedia(List<FormData> files) async {
    try {
      // This would need to be implemented as multipart/mixed
      // For now, upload one by one
      final results = [];
      for (final file in files) {
        final result = await uploadMedia(file);
        results.add(result);
      }
      return {'results': results};
    } catch (e) {
      throw Exception('Failed to upload multiple files: $e');
    }
  }
  
  // Upload profile picture
  Future<Map<String, dynamic>> uploadProfilePicture(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });
      
      final response = await _dio.post(
        '/media/upload/profile-picture',
        data: formData,
      );
      
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Upload failed');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Delete media
  Future<void> deleteMedia(String url) async {
    try {
      // Extract key from URL
      final uri = Uri.parse(url);
      final key = uri.pathSegments.last;
      
      await _dio.delete('/media/$key');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Get optimized URL
  String getOptimizedUrl(String url, {int? width, int? height}) {
    // Use backend optimization
    final uri = Uri.parse(url);
    final path = uri.path;
    
    if (width != null || height != null) {
      final queryParams = <String, String>{};
      if (width != null) queryParams['width'] = width.toString();
      if (height != null) queryParams['height'] = height.toString();
      
      return '/media/optimized-url$path?${Uri(queryParameters: queryParams).query}';
    }
    
    return url;
  }
  
  // ============= WEBSOCKET =============
  
  WebSocketChannel? _channel;
  
  void connectWebSocket() {
    // TODO: Implement WebSocket connection for real-time updates
    // _channel = WebSocketChannel.connect(Uri.parse('ws://api.yourbackend.com/ws'));
  }
  
  void disconnectWebSocket() {
    _channel?.sink.close();
    _channel = null;
  }
  
  // ============= ERROR HANDLING =============
  
  Exception _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response?.data;
      if (data is Map && data.containsKey('message')) {
        return Exception(data['message']);
      }
      return Exception('Server error: ${error.response?.statusCode}');
    }
    
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return Exception('Connection timeout. Please check your internet.');
      case DioExceptionType.connectionError:
        return Exception('No internet connection');
      case DioExceptionType.cancel:
        return Exception('Request was cancelled');
      case DioExceptionType.badResponse:
        return Exception('Bad response from server');
      default:
        return Exception('Network error: ${error.message}');
    }
  }
}
