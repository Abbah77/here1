import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/media_service.dart';

part 'media_provider.g.dart';

@Riverpod(keepAlive: true)
MediaService mediaService(MediaServiceRef ref) {
  return MediaService();
}

@riverpod
class SelectedMedia extends _$SelectedMedia {
  @override
  List<MediaFile> build() => [];

  void addMedia(MediaFile media) {
    state = [...state, media];
  }

  void removeMedia(String mediaId) {
    state = state.where((m) => m.id != mediaId).toList();
  }

  void clear() {
    state = [];
  }
}

@riverpod
class MediaUploadProgress extends _$MediaUploadProgress {
  @override
  Map<String, double> build() => {};

  void updateProgress(String mediaId, double progress) {
    state = {...state, mediaId: progress};
  }

  void removeProgress(String mediaId) {
    final newMap = Map<String, double>.from(state);
    newMap.remove(mediaId);
    state = newMap;
  }

  void clear() {
    state = {};
  }
}