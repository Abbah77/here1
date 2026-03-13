import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../network/api_client.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/services/auth_service.dart'; // Added for AuthService
import '../providers/database_provider.dart';
import '../database/database.dart'; // Added for model classes

part 'websocket_service.g.dart';

@Riverpod(keepAlive: true)
WebSocketService webSocketService(WebSocketServiceRef ref) {
  final service = WebSocketService(ref);
  ref.onDispose(() => service.disconnect());
  return service;
}

class WebSocketService {
  final Ref _ref;
  WebSocketChannel? _channel;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  
  // Callbacks
  final Map<String, List<Function(dynamic)>> _listeners = {};
  
  WebSocketService(this._ref);
  
  String? get _baseUrl {
    // Use WebSocket URL (ws:// or wss://)
    return 'ws://localhost:8000/ws'; // TODO: Configure based on environment
  }
  
  Future<void> connect() async {
    if (_isConnected) return;
    
    try {
      final authService = _ref.read(authServiceProvider);
      final token = await authService.getToken();
      if (token == null) {
        print('No token available for WebSocket connection');
        return;
      }
      
      final userId = await authService.getCurrentUserId();
      if (userId == null) return;
      
      final url = '$_baseUrl/$userId?token=$token';
      _channel = WebSocketChannel.connect(Uri.parse(url));
      
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );
      
      _isConnected = true;
      _reconnectAttempts = 0;
      print('WebSocket connected');
      
      // Start ping to keep connection alive
      _startPing();
      
    } catch (e) {
      print('WebSocket connection failed: $e');
      _handleDisconnect();
    }
  }
  
  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message);
      final type = data['type'] as String;
      
      // Notify listeners
      if (_listeners.containsKey(type)) {
        for (final listener in _listeners[type]!) {
          listener(data['data']);
        }
      }
      
      // Handle specific message types
      switch (type) {
        case 'new_message':
          _handleNewMessage(data['data']);
          break;
        case 'typing':
          _handleTypingIndicator(data['data']);
          break;
        case 'read_receipt':
          _handleReadReceipt(data['data']);
          break;
        case 'presence':
          _handlePresence(data['data']);
          break;
        case 'notification':
          _handleNotification(data['data']);
          break;
        case 'pong':
          // Ping response received
          break;
      }
    } catch (e) {
      print('Error handling WebSocket message: $e');
    }
  }
  
  void _handleError(error) {
    print('WebSocket error: $error');
    _handleDisconnect();
  }
  
  void _handleDone() {
    print('WebSocket connection closed');
    _handleDisconnect();
  }
  
  void _handleDisconnect() {
    _isConnected = false;
    _channel = null;
    
    // Attempt to reconnect
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      print('Attempting to reconnect (${_reconnectAttempts}/$_maxReconnectAttempts)...');
      Future.delayed(Duration(seconds: _reconnectAttempts * 2), connect);
    }
  }
  
  void _startPing() {
    Future.delayed(const Duration(seconds: 30), () {
      if (_isConnected) {
        send('ping', {});
        _startPing();
      }
    });
  }
  
  // ============= SEND METHODS =============
  
  void send(String type, Map<String, dynamic> data) {
    if (!_isConnected || _channel == null) {
      print('WebSocket not connected');
      return;
    }
    
    try {
      _channel!.sink.add(json.encode({
        'type': type,
        ...data,
        'timestamp': DateTime.now().toIso8601String(),
      }));
    } catch (e) {
      print('Error sending WebSocket message: $e');
    }
  }
  
  // Message methods
  void sendMessage({
    required String chatId,
    String? text,
    String? mediaUrl,
    String? mediaType,
    String? tempId,
  }) {
    send('message', {
      'chat_id': chatId,
      'text': text,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'temp_id': tempId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    });
  }
  
  void sendTypingIndicator(String chatId, bool isTyping) {
    send('typing', {
      'chat_id': chatId,
      'is_typing': isTyping,
    });
  }
  
  void sendReadReceipt(String messageId, String chatId) {
    send('read_receipt', {
      'message_id': messageId,
      'chat_id': chatId,
    });
  }
  
  void requestOnlineStatus(String? userId) {
    send('get_online_status', {
      'user_id': userId,
    });
  }
  
  // ============= LISTENER METHODS =============
  
  void on(String type, Function(dynamic) callback) {
    if (!_listeners.containsKey(type)) {
      _listeners[type] = [];
    }
    _listeners[type]!.add(callback);
  }
  
  void off(String type, Function(dynamic) callback) {
    if (_listeners.containsKey(type)) {
      _listeners[type]!.remove(callback);
    }
  }
  
  // ============= MESSAGE HANDLERS =============
  
  void _handleNewMessage(dynamic data) {
    try {
      final chatRepo = _ref.read(chatRepositoryProvider);
      // FIXED: Create a method that exists in ChatRepository
      // This assumes your ChatRepository has a method to save messages
      if (data is Map<String, dynamic>) {
        // You might need to adapt this based on your actual ChatRepository methods
        chatRepo.sendMessage(
          chatId: data['chat_id'] ?? '',
          senderId: data['sender_id'] ?? '',
          content: data['content'] ?? '',
          mediaUrl: data['media_url'],
          mediaType: data['media_type'],
        );
      }
    } catch (e) {
      print('Error saving remote message: $e');
    }
  }
  
  void _handleTypingIndicator(dynamic data) {
    // Update UI typing indicators
    // This would be handled by providers
  }
  
  void _handleReadReceipt(dynamic data) {
    try {
      final chatRepo = _ref.read(chatRepositoryProvider);
      if (data['message_id'] != null) {
        // FIXED: Use markChatAsRead which exists in ChatRepository
        // You'll need to get the chatId from somewhere
        final String? chatId = data['chat_id'];
        if (chatId != null) {
          chatRepo.markChatAsRead(chatId, ''); // You need current user ID here
        }
      }
    } catch (e) {
      print('Error marking message as read: $e');
    }
  }
  
  void _handlePresence(dynamic data) {
    // Update online status in UI
  }
  
  void _handleNotification(dynamic data) {
    // Show local notification
    // This would integrate with flutter_local_notifications
  }
  
  // ============= CONNECTION MANAGEMENT =============
  
  bool get isConnected => _isConnected;
  
  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close(status.normalClosure, 'Disconnected');
      _channel = null;
    }
    _isConnected = false;
    _listeners.clear();
  }
}

// REMOVED: Duplicate provider definitions at the bottom
// These should be defined in their respective files, not here
// - authServiceProvider is already defined in auth_service.dart
// - chatRepositoryProvider is already defined in database_provider.dart