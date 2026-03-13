import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/media_provider.dart';
import '../../core/services/media_service.dart';

class MediaPickerSheet extends ConsumerWidget {
  final Function(MediaFile) onMediaSelected;
  final bool allowMultiple;
  final bool allowVideos;

  const MediaPickerSheet({
    super.key,
    required this.onMediaSelected,
    this.allowMultiple = false,
    this.allowVideos = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mediaService = ref.read(mediaServiceProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Text(
              'Add Media',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            
            // Options
            _buildOption(
              context,
              icon: Icons.camera_alt,
              label: 'Take Photo',
              onTap: () async {
                Navigator.pop(context);
                final media = await mediaService.pickImage(fromCamera: true);
                if (media != null) {
                  onMediaSelected(media);
                }
              },
            ),
            
            _buildOption(
              context,
              icon: Icons.photo_library,
              label: 'Choose from Gallery',
              onTap: () async {
                Navigator.pop(context);
                final media = await mediaService.pickImage(fromCamera: false);
                if (media != null) {
                  onMediaSelected(media);
                }
              },
            ),
            
            if (allowVideos)
              _buildOption(
                context,
                icon: Icons.videocam,
                label: 'Record Video',
                onTap: () async {
                  Navigator.pop(context);
                  final media = await mediaService.pickVideo(fromCamera: true);
                  if (media != null) {
                    onMediaSelected(media);
                  }
                },
              ),
            
            if (allowVideos)
              _buildOption(
                context,
                icon: Icons.video_library,
                label: 'Choose Video',
                onTap: () async {
                  Navigator.pop(context);
                  final media = await mediaService.pickVideo(fromCamera: false);
                  if (media != null) {
                    onMediaSelected(media);
                  }
                },
              ),
            
            const SizedBox(height: 8),
            
            // Cancel button
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 24,
        ),
      ),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}