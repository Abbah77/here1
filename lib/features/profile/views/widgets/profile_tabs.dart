import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileTabs extends HookConsumerWidget {
  // Added userId parameter to match how it's called in ProfileScreen
  final String? userId;
  
  const ProfileTabs({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hooks handle the controller lifecycle automatically
    final tabController = useTabController(initialLength: 2);
    final theme = Theme.of(context);

    return Column(
      children: [
        TabBar(
          controller: tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          // KEPT: withOpacity for Codemagic
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
          tabs: const [
            Tab(text: 'Posts'),
            Tab(text: 'Saved'),
          ],
        ),
        SizedBox(
          height: 600, // Increased height slightly to prevent overflow on larger screens
          child: TabBarView(
            controller: tabController,
            children: [
              _buildPostsGrid(context),
              _buildSavedGrid(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostsGrid(BuildContext context) {
    final theme = Theme.of(context);
    
    return GridView.builder(
      // Important for nested scrolling in CustomScrollView
      physics: const NeverScrollableScrollPhysics(), 
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: 9, // Placeholder for now
      itemBuilder: (context, index) {
        return Container(
          color: theme.colorScheme.primary.withOpacity(0.1),
          child: Center(
            child: Icon(
              Icons.image,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedGrid(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 60,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No saved posts yet',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}