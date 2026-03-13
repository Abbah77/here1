import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// Internal Package Imports
import 'package:here/core/providers/theme_provider.dart';
import 'package:here/features/auth/providers/auth_provider.dart';
import 'package:here/features/auth/views/screens/auth_screen.dart';

// Feature-relative Widget Imports
import '../widgets/profile_header.dart';
import '../widgets/profile_stats.dart';
import '../widgets/profile_tabs.dart';

class ProfileScreen extends HookConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Watch Theme & Auth State
    final currentAppTheme = ref.watch(themeProvider);
    final currentUserAsync = ref.watch(currentUserProvider);
    
    final isDark = currentAppTheme == AppTheme.dark ||
        (currentAppTheme == AppTheme.system &&
            View.of(context).platformDispatcher.platformBrightness == Brightness.dark);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: currentUserAsync.when(
        data: (userMap) {
          if (userMap == null) {
            return const Center(child: Text('Not logged in'));
          }
          
          // Data extraction for the AppBar
          final String displayName = userMap['full_name'] ?? userMap['username'] ?? 'Profile';
          final String userId = userMap['id']?.toString() ?? '';
          
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: theme.colorScheme.surface,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    displayName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                    onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
                  ),
                  _buildSettingsMenu(context, ref),
                ],
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // FIXED: Using 'userData' parameter to match our refactored ProfileHeader
                    ProfileHeader(userData: userMap),
                    
                    // FIXED: Using 'userData' for stats to ensure no type mismatch errors
                    ProfileStats(userData: userMap),
                    
                    // FIXED: Passing userId string to tabs for database queries
                    ProfileTabs(userId: userId),
                  ],
                ),
              ),
            ],
          );
        },
        error: (error, _) => Center(child: Text('User Error: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  // ... (_buildSettingsMenu and _showLogoutDialog remain unchanged)
  
  Widget _buildSettingsMenu(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.settings_outlined),
      onSelected: (value) {
        if (value == 'logout') _showLogoutDialog(context, ref);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit Profile')),
        const PopupMenuItem(
          value: 'logout', 
          child: Text('Logout', style: TextStyle(color: Colors.red))
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Cancel')
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
