import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';
import 'package:here/core/services/ai_service.dart';

part 'ai_provider.g.dart';

@riverpod
AIService aiService(Ref ref) {
  return AIService();
}