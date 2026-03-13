import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';

// Absolute imports to prevent "URI doesn't exist" errors
import 'package:here/core/database/database.dart';
import 'package:here/core/network/api_client.dart';
import 'package:here/core/providers/database_provider.dart';
import 'package:here/core/constants/app_constants.dart';

part 'sync_service.g.dart';

@Riverpod(keepAlive: true)
class SyncService extends _$SyncService {
  Timer? _syncTimer;
  bool _isSyncing = false;
  
  // Updated for connectivity_plus 6.x compatibility
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final Map<String, DateTime> _lastSyncTimes = {};

  @override
  FutureOr<void> build() {
    _init();
    ref.onDispose(() {
      _syncTimer?.cancel();
      _connectivitySubscription?.cancel();
    });
  }

  void _init() {
    _setupConnectivityListener();
    _startPeriodicSync();
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _handleConnectivityChange,
      onError: (e) => debugPrint('❌ Connectivity error: $e'),
    );
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    // Check if any of the results indicate an active connection
    final hasConnection = results.isNotEmpty && 
                         !results.contains(ConnectivityResult.none);
    
    if (hasConnection) {
      debugPrint('📱 Network available - starting sync');
      syncAll();
    }
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    // Synced every 15 mins to save battery, but triggers immediately on network change
    _syncTimer = Timer.periodic(const Duration(minutes: 15), (_) => syncAll());
  }

  Future<bool> _checkConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.isNotEmpty && !results.contains(ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }

  Future<void> syncAll() async {
    if (_isSyncing) return;
    if (!await _checkConnectivity()) return;

    _isSyncing = true;
    try {
      await Future.wait([
        syncMessages(),
        syncFeed(),
        syncProfile(),
        _syncPendingActions(),
      ]);
      debugPrint('✅ Full sync completed');
    } catch (e) {
      debugPrint('❌ Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // --- MESSAGES SYNC ---

  Future<bool> syncMessages() async {
    try {
      final api = ref.read(apiClientProvider);
      final db = ref.read(appDatabaseProvider);

      final chatsList = await db.select(db.chats).get();
      for (final chat in chatsList) {
        final lastSync = _lastSyncTimes['messages_${chat.id}'];
        final remoteMessages = await api.syncMessages(
          chatId: chat.id, 
          since: lastSync
        );

        if (remoteMessages.isNotEmpty) {
          await db.batch((batch) {
            for (final msg in remoteMessages) {
              _insertMessage(batch, db, msg);
            }
          });
          _lastSyncTimes['messages_${chat.id}'] = DateTime.now();
        }
      }
      await _sendPendingMessages();
      return true;
    } catch (e) {
      return false;
    }
  }

  void _insertMessage(Batch batch, AppDatabase db, Map<String, dynamic> msg) {
    final timestamp = DateTime.tryParse(msg['timestamp']?.toString() ?? '') ?? DateTime.now();
    
    batch.insert(
      db.messages,
      MessagesCompanion(
        id: Value(msg['id'] as String),
        chatId: Value(msg['chatId'] as String),
        senderId: Value(msg['senderId'] as String),
        content: Value(msg['content'] as String? ?? ''),
        status: Value(msg['status']?.toString() ?? AppConstants.messageStatusDelivered),
        timestamp: Value(timestamp),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> _sendPendingMessages() async {
    final api = ref.read(apiClientProvider);
    final db = ref.read(appDatabaseProvider);
    final pending = await db.getPendingMessages();

    for (final msg in pending) {
      try {
        await api.sendMessage({
          'id': msg.id,
          'chatId': msg.chatId,
          'content': msg.content,
        });
        await db.updateMessageStatus(msg.id, AppConstants.messageStatusSent);
      } catch (e) {
        debugPrint('❌ Failed to send pending message: $e');
      }
    }
  }

  // --- FEED SYNC ---

  Future<bool> syncFeed() async {
    try {
      final api = ref.read(apiClientProvider);
      final db = ref.read(appDatabaseProvider);
      
      final lastSync = _lastSyncTimes['feed'];
      final posts = await api.syncFeed(since: lastSync);

      if (posts.isNotEmpty) {
        await db.batch((batch) {
          for (final post in posts) {
            batch.insert(
              db.postsMetadata,
              PostsMetadataCompanion(
                postId: Value(post['id'] as String),
                authorId: Value(post['authorId'] as String),
                authorName: Value(post['authorName'] as String),
                timestamp: Value(DateTime.parse(post['timestamp'] as String)),
                content: Value(post['content'] as String? ?? ''),
                likeCount: Value(post['likeCount'] as int? ?? 0),
                isBookmarked: Value(post['isBookmarked'] as bool? ?? false),
                heatScore: Value((post['heatScore'] as num?)?.toDouble() ?? 0.0),
              ),
              mode: InsertMode.insertOrReplace,
            );
          }
        });
        _lastSyncTimes['feed'] = DateTime.now();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- PROFILE SYNC ---

  Future<bool> syncProfile() async {
    try {
      final api = ref.read(apiClientProvider);
      final db = ref.read(appDatabaseProvider);
      
      // Replace with actual current user ID logic
      const userId = "current_session_user"; 

      final data = await api.getUserProfile(userId);
      await db.into(db.userProfiles).insertOnConflictUpdate(
        UserProfilesCompanion(
          userId: Value(data['id'] as String),
          displayName: Value(data['displayName'] as String? ?? ''),
          username: Value(data['username'] as String? ?? ''),
          avatarUrl: data['avatarUrl'] != null ? Value(data['avatarUrl'] as String) : const Value.absent(),
        ),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- PENDING ACTIONS ---

  Future<void> _syncPendingActions() async {
    final api = ref.read(apiClientProvider);
    final db = ref.read(appDatabaseProvider);
    final actions = await db.getPendingActions();

    for (final action in actions) {
      try {
        if (action.actionType == 'like') {
          await api.interactWithPost(action.targetId, 'like');
        } else if (action.actionType == 'follow') {
          await api.toggleFollow(action.targetId);
        }
        await db.removePendingAction(action.id);
      } catch (e) {
        debugPrint('❌ Failed action sync: $e');
      }
    }
  }
}