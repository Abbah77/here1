import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../core/services/media_service.dart';

class MediaPreview extends StatefulWidget {
  final String mediaUrl;
  final String mediaType;
  final bool isThumbnail;
  final double? width;
  final double? height;
  final BoxFit fit;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const MediaPreview({
    super.key,
    required this.mediaUrl,
    required this.mediaType,
    this.isThumbnail = false,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<MediaPreview> createState() => _MediaPreviewState();
}

class _MediaPreviewState extends State<MediaPreview> {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.mediaType == 'video' && !widget.isThumbnail) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.network(widget.mediaUrl);
    await _videoController!.initialize();
    setState(() => _isInitialized = true);
    _videoController!.setLooping(true);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.surface,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Media content
            if (widget.mediaType == 'image')
              _buildImage()
            else if (widget.mediaType == 'video')
              _buildVideo(),
            
            // Play button overlay for videos
            if (widget.mediaType == 'video' && widget.isThumbnail)
              Container(
                color: Colors.black26,
                child: Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return CachedNetworkImage(
      imageUrl: widget.mediaUrl,
      fit: widget.fit,
      placeholder: (context, url) => Container(
        color: Colors.grey[300],
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }

  Widget _buildVideo() {
    if (widget.isThumbnail) {
      // Show thumbnail for video previews
      final thumbnailUrl = widget.mediaUrl.replaceFirst(
        RegExp(r'\.mp4$'),
        '_thumb.jpg',
      );
      return _buildImage(); // Will use thumbnail URL
    }

    if (!_isInitialized) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: VideoPlayer(_videoController!),
    );
  }
}