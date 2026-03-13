import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart';

// UI Widgets
import '../widgets/post_card.dart';
import '../widgets/create_post_widget.dart';

// FIXED: Absolute paths
import 'package:here/core/providers/database_provider.dart';
import 'package:here/core/providers/sync_provider.dart'; // Ensure this file exists
import 'package:here/core/database/database.dart'; 
import 'package:here/shared/widgets/sync_status_widget.dart';
import 'post_detail_screen.dart';

// FIXED: Feed stream logic using the Drift database instance
final feedStreamProvider = StreamProvider<List<PostsMetadataData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.postsMetadata)
    ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)]))
    .watch();
});

class FeedScreen extends HookConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedStreamProvider);
    final scrollController = useScrollController();
    final isRefreshing = useState(false);
    final theme = Theme.of(context);

    Future<void> _refreshFeed() async {
      isRefreshing.value = true;
      HapticFeedback.mediumImpact();
      
      try {
        // FIXED: Using 'syncProvider' (the most likely name generated from sync_provider.dart)
        // If your class in sync_provider.dart is SyncNotifier, use syncNotifierProvider.notifier
        await ref.read(syncProvider.notifier).syncFeed(); 
      } catch (e) {
        debugPrint('Refresh failed: $e');
      } finally {
        isRefreshing.value = false;
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Feed',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 24),
        ),
        actions: [
          const SyncStatusWidget(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshFeed,
        color: theme.colorScheme.primary,
        child: feedAsync.when(
          data: (posts) {
            if (posts.isEmpty) return _buildEmptyState(context);
            
            return ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return PostCard(
                  post: post,
                  onLike: () => HapticFeedback.lightImpact(),
                  onComment: () => _showComments(context, post),
                  onShare: () => _sharePost(context, post),
                  onBookmark: () => HapticFeedback.lightImpact(),
                  onTap: () => _openPostDetail(context, post),
                );
              },
            );
          },
          error: (error, stack) => Center(child: Text('Error: $error')),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePost(context),
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      ),
    );
  }

  // --- UI HELPER METHODS ---
  void _showCreatePost(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreatePostWidget(),
    );
  }

  void _showComments(BuildContext context, PostsMetadataData post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: const Center(child: Text("Comments logic here")),
      ),
    );
  }

  void _sharePost(BuildContext context, PostsMetadataData post) {}

  void _openPostDetail(BuildContext context, PostsMetadataData post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(post: post),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const Center(child: Text("No posts yet"));
  }
}
