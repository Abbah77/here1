import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// Import the database if you need specific types, but we'll use dynamic for flexibility
import 'package:here/core/database/database.dart';

class ProfileHeader extends ConsumerWidget {
  // FIXED: We make both optional so the widget doesn't crash if one is missing.
  // We prioritize 'profile' (the object) but fallback to 'userData' (the Map).
  final UserProfile? profile; 
  final Map<String, dynamic>? userData;

  const ProfileHeader({
    super.key,
    this.profile,
    this.userData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Logic: Try to get data from the Object first, then the Map
    final displayName = profile?.displayName ?? userData?['full_name'] ?? userData?['displayName'] ?? 'User';
    final username = profile?.username ?? userData?['username'] ?? 'username';
    final bio = profile?.bio ?? userData?['bio'];
    final profilePic = profile?.profilePicUrl ?? userData?['profile_pic_url'];
    final isVerified = profile?.isVerified ?? (userData?['is_verified'] ?? false);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar Stack
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 3,
                  ),
                ),
                child: _buildAvatar(theme, profilePic),
              ),
              _buildCameraIcon(theme),
              if (isVerified) _buildVerifiedBadge(),
            ],
          ),
          const SizedBox(height: 16),
          
          // Name
          Text(
            displayName,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          
          // Username
          Text(
            '@$username',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          
          // Bio
          if (bio != null && bio.toString().isNotEmpty)
            Text(
              bio.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          const SizedBox(height: 20),
          
          // Edit Profile Button
          _buildEditButton(theme),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildAvatar(ThemeData theme, String? url) {
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultIcon(theme),
        ),
      );
    }
    return _defaultIcon(theme);
  }

  Widget _defaultIcon(ThemeData theme) => Icon(
        Icons.person,
        size: 50,
        color: theme.colorScheme.primary,
      );

  Widget _buildCameraIcon(ThemeData theme) => Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: theme.scaffoldBackgroundColor, width: 3),
          ),
          child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
        ),
      );

  Widget _buildVerifiedBadge() => Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
          child: const Icon(Icons.check, size: 12, color: Colors.white),
        ),
      );

  Widget _buildEditButton(ThemeData theme) => SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {}, 
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: BorderSide(color: theme.colorScheme.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: Text(
            'Edit Profile',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      );
}
