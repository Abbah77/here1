import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Internal imports
import '../constants/app_constants.dart';
import '../security/encryption_service.dart';
import 'encrypted_database.dart';

part 'database.g.dart';

// ============= TABLES =============

@DataClassName('Chat')
class Chats extends Table {
  TextColumn get id => text()();
  TextColumn get participants => text()(); 
  TextColumn get lastMessage => text().nullable()();
  DateTimeColumn get lastMessageTime => dateTime().nullable()();
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Message')
class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get chatId => text().references(Chats, #id)();
  TextColumn get senderId => text()();
  TextColumn get content => text().nullable()(); 
  TextColumn get mediaUrl => text().nullable()();
  TextColumn get mediaType => text().nullable()(); 
  TextColumn get status => text()(); 
  DateTimeColumn get timestamp => dateTime()();
  BlobColumn get encryptedData => blob().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PostsMetadataData')
class PostsMetadata extends Table {
  TextColumn get postId => text()();
  TextColumn get authorId => text()();
  TextColumn get authorName => text()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get content => text().nullable()(); 
  TextColumn get mediaUrl => text().nullable()();
  TextColumn get mediaType => text().nullable()(); 
  RealColumn get heatScore => real().withDefault(const Constant(0.0))();
  IntColumn get likeCount => integer().withDefault(const Constant(0))();
  IntColumn get commentCount => integer().withDefault(const Constant(0))();
  IntColumn get shareCount => integer().withDefault(const Constant(0))();
  BoolColumn get isBookmarked => boolean().withDefault(const Constant(false))();
  BoolColumn get isVisible => boolean().withDefault(const Constant(true))();
  @override
  Set<Column> get primaryKey => {postId};
}

@DataClassName('UserProfile')
class UserProfiles extends Table {
  TextColumn get userId => text()();
  TextColumn get displayName => text()();
  TextColumn get username => text().unique()();
  TextColumn get bio => text().nullable()();
  TextColumn get profilePicUrl => text().nullable()();
  TextColumn get avatarUrl => text().nullable()(); 
  IntColumn get followerCount => integer().withDefault(const Constant(0))();
  IntColumn get followingCount => integer().withDefault(const Constant(0))();
  IntColumn get postCount => integer().withDefault(const Constant(0))();
  RealColumn get heatScore => real().withDefault(const Constant(0.0))();
  TextColumn get settings => text().nullable()(); 
  BoolColumn get isVerified => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {userId};
}

@DataClassName('PendingAction')
class PendingActions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get actionType => text()(); 
  TextColumn get targetId => text()(); 
  TextColumn get data => text()(); 
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ============= DATABASE =============

@DriftDatabase(tables: [Chats, Messages, PostsMetadata, UserProfiles, PendingActions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // === REPOSITORY & SYNC COMPATIBILITY ===

  Future<void> clearOldCache() {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return (delete(postsMetadata)..where((t) => t.timestamp.isSmallerThanValue(sevenDaysAgo))).go();
  }

  Future<void> updateMessageStatus(String messageId, String status) {
    return (update(messages)..where((t) => t.id.equals(messageId)))
        .write(MessagesCompanion(status: Value(status)));
  }

  Future<void> removeFromQueue(String messageId) {
    return (delete(messages)..where((t) => t.id.equals(messageId))).go();
  }

  Future<List<PendingAction>> getPendingActions() => select(pendingActions).get();

  Future<void> removePendingAction(int id) {
    return (delete(pendingActions)..where((t) => t.id.equals(id))).go();
  }

  Future<void> addPendingAction(String type, String target, Map<String, dynamic> data) {
    return into(pendingActions).insert(PendingActionsCompanion.insert(
      actionType: type,
      targetId: target,
      data: data.toString(),
    ));
  }

  // === QUERIES ===

  Stream<List<Chat>> watchChats() => select(chats).watch();

  Stream<List<Message>> watchMessages(String chatId) {
    return (select(messages)
          ..where((t) => t.chatId.equals(chatId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<List<Message>> getPendingMessages() {
    return (select(messages)..where((t) => t.status.equals(AppConstants.messageStatusPending))).get();
  }

  Future<void> insertMessageWithQueue(Message message) => into(messages).insert(message);

  Stream<List<PostsMetadataData>> watchFeed() => (select(postsMetadata)
    ..where((t) => t.isVisible.equals(true))
    ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)]))
    .watch();

  Stream<UserProfile?> watchUserProfile(String userId) {
    return (select(userProfiles)..where((t) => t.userId.equals(userId))).watchSingleOrNull();
  }

  Future<UserProfile?> getUserProfile(String userId) {
    return (select(userProfiles)..where((t) => t.userId.equals(userId))).getSingleOrNull();
  }

  Future<bool> usernameExists(String username) async {
    final res = await (select(userProfiles)..where((t) => t.username.equals(username))).get();
    return res.isNotEmpty;
  }

  Future<List<UserProfile>> searchUsers(String query) {
    return (select(userProfiles)..where((t) => t.username.contains(query))).get();
  }

  Future<void> toggleFollow(String current, String target) async {
    await customUpdate(
      'UPDATE user_profiles SET following_count = following_count + 1 WHERE user_id = ?',
      variables: [Variable.withString(current)],
    );
  }
}

// Fixed: Just call EncryptedDatabaseConnection.create directly
// It already returns a LazyDatabase wrapped in NativeDatabase
QueryExecutor _openConnection() {
  return EncryptedDatabaseConnection.create(
    '${AppConstants.databaseName}.sqlite',
    EncryptionService(),
  );
}
// Extension to add 'text' getter to PostsMetadataData
extension PostsMetadataDataCompat on PostsMetadataData {
  String get text => content ?? '';
}
