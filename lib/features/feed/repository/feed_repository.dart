import 'dart:math';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:here/core/database/database.dart';
import 'package:here/core/constants/app_constants.dart';

class FeedRepository {
  final AppDatabase _db;
  
  FeedRepository(this._db);

  // ============= POST OPERATIONS =============

  Future<void> createPost({
    required String authorId,
    required String authorName,
    String? content,
    String? mediaUrl,
    String? mediaType,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();

    final companion = PostsMetadataCompanion.insert(
      postId: id,
      authorId: authorId,
      authorName: authorName,
      timestamp: now,
      content: Value(content),
      mediaUrl: Value(mediaUrl),
      mediaType: Value(mediaType),
      isVisible: const Value(true),
    );
    
    await _db.into(_db.postsMetadata).insert(companion);
    
    await _db.addPendingAction('create_post', id, {
      'postId': id,
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'timestamp': now.toIso8601String(),
    });
  }

  Future<void> saveRemotePost(Map<String, dynamic> postData) async {
    final companion = PostsMetadataCompanion.insert(
      postId: postData['id'],
      authorId: postData['authorId'],
      authorName: postData['authorName'],
      timestamp: DateTime.parse(postData['timestamp']),
      content: Value(postData['content'] ?? postData['text']),
      mediaUrl: Value(postData['mediaUrl']),
      mediaType: Value(postData['mediaType']),
      heatScore: Value((postData['heatScore'] ?? 0.0).toDouble()),
      likeCount: Value(postData['likeCount'] ?? 0),
      commentCount: Value(postData['commentCount'] ?? 0),
      shareCount: Value(postData['shareCount'] ?? 0),
      isBookmarked: Value(postData['isBookmarked'] ?? false),
    );
    
    await _db.into(_db.postsMetadata).insertOnConflictUpdate(companion);
  }

  // ============= INTERACTIONS =============

  Future<void> likePost(String postId, String userId) async {
    await _db.customUpdate(
      'UPDATE posts_metadata SET like_count = like_count + 1 WHERE post_id = ?',
      variables: [Variable.withString(postId)],
    );
    
    await _recalculateHeatScore(postId);
    await _db.addPendingAction('like', postId, {'userId': userId});
  }

  Future<void> unlikePost(String postId, String userId) async {
    await _db.customUpdate(
      'UPDATE posts_metadata SET like_count = like_count - 1 WHERE post_id = ? AND like_count > 0',
      variables: [Variable.withString(postId)],
    );
    
    await _recalculateHeatScore(postId);
    await _db.addPendingAction('unlike', postId, {'userId': userId});
  }

  Future<void> commentOnPost(String postId, String userId, String comment) async {
    await _db.customUpdate(
      'UPDATE posts_metadata SET comment_count = comment_count + 1 WHERE post_id = ?',
      variables: [Variable.withString(postId)],
    );
    
    await _recalculateHeatScore(postId);
    await _db.addPendingAction('comment', postId, {
      'userId': userId,
      'comment': comment,
    });
  }

  Future<void> sharePost(String postId, String userId) async {
    await _db.customUpdate(
      'UPDATE posts_metadata SET share_count = share_count + 1 WHERE post_id = ?',
      variables: [Variable.withString(postId)],
    );
    
    await _recalculateHeatScore(postId);
    await _db.addPendingAction('share', postId, {'userId': userId});
  }

  Future<void> toggleBookmark(String postId, bool bookmarked) async {
    await (_db.update(_db.postsMetadata)
          ..where((t) => t.postId.equals(postId)))
        .write(PostsMetadataCompanion(
          isBookmarked: Value(bookmarked),
        ));
  }

  // ============= HEAT SCORE CALCULATION =============

  Future<void> _recalculateHeatScore(String postId) async {
    final post = await (_db.select(_db.postsMetadata)
          ..where((t) => t.postId.equals(postId)))
        .getSingleOrNull();
    
    if (post == null) return;

    final now = DateTime.now();
    final ageInHours = max(1, now.difference(post.timestamp).inHours);
    
    final engagement = post.likeCount + 
                     (post.commentCount * 2) + 
                     (post.shareCount * 3);
    
    final decayFactor = pow(AppConstants.heatDecayFactor, ageInHours / 24).toDouble();
    final heatScore = engagement * decayFactor;
    
    await (_db.update(_db.postsMetadata)
          ..where((t) => t.postId.equals(postId)))
        .write(PostsMetadataCompanion(
          heatScore: Value(heatScore),
        ));
  }

  Future<void> recalculateAllHeatScores() async {
    final posts = await _db.select(_db.postsMetadata).get();
    for (final post in posts) {
      await _recalculateHeatScore(post.postId);
    }
  }

  // ============= FEED QUERIES =============

  Stream<List<PostsMetadataData>> watchFeed() {
    return (_db.select(_db.postsMetadata)
          ..where((t) => t.isVisible.equals(true))
          ..orderBy([
            (t) => OrderingTerm(expression: t.heatScore, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<List<PostsMetadataData>> getFeedPaginated({
    required int limit,
    required int offset,
  }) {
    return (_db.select(_db.postsMetadata)
          ..where((t) => t.isVisible.equals(true))
          ..orderBy([
            (t) => OrderingTerm(expression: t.heatScore, mode: OrderingMode.desc)
          ])
          ..limit(limit, offset: offset))
        .get();
  }

  Stream<List<PostsMetadataData>> watchUserPosts(String userId) {
    return (_db.select(_db.postsMetadata)
          ..where((t) => t.authorId.equals(userId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  // ============= CACHE MANAGEMENT =============

  Future<void> updateFeedVisibility(String postId, bool isVisible) async {
    await (_db.update(_db.postsMetadata)
          ..where((t) => t.postId.equals(postId)))
        .write(PostsMetadataCompanion(isVisible: Value(isVisible)));
  }

  Future<void> clearOldFeedCache() async {
    await _db.clearOldCache();
  }
}