import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

// Package Imports
import 'package:here/core/providers/database_provider.dart';
import 'package:here/core/providers/media_provider.dart';
import 'package:here/shared/widgets/media_picker_sheet.dart';
import 'package:here/core/services/media_service.dart';

class CreatePostWidget extends HookConsumerWidget {
  const CreatePostWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = useTextEditingController();
    final selectedMedia = ref.watch(selectedMediaProvider);
    final isPosting = useState(false);
    final theme = Theme.of(context);

    Future<void> _pickMedia() async {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => MediaPickerSheet(
          onMediaSelected: (media) {
            ref.read(selectedMediaProvider.notifier).addMedia(media);
          },
          allowMultiple: true,
          allowVideos: true,
        ),
      );
    }

    Future<void> _createPost() async {
      if (textController.text.isEmpty && selectedMedia.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add some content to your post'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      isPosting.value = true;

      try {
        final feedRepo = ref.read(feedRepositoryProvider);
        final mediaService = ref.read(mediaServiceProvider);
        
        String? mediaUrl;
        String? mediaType;
        
        if (selectedMedia.isNotEmpty) {
          final media = selectedMedia.first;
          mediaUrl = media.optimizedPath; 
          mediaType = media.mediaType;
        }

        // FIXED: Using 'content' instead of 'text' and adding the required 'postId'
        await feedRepo.createPost(
          postId: const Uuid().v4(), // Generates a unique ID
          authorId: 'current_user_id',
          authorName: 'Current User',
          content: textController.text, 
          mediaUrl: mediaUrl,
          mediaType: mediaType,
        );

        // Clean up temp files
        for (final media in selectedMedia) {
          await mediaService.deleteMediaFile(media);
        }
        
        ref.read(selectedMediaProvider.notifier).clear();
        
        if (context.mounted) Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        isPosting.value = false;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Create Post',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Icon(Icons.person, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current User',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Public',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                maxLines: 5,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: "What's on your mind?",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
              ),
              if (selectedMedia.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: selectedMedia.length,
                    itemBuilder: (context, index) {
                      final media = selectedMedia[index];
                      return Stack(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: media.isImage
                                  ? DecorationImage(
                                      image: FileImage(File(media.thumbnailPath)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              color: Colors.grey[300],
                            ),
                            child: media.isVideo
                                ? const Center(child: Icon(Icons.play_arrow))
                                : null,
                          ),
                          Positioned(
                            top: 0,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                ref.read(selectedMediaProvider.notifier)
                                    .removeMedia(media.id);
                              },
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(2),
                                child: const Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickMedia,
                      icon: const Icon(Icons.image),
                      label: const Text('Add Media'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isPosting.value ? null : _createPost,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: isPosting.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text('Post'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}