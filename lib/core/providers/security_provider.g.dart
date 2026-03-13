// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'security_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$encryptionServiceHash() => r'38c86d5786979d73370b3ffaa6baceb66c7f33a0';

/// See also [encryptionService].
@ProviderFor(encryptionService)
final encryptionServiceProvider = Provider<EncryptionService>.internal(
  encryptionService,
  name: r'encryptionServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$encryptionServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef EncryptionServiceRef = ProviderRef<EncryptionService>;
String _$messageEncryptionHash() => r'9a747cf1da4932e2b32021965f8ee21606e14eb9';

/// See also [messageEncryption].
@ProviderFor(messageEncryption)
final messageEncryptionProvider =
    AutoDisposeProvider<MessageEncryption>.internal(
  messageEncryption,
  name: r'messageEncryptionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$messageEncryptionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MessageEncryptionRef = AutoDisposeProviderRef<MessageEncryption>;
String _$localDataEncryptionHash() =>
    r'2047c83fd28a6a3a03f9c69df4cd6842658c60d1';

/// See also [localDataEncryption].
@ProviderFor(localDataEncryption)
final localDataEncryptionProvider =
    AutoDisposeProvider<LocalDataEncryption>.internal(
  localDataEncryption,
  name: r'localDataEncryptionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$localDataEncryptionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LocalDataEncryptionRef = AutoDisposeProviderRef<LocalDataEncryption>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
