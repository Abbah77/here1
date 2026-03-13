// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$mediaServiceHash() => r'1deec1993351fd434494ea12fa1caad028c1cda5';

/// See also [mediaService].
@ProviderFor(mediaService)
final mediaServiceProvider = Provider<MediaService>.internal(
  mediaService,
  name: r'mediaServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$mediaServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MediaServiceRef = ProviderRef<MediaService>;
String _$selectedMediaHash() => r'9ece149f0d8d335c2c1ce8182988e2b6a448e3d6';

/// See also [SelectedMedia].
@ProviderFor(SelectedMedia)
final selectedMediaProvider =
    AutoDisposeNotifierProvider<SelectedMedia, List<MediaFile>>.internal(
  SelectedMedia.new,
  name: r'selectedMediaProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedMediaHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedMedia = AutoDisposeNotifier<List<MediaFile>>;
String _$mediaUploadProgressHash() =>
    r'be14e92f5953d7e179a6ba66deb87748bc925033';

/// See also [MediaUploadProgress].
@ProviderFor(MediaUploadProgress)
final mediaUploadProgressProvider = AutoDisposeNotifierProvider<
    MediaUploadProgress, Map<String, double>>.internal(
  MediaUploadProgress.new,
  name: r'mediaUploadProgressProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$mediaUploadProgressHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MediaUploadProgress = AutoDisposeNotifier<Map<String, double>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
