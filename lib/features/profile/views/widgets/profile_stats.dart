import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// Absolute path to resolve UserProfile
import 'package:here/core/database/database.dart';

class ProfileStats extends ConsumerWidget {
  // FIXED: Changed from 'required' to optional '?' and added userData Map
  final UserProfile? profile;
  final Map<String, dynamic>? userData;

  const ProfileStats({
    super.key, 
    this.profile, 
    this.userData, // Added to allow Map input from ProfileScreen
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Logic: Pull stats from Object if available, otherwise from Map
    final postCount = profile?.postCount ?? userData?['post_count'] ?? 0;
    final followerCount = profile?.followerCount ?? userData?['follower_count'] ?? 0;
    final followingCount = profile?.followingCount ?? userData?['following_count'] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
          bottom: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            'Posts',
            postCount,
            onTap: () {},
          ),
          _buildStatItem(
            context,
            'Followers',
            followerCount,
            onTap: () {},
          ),
          _buildStatItem(
            context,
            'Following',
            followingCount,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // ... (_buildStatItem and _formatCount remain the same logic)

  Widget _buildStatItem(
    BuildContext context,
    String label,
    int value, {
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            Text(
              _formatCount(value),
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
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
