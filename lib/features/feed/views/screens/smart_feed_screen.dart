import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// Internal Package Imports
import 'package:here/core/database/database.dart';
import 'package:here/core/services/ai_service.dart';
import 'package:here/features/auth/providers/auth_provider.dart';

// Feature-relative Widget Imports
import '../widgets/post_card.dart';
import '../widgets/trending_topics_widget.dart';

class SmartFeedScreen extends HookConsumerWidget {
  const SmartFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationsAsync = ref.watch(_recommendationsProvider);
    final trendingTopicsAsync = ref.watch(_trendingTopicsProvider);
    final similarUsersAsync = ref.watch(_similarUsersProvider);
    
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Smart Feed',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 24,
            ),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'For You'),
              Tab(text: 'Trending'),
              Tab(text: 'Discover'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _forYouTab(context, recommendationsAsync),
            _trendingTab(context, trendingTopicsAsync),
            _discoverTab(context, similarUsersAsync),
          ],
        ),
      ),
    );
  }
  
  // ================= TAB BUILDERS =================

  Widget _forYouTab(BuildContext context, AsyncValue<List<Map<String, dynamic>>> asyncVal) {
    return asyncVal.when(
      data: (items) => items.isEmpty 
          ? _emptyState('No recommendations yet') 
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final dynamic rawPost = item['post'];
                
                // FIXED: Providing ALL 11 required parameters for PostsMetadataData
                // This resolves the 'missing_required_argument' and 'undefined_named_parameter' errors.
                final PostsMetadataData postData = (rawPost is Map) 
                    ? PostsMetadataData(
                        postId: rawPost['postId']?.toString() ?? rawPost['id']?.toString() ?? '',
                        authorId: rawPost['authorId']?.toString() ?? rawPost['author_id']?.toString() ?? '',
                        authorName: rawPost['authorName']?.toString() ?? 'User',
                        content: rawPost['content']?.toString() ?? '',
                        timestamp: DateTime.tryParse(rawPost['timestamp']?.toString() ?? '') ?? DateTime.now(),
                        likeCount: rawPost['likeCount'] ?? 0,
                        commentCount: rawPost['commentCount'] ?? 0,
                        shareCount: rawPost['shareCount'] ?? 0,
                        heatScore: (rawPost['heatScore'] as num?)?.toDouble() ?? 0.0,
                        isBookmarked: rawPost['isBookmarked'] ?? false,
                        isVisible: rawPost['isVisible'] ?? true,
                      )
                    : rawPost as PostsMetadataData;

                return Column(
                  children: [
                    if (index == 0) _aiHeader(context),
                    PostCard(
                      post: postData, 
                      onLike: () {},
                      onComment: () {},
                      onShare: () {},
                      onBookmark: () {},
                      onTap: () {},
                    ),
                    if (item['reason'] != null)
                      _reasonBadge(item['reason'].toString()),
                  ],
                );
              },
            ),
      error: (e, _) => Center(child: Text('Error: $e')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _trendingTab(BuildContext context, AsyncValue<List<Map<String, dynamic>>> asyncVal) {
    return asyncVal.when(
      data: (topics) => TrendingTopicsWidget(topics: topics),
      error: (e, _) => Center(child: Text('Error: $e')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _discoverTab(BuildContext context, AsyncValue<List<Map<String, dynamic>>> asyncVal) {
    return asyncVal.when(
      data: (users) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final String? profilePic = user['profile_pic_url']?.toString();
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: (profilePic != null && profilePic.isNotEmpty)
                    ? NetworkImage(profilePic) 
                    : null,
                child: (profilePic == null || profilePic.isEmpty) 
                    ? const Icon(Icons.person) 
                    : null,
              ),
              title: Text(user['full_name'] ?? 'User'),
              subtitle: Text('@${user['username'] ?? 'unknown'}'),
              trailing: Text('${((user['similarity_score'] ?? 0.8) * 100).toInt()}% match'),
            ),
          );
        },
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  // ================= UI COMPONENTS =================

  Widget _aiHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // FIXED: Using withOpacity for Codemagic compatibility
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Text('AI-curated for you', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _reasonBadge(String reason) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text('✨ $reason', style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(child: Text(message, style: GoogleFonts.poppins(fontSize: 16)));
  }
}

// ================= PRIVATE PROVIDERS =================

final _recommendationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final aiService = ref.read(aiServiceProvider);
  final user = ref.read(currentUserProvider).value;
  final userId = user?['id']?.toString() ?? 'guest';
  
  final results = await aiService.getPostRecommendations(userId);
  return results.cast<Map<String, dynamic>>();
});

final _trendingTopicsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final aiService = ref.read(aiServiceProvider);
  final results = await aiService.getTrendingTopics();
  return results.cast<Map<String, dynamic>>();
});

final _similarUsersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final aiService = ref.read(aiServiceProvider);
  final user = ref.read(currentUserProvider).value;
  final userId = user?['id']?.toString() ?? 'guest';

  final dynamic rawData = await aiService.getSimilarUsers(userId);
  
  if (rawData is! List) return <Map<String, dynamic>>[];

  // Use .from to explicitly tell the compiler we are creating a list of Maps
  return List<Map<String, dynamic>>.from(
    rawData.map((item) {
      if (item is Map) {
        return Map<String, dynamic>.from(item);
      }
      // Wrap the string in a Map structure so the types match perfectly
      return <String, dynamic>{
        'username': item.toString(),
        'full_name': 'Discovery User',
        'similarity_score': 0.82,
        'profile_pic_url': null,
      };
    }),
  );
});
