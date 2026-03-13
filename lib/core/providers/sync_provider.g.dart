// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$connectivityStreamHash() =>
    r'2b9c6b00272455180b3b92776f6caae413ddc00f';

/// 2. Connectivity stream - uses the new List return type for connectivity_plus 6.x
///
/// Copied from [connectivityStream].
@ProviderFor(connectivityStream)
final connectivityStreamProvider =
    AutoDisposeStreamProvider<List<ConnectivityResult>>.internal(
  connectivityStream,
  name: r'connectivityStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$connectivityStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ConnectivityStreamRef
    = AutoDisposeStreamProviderRef<List<ConnectivityResult>>;
String _$syncStateHash() => r'da2b2e6db9c43ad3793471f571a9fd559dce71d1';

/// 1. State provider for the UI to show "Syncing..." or "Success"
///
/// Copied from [SyncState].
@ProviderFor(SyncState)
final syncStateProvider =
    AutoDisposeNotifierProvider<SyncState, SyncStatus>.internal(
  SyncState.new,
  name: r'syncStateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$syncStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SyncState = AutoDisposeNotifier<SyncStatus>;
String _$syncHash() => r'292c445c31d9178f07efe771af864cdcfe3fcc90';

/// 3. The Main Sync Logic (Renamed to 'Sync' to generate 'syncProvider')
///
/// Copied from [Sync].
@ProviderFor(Sync)
final syncProvider = AutoDisposeAsyncNotifierProvider<Sync, void>.internal(
  Sync.new,
  name: r'syncProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$syncHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Sync = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
