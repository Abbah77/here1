import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sodium_libs/sodium_libs.dart';
import 'package:flutter/foundation.dart';

// ignore_for_file: undefined_method, invalid_use_of_internal_member

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final _secureStorage = const FlutterSecureStorage();
  late Sodium _sodium;
  bool _initialized = false;
  
  static const String _masterKeyKey = 'master_encryption_key';
  static const String _identityKeyPairPublic = 'identity_public_key';
  static const String _identityKeyPairSecret = 'identity_secret_key';
  
  Uint8List? _masterKey;
  KeyPair? _identityKeyPair;
  
  // ============= INITIALIZATION =============
  
  Future<void> initialize() async {
    if (_initialized) return;
    _sodium = await SodiumInit.init();
    await _ensureMasterKey();
    await _ensureIdentityKeys();
    _initialized = true;
  }

  // ============= GETTERS FOR PROVIDERS =============

  Future<String> getPublicIdentityKey() async {
    await _ensureIdentityKeys();
    return base64.encode(_identityKeyPair!.publicKey);
  }

  Future<String> getDatabaseKey() async {
    final key = await _ensureMasterKey();
    return key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
  
  // ============= MASTER KEY MANAGEMENT =============
  
  Future<Uint8List> _ensureMasterKey() async {
    if (_masterKey != null) return _masterKey!;
    final existingKey = await _secureStorage.read(key: _masterKeyKey);
    
    if (existingKey != null) {
      _masterKey = base64.decode(existingKey);
    } else {
      _masterKey = _sodium.randombytes.buf(32); 
      await _secureStorage.write(key: _masterKeyKey, value: base64.encode(_masterKey!));
    }
    return _masterKey!;
  }

  // ============= LOCAL ENCRYPTION =============

  Future<String> encryptLocal(String plainText) async {
    final key = await _ensureMasterKey();
    final nonce = _sodium.randombytes.buf(_sodium.crypto.secretBox.nonceBytes);
    
    final encrypted = _sodium.crypto.secretBox.easy(
      message: utf8.encoder.convert(plainText),
      nonce: nonce,
      key: SecureKey.fromList(_sodium, key),
    );
    
    final combined = Uint8List.fromList([...nonce, ...encrypted]);
    return base64.encode(combined);
  }

  Future<String> decryptLocal(String cipherTextBase64) async {
    final key = await _ensureMasterKey();
    final combined = base64.decode(cipherTextBase64);
    final nonce = combined.sublist(0, _sodium.crypto.secretBox.nonceBytes);
    final cipherText = combined.sublist(_sodium.crypto.secretBox.nonceBytes);
    
    final decrypted = _sodium.crypto.secretBox.openEasy(
      cipherText: cipherText,
      nonce: nonce,
      key: SecureKey.fromList(_sodium, key),
    );
    return utf8.decode(decrypted);
  }

  // ============= E2EE MESSAGE ENCRYPTION =============
  
  Future<EncryptedMessage> encryptMessage(String plainText, String recipientPublicKeyBase64) async {
    await _ensureIdentityKeys();
    final recipientPublicKey = base64.decode(recipientPublicKeyBase64);
    final nonce = _sodium.randombytes.buf(_sodium.crypto.box.nonceBytes);
    
    final encrypted = _sodium.crypto.box.easy(
      message: utf8.encoder.convert(plainText),
      nonce: nonce,
      publicKey: recipientPublicKey,
      secretKey: _identityKeyPair!.secretKey,
    );
    
    return EncryptedMessage(
      cipherText: base64.encode(encrypted),
      nonce: base64.encode(nonce),
      senderPublicKey: base64.encode(_identityKeyPair!.publicKey),
    );
  }

  // ============= METHODS FOR SECURITY PROVIDER =============
  
  /// Decrypt a message using E2EE
  Future<String> decryptMessage(EncryptedMessage encryptedMessage) async {
    await _ensureIdentityKeys();
    
    final cipherText = base64.decode(encryptedMessage.cipherText);
    final nonce = base64.decode(encryptedMessage.nonce);
    final senderPublicKey = base64.decode(encryptedMessage.senderPublicKey);
    
    final decrypted = _sodium.crypto.box.openEasy(
      cipherText: cipherText,
      nonce: nonce,
      publicKey: senderPublicKey,
      secretKey: _identityKeyPair!.secretKey,
    );
    
    return utf8.decode(decrypted);
  }
  
  /// Generate one-time prekeys for a user (for Signal protocol)
  Future<List<Map<String, String>>> generateOneTimePreKeys(int count) async {
    await _ensureIdentityKeys();
    final List<Map<String, String>> preKeys = [];
    
    for (int i = 0; i < count; i++) {
      // Generate a keypair for each prekey
      final keyPair = _sodium.crypto.box.keypair();
      
      preKeys.add({
        'id': i.toString(),
        'publicKey': base64.encode(keyPair.publicKey),
      });
    }
    
    return preKeys;
  }
  
  /// Create a secure session with another user
  Future<void> createSession(String userId, String theirPublicKey) async {
    await _ensureIdentityKeys();
    
    debugPrint('Creating secure session with user: $userId');
    
    try {
      base64.decode(theirPublicKey);
    } catch (e) {
      throw Exception('Invalid public key format');
    }
    
    await _secureStorage.write(
      key: 'session_$userId',
      value: theirPublicKey,
    );
  }

  // ============= FILE ENCRYPTION =============

  Future<Uint8List> encryptFile(Uint8List fileBytes) async {
    final key = await _ensureMasterKey();
    final nonce = _sodium.randombytes.buf(_sodium.crypto.secretBox.nonceBytes);
    final encrypted = _sodium.crypto.secretBox.easy(
      message: fileBytes,
      nonce: nonce,
      key: SecureKey.fromList(_sodium, key),
    );
    return Uint8List.fromList([...nonce, ...encrypted]);
  }

  Future<Uint8List> decryptFile(Uint8List encryptedBytes) async {
    final key = await _ensureMasterKey();
    final nonce = encryptedBytes.sublist(0, _sodium.crypto.secretBox.nonceBytes);
    final cipherText = encryptedBytes.sublist(_sodium.crypto.secretBox.nonceBytes);
    
    return _sodium.crypto.secretBox.openEasy(
      cipherText: cipherText,
      nonce: nonce,
      key: SecureKey.fromList(_sodium, key),
    );
  }

  // ============= IDENTITY KEY MANAGEMENT =============
  
  Future<void> _ensureIdentityKeys() async {
    final pub = await _secureStorage.read(key: _identityKeyPairPublic);
    final sec = await _secureStorage.read(key: _identityKeyPairSecret);
    
    if (pub != null && sec != null) {
      _identityKeyPair = KeyPair(
        publicKey: base64.decode(pub),
        secretKey: SecureKey.fromList(_sodium, base64.decode(sec)),
      );
    } else {
      _identityKeyPair = _sodium.crypto.box.keypair();
      
      await _secureStorage.write(
        key: _identityKeyPairPublic, 
        value: base64.encode(_identityKeyPair!.publicKey)
      );
      final secretKeyBytes = _identityKeyPair!.secretKey.extractBytes();
      await _secureStorage.write(
        key: _identityKeyPairSecret, 
        value: base64.encode(secretKeyBytes)
      );
    }
  }
}

// ============= MODELS =============

class EncryptedMessage {
  final String cipherText;
  final String nonce;
  final String senderPublicKey;
  
  EncryptedMessage({
    required this.cipherText,
    required this.nonce,
    required this.senderPublicKey,
  });
}