import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../security/encryption_service.dart';

part 'security_provider.g.dart';

// Singleton encryption service
@Riverpod(keepAlive: true)
EncryptionService encryptionService(EncryptionServiceRef ref) {
  return EncryptionService();
}

// Provider for encrypted message handling
@riverpod
MessageEncryption messageEncryption(MessageEncryptionRef ref) {
  return MessageEncryption(ref.watch(encryptionServiceProvider));
}

class MessageEncryption {
  final EncryptionService _encryptionService;
  
  MessageEncryption(this._encryptionService);
  
  // Encrypt message for chat
  Future<Map<String, dynamic>> encryptChatMessage(
    String plainText,
    String recipientPublicKey,
  ) async {
    // We now use the actual EncryptedMessage model from the service
    final encrypted = await _encryptionService.encryptMessage(
      plainText, 
      recipientPublicKey,
    );
    
    return {
      'cipherText': encrypted.cipherText,
      'nonce': encrypted.nonce,
      'senderPublicKey': encrypted.senderPublicKey,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  // Decrypt chat message - FIXED: Now using decryptMessage
  Future<String> decryptChatMessage(
    String cipherText,
    String nonce,
    String senderPublicKey,
  ) async {
    // Reconstruct the model to send to the service
    final message = EncryptedMessage(
      cipherText: cipherText,
      nonce: nonce,
      senderPublicKey: senderPublicKey,
    );
    
    return _encryptionService.decryptMessage(message);
  }
  
  // Generate one-time prekeys for a user
  Future<List<Map<String, String>>> generatePreKeys(int count) async {
    return _encryptionService.generateOneTimePreKeys(count);
  }
  
  // Create secure session
  Future<void> createSecureSession(
    String userId,
    String theirPublicKey,
  ) async {
    return _encryptionService.createSession(
      userId,
      theirPublicKey,
    );
  }
}

// Provider for local data encryption
@riverpod
LocalDataEncryption localDataEncryption(LocalDataEncryptionRef ref) {
  return LocalDataEncryption(ref.watch(encryptionServiceProvider));
}

class LocalDataEncryption {
  final EncryptionService _encryptionService;
  
  LocalDataEncryption(this._encryptionService);
  
  Future<String> encryptSensitiveData(String data) async {
    return _encryptionService.encryptLocal(data);
  }
  
  Future<String> decryptSensitiveData(String encryptedData) async {
    return _encryptionService.decryptLocal(encryptedData);
  }
  
  Future<Uint8List> encryptFile(Uint8List fileBytes) async {
    return _encryptionService.encryptFile(fileBytes);
  }
  
  Future<Uint8List> decryptFile(Uint8List encryptedBytes) async {
    return _encryptionService.decryptFile(encryptedBytes);
  }
}