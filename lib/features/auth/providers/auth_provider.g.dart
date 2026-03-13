// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$usernameAvailabilityHash() =>
    r'24bf0359c8085c6f177c7edab49da01532e2ad3f';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [usernameAvailability].
@ProviderFor(usernameAvailability)
const usernameAvailabilityProvider = UsernameAvailabilityFamily();

/// See also [usernameAvailability].
class UsernameAvailabilityFamily extends Family<AsyncValue<bool>> {
  /// See also [usernameAvailability].
  const UsernameAvailabilityFamily();

  /// See also [usernameAvailability].
  UsernameAvailabilityProvider call(
    String username,
  ) {
    return UsernameAvailabilityProvider(
      username,
    );
  }

  @override
  UsernameAvailabilityProvider getProviderOverride(
    covariant UsernameAvailabilityProvider provider,
  ) {
    return call(
      provider.username,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'usernameAvailabilityProvider';
}

/// See also [usernameAvailability].
class UsernameAvailabilityProvider extends AutoDisposeFutureProvider<bool> {
  /// See also [usernameAvailability].
  UsernameAvailabilityProvider(
    String username,
  ) : this._internal(
          (ref) => usernameAvailability(
            ref as UsernameAvailabilityRef,
            username,
          ),
          from: usernameAvailabilityProvider,
          name: r'usernameAvailabilityProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$usernameAvailabilityHash,
          dependencies: UsernameAvailabilityFamily._dependencies,
          allTransitiveDependencies:
              UsernameAvailabilityFamily._allTransitiveDependencies,
          username: username,
        );

  UsernameAvailabilityProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.username,
  }) : super.internal();

  final String username;

  @override
  Override overrideWith(
    FutureOr<bool> Function(UsernameAvailabilityRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UsernameAvailabilityProvider._internal(
        (ref) => create(ref as UsernameAvailabilityRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        username: username,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _UsernameAvailabilityProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UsernameAvailabilityProvider && other.username == username;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, username.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UsernameAvailabilityRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `username` of this provider.
  String get username;
}

class _UsernameAvailabilityProviderElement
    extends AutoDisposeFutureProviderElement<bool>
    with UsernameAvailabilityRef {
  _UsernameAvailabilityProviderElement(super.provider);

  @override
  String get username => (origin as UsernameAvailabilityProvider).username;
}

String _$authNotifierHash() => r'53d9e0f864713e4ce7f495038aef5ecd13683e49';

/// Use 'AuthNotifier' to avoid conflict with the generated 'authProvider' name
///
/// Copied from [AuthNotifier].
@ProviderFor(AuthNotifier)
final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthStatus>.internal(
  AuthNotifier.new,
  name: r'authNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$authNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AuthNotifier = AsyncNotifier<AuthStatus>;
String _$currentUserHash() => r'dd4c6a55c39fd4a65d3ef245cbf077f17ba06506';

/// See also [CurrentUser].
@ProviderFor(CurrentUser)
final currentUserProvider = AutoDisposeAsyncNotifierProvider<CurrentUser,
    Map<String, dynamic>?>.internal(
  CurrentUser.new,
  name: r'currentUserProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$currentUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CurrentUser = AutoDisposeAsyncNotifier<Map<String, dynamic>?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
