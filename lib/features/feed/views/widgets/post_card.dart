import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:here/core/database/database.dart';
import 'package:here/shared/widgets/media_preview.dart';

class PostCard extends ConsumerWidget {
  final PostsMetadataData post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onBookmark;
  final VoidCallback onTap;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onBookmark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              timeago.format(post.timestamp),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Heat score indicator
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: post.heatScore > 10
                                    ? Colors.orange.shade50
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.whatshot,
                                    size: 10,
                                    color: post.heatScore > 10
                                        ? Colors.orange
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    post.heatScore.toStringAsFixed(1),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: post.heatScore > 10
                                          ? Colors.orange.shade700
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      post.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    ),
                    onPressed: onBookmark,
                    iconSize: 20,
                  ),
                ],
              ),
              
              // Text content
              if (post.text != null && post.text!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  post.text!,
                  style: GoogleFonts.inter(fontSize: 14),
                ),
              ],
              
              // Media content
              if (post.mediaUrl != null && post.mediaUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                MediaPreview(
                  mediaUrl: post.mediaUrl!,
                  mediaType: post.mediaType ?? 'image',
                  isThumbnail: true,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  onTap: () {
                    // Open full screen
                    // TODO: Navigate to full screen media
                  },
                ),
              ],
              
              // Engagement stats
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatItem(
                    context,
                    icon: Icons.favorite,
                    count: post.likeCount,
                    color: Colors.red,
                    onTap: onLike,
                  ),
                  const SizedBox(width: 16),
                  _buildStatItem(
                    context,
                    icon: Icons.chat_bubble_outline,
                    count: post.commentCount,
                    onTap: onComment,
                  ),
                  const SizedBox(width: 16),
                  _buildStatItem(
                    context,
                    icon: Icons.share_outlined,
                    count: post.shareCount,
                    onTap: onShare,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required int count,
    Color? color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: color ?? theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 4),
            Text(
              _formatCount(count),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}