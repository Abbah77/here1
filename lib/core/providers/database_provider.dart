import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

// Imports for our custom logic
import '../database/encrypted_database.dart';
import '../security/encryption_service.dart';
import '../database/database.dart'; 
import '../constants/app_constants.dart';

part 'database_provider.g.dart';

// ============= DATABASE INSTANCE =============

@Riverpod(keepAlive: true)
AppDatabase appDatabase(AppDatabaseRef ref) {
  // FIXED: The AppDatabase constructor doesn't take parameters
  // It calls _openConnection() internally which uses EncryptedDatabaseConnection
  return AppDatabase(); // Just return the instance, no parameters needed
}

// ============= STREAMS (REACTIVE UI) =============

@riverpod
Stream<List<Chat>> chatsStream(ChatsStreamRef ref) {
  return ref.watch(appDatabaseProvider).watchChats();
}

@riverpod
Stream<List<Message>> messagesStream(MessagesStreamRef ref, {required String chatId}) {
  return ref.watch(appDatabaseProvider).watchMessages(chatId);
}

// ============= REPOSITORY PROVIDERS =============

@riverpod
ChatRepository chatRepository(ChatRepositoryRef ref) {
  return ChatRepository(ref.watch(appDatabaseProvider));
}

@riverpod
FeedRepository feedRepository(FeedRepositoryRef ref) {
  return FeedRepository(ref.watch(appDatabaseProvider));
}

@riverpod
ProfileRepository profileRepository(ProfileRepositoryRef ref) {
  return ProfileRepository(ref.watch(appDatabaseProvider));
}

// ============= REPOSITORY IMPLEMENTATIONS =============

class ChatRepository {
  final AppDatabase _db;
  ChatRepository(this._db);
  
  // Add the missing sendMessage method
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    String? mediaUrl,
    String? mediaType,
  }) async {
    final message = MessagesCompanion.insert(
      id: const Uuid().v4(),
      chatId: chatId,
      senderId: senderId,
      content: Value(content),
      mediaUrl: mediaUrl != null ? Value(mediaUrl) : const Value.absent(),
      mediaType: mediaType != null ? Value(mediaType) : const Value.absent(),
      status: AppConstants.messageStatusSending,
      timestamp: DateTime.now(),
    );
    
    await _db.into(_db.messages).insert(message);
    
    // Update last message in chat
    await (_db.update(_db.chats)..where((t) => t.id.equals(chatId)))
        .write(ChatsCompanion(
          lastMessage: Value(content),
          lastMessageTime: Value(DateTime.now()),
        ));
  }

  /// Mark as read logic
  Future<void> markChatAsRead(String chatId, String currentUserId) async {
    await (_db.update(_db.messages)
          ..where((t) => 
              t.chatId.equals(chatId) &
              t.senderId.equals(currentUserId).not() & 
              t.status.equals(AppConstants.messageStatusDelivered)))
        .write(const MessagesCompanion(status: Value(AppConstants.messageStatusRead)));
    
    await (_db.update(_db.chats)..where((t) => t.id.equals(chatId)))
        .write(const ChatsCompanion(unreadCount: Value(0)));
  }
}

class FeedRepository {
  final AppDatabase _db;
  FeedRepository(this._db);
  
  // Add the missing updateFeedVisibility method
  Future<void> updateFeedVisibility(String postId, bool isVisible) async {
    await (_db.update(_db.postsMetadata)..where((t) => t.postId.equals(postId)))
        .write(PostsMetadataCompanion(
          isVisible: Value(isVisible),
        ));
  }
  
  // Add method to create a post
  Future<void> createPost({
    required String postId,
    required String authorId,
    required String authorName,
    required String content,
    String? mediaUrl,
    String? mediaType,
    double heatScore = 0.0,
  }) async {
    final post = PostsMetadataCompanion.insert(
      postId: postId,
      authorId: authorId,
      authorName: authorName,
      timestamp: DateTime.now(),
      content: Value(content),
      mediaUrl: mediaUrl != null ? Value(mediaUrl) : const Value.absent(),
      mediaType: mediaType != null ? Value(mediaType) : const Value.absent(),
      heatScore: Value(heatScore),
    );
    
    await _db.into(_db.postsMetadata).insert(post);
  }
}

class ProfileRepository {
  final AppDatabase _db;
  ProfileRepository(this._db);
  
  Future<void> saveRemoteProfile(Map<String, dynamic> data) async {
    // FIXED: Ensure all required fields have values
    final userId = data['id']?.toString() ?? '';
    final username = data['username']?.toString() ?? '';
    final displayName = data['display_name']?.toString() ?? data['displayName']?.toString() ?? '';
    
    if (userId.isEmpty || username.isEmpty || displayName.isEmpty) {
      throw Exception('Invalid profile data: missing required fields');
    }
    
    final profile = UserProfilesCompanion.insert(
      userId: userId,
      username: username,
      displayName: displayName,
      avatarUrl: data['avatar_url'] != null 
          ? Value(data['avatar_url'].toString()) 
          : (data['avatarUrl'] != null 
              ? Value(data['avatarUrl'].toString()) 
              : const Value.absent()),
      bio: data['bio'] != null ? Value(data['bio'].toString()) : const Value.absent(),
      followerCount: Value(data['follower_count'] as int? ?? data['followerCount'] as int? ?? 0),
      followingCount: Value(data['following_count'] as int? ?? data['followingCount'] as int? ?? 0),
      postCount: Value(data['post_count'] as int? ?? data['postCount'] as int? ?? 0),
      isVerified: Value(data['is_verified'] as bool? ?? data['isVerified'] as bool? ?? false),
      heatScore: Value((data['heat_score'] as num?)?.toDouble() ?? (data['heatScore'] as num?)?.toDouble() ?? 0.0),
    );
    
    await _db.into(_db.userProfiles).insertOnConflictUpdate(profile);
  }
}