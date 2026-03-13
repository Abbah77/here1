import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart'; // ADD THIS IMPORT
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../network/api_client.dart'; // FIXED PATH

class MediaService {
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  final ImagePicker _picker = ImagePicker();
  final _uuid = const Uuid();

  // ============= IMAGE PICKING =============

  Future<MediaFile?> pickImage({bool fromCamera = false}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return null;

      return await _processImage(File(image.path));
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  Future<MediaFile?> pickVideo({bool fromCamera = false}) async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxDuration: const Duration(seconds: 60),
      );

      if (video == null) return null;

      return await _processVideo(File(video.path));
    } catch (e) {
      debugPrint('Error picking video: $e');
      return null;
    }
  }

  // ============= IMAGE PROCESSING =============

  Future<MediaFile> _processImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(bytes);
    
    if (originalImage == null) {
      throw Exception('Failed to decode image');
    }

    // Generate thumbnail
    final thumbnail = _generateThumbnail(originalImage);
    
    // Save thumbnail to temporary file
    final tempDir = await getTemporaryDirectory();
    final thumbnailPath = path.join(
      tempDir.path,
      'thumb_${_uuid.v4()}.jpg',
    );
    await File(thumbnailPath).writeAsBytes(thumbnail);

    // Optimize original image for upload
    final optimizedImage = _optimizeImage(originalImage);
    final optimizedPath = path.join(
      tempDir.path,
      'opt_${_uuid.v4()}.jpg',
    );
    await File(optimizedPath).writeAsBytes(optimizedImage);

    return MediaFile(
      id: _uuid.v4(),
      originalPath: imageFile.path,
      optimizedPath: optimizedPath,
      thumbnailPath: thumbnailPath,
      mediaType: 'image',
      width: originalImage.width,
      height: originalImage.height,
      size: await imageFile.length(),
    );
  }

  Uint8List _generateThumbnail(img.Image originalImage) {
    final thumbWidth = AppConstants.thumbnailMaxWidth;
    final thumbHeight = (originalImage.height * thumbWidth / originalImage.width)
        .round()
        .clamp(1, AppConstants.thumbnailMaxHeight);
    
    final thumbnail = img.copyResize(
      originalImage,
      width: thumbWidth,
      height: thumbHeight,
    );
    
    return Uint8List.fromList(
      img.encodeJpg(thumbnail, quality: AppConstants.thumbnailQuality),
    );
  }

  Uint8List _optimizeImage(img.Image originalImage) {
    const maxDimension = 1920;
    img.Image optimized = originalImage;
    
    if (originalImage.width > maxDimension || originalImage.height > maxDimension) {
      if (originalImage.width > originalImage.height) {
        optimized = img.copyResize(originalImage, width: maxDimension);
      } else {
        optimized = img.copyResize(originalImage, height: maxDimension);
      }
    }
    
    return Uint8List.fromList(
      img.encodeJpg(optimized, quality: 80),
    );
  }

  // ============= VIDEO PROCESSING =============

  Future<MediaFile> _processVideo(File videoFile) async {
    final thumbnailBytes = await VideoThumbnail.thumbnailData(
      video: videoFile.path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: AppConstants.thumbnailMaxWidth,
      quality: AppConstants.thumbnailQuality,
    );

    if (thumbnailBytes == null) {
      throw Exception('Failed to generate video thumbnail');
    }

    final tempDir = await getTemporaryDirectory();
    final thumbnailPath = path.join(
      tempDir.path,
      'thumb_${_uuid.v4()}.jpg',
    );
    await File(thumbnailPath).writeAsBytes(thumbnailBytes);

    return MediaFile(
      id: _uuid.v4(),
      originalPath: videoFile.path,
      optimizedPath: videoFile.path,
      thumbnailPath: thumbnailPath,
      mediaType: 'video',
      width: null,
      height: null,
      size: await videoFile.length(),
    );
  }

  // ============= CACHE MANAGEMENT =============

  Future<void> clearTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      
      for (var file in files) {
        if (file is File) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('Error clearing temp files: $e');
    }
  }

  Future<void> deleteMediaFile(MediaFile mediaFile) async {
    try {
      if (mediaFile.thumbnailPath.isNotEmpty) {
        await File(mediaFile.thumbnailPath).delete();
      }
      if (mediaFile.optimizedPath.isNotEmpty) {
        await File(mediaFile.optimizedPath).delete();
      }
    } catch (e) {
      debugPrint('Error deleting media file: $e');
    }
  }

  // ============= BACKEND UPLOAD METHODS =============
  
  // Upload to backend - FIXED: Added Ref parameter
  Future<String> uploadToServer(Ref ref, MediaFile media, {String mediaType = 'post'}) async {
    try {
      final api = ref.read(apiClientProvider);
      
      // Create form data
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          media.optimizedPath,
          filename: '${media.id}.${media.mediaType == 'image' ? 'jpg' : 'mp4'}',
        ),
        'mediaType': mediaType,
      });
      
      // Upload
      final response = await api.uploadMedia(formData);
      
      return response['url'];
    } catch (e) {
      throw Exception('Failed to upload media: $e');
    }
  }
  
  // Get optimized image URL
  String getOptimizedImageUrl(String url, {int? width, int? height, int quality = 80}) {
    if (url.isEmpty) return url;
    
    final uri = Uri.parse(url);
    final params = <String, String>{};
    
    if (width != null) params['width'] = width.toString();
    if (height != null) params['height'] = height.toString();
    params['quality'] = quality.toString();
    
    return uri.replace(queryParameters: params).toString();
  }
  
  // Get video thumbnail URL
  String getVideoThumbnailUrl(String videoUrl) {
    return videoUrl.replaceFirst(RegExp(r'\.mp4$'), '_thumb.jpg');
  }
  
  // Delete from server
  Future<void> deleteFromServer(Ref ref, String url) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.deleteMedia(url);
    } catch (e) {
      debugPrint('Failed to delete media: $e');
    }
  }
}

// ============= MEDIA FILE MODEL =============

class MediaFile {
  final String id;
  final String originalPath;
  final String optimizedPath;
  final String thumbnailPath;
  final String mediaType;
  final int? width;
  final int? height;
  final int size;

  MediaFile({
    required this.id,
    required this.originalPath,
    required this.optimizedPath,
    required this.thumbnailPath,
    required this.mediaType,
    this.width,
    this.height,
    required this.size,
  });

  bool get isImage => mediaType == 'image';
  bool get isVideo => mediaType == 'video';
}