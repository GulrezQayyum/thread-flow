// lib/providers/typing_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/typing_indicator_service.dart';

// Typing indicator service provider
final typingIndicatorServiceProvider = Provider((ref) => TypingIndicatorService());

// Watch typing users in chat
final watchTypingUsersProvider = StreamProvider.family<List<String>, String>(
  (ref, chatId) {
    print('👁️ PROVIDER: Watching typing users in chat $chatId');
    final typingService = ref.watch(typingIndicatorServiceProvider);
    return typingService.watchTypingUsers(chatId);
  },
);

// Set user as typing
final setUserTypingProvider = FutureProvider.family<void, SetTypingParams>(
  (ref, params) async {
    print('⌨️ PROVIDER: Setting ${params.userName} as typing');
    final typingService = ref.watch(typingIndicatorServiceProvider);

    try {
      await typingService.setTyping(
        chatId: params.chatId,
        userId: params.userId,
        userName: params.userName,
      );
      print('✅ PROVIDER: Typing indicator set');
    } catch (e) {
      print('❌ PROVIDER TYPING SET ERROR: $e');
    }
  },
);

class SetTypingParams {
  final String chatId;
  final String userId;
  final String userName;

  SetTypingParams({
    required this.chatId,
    required this.userId,
    required this.userName,
  });
}

// Clear typing indicator
final clearUserTypingProvider = FutureProvider.family<void, ClearTypingParams>(
  (ref, params) async {
    print('⌨️ PROVIDER: Clearing typing indicator');
    final typingService = ref.watch(typingIndicatorServiceProvider);

    try {
      await typingService.clearTyping(
        chatId: params.chatId,
        userId: params.userId,
      );
      print('✅ PROVIDER: Typing indicator cleared');
    } catch (e) {
      print('❌ PROVIDER TYPING CLEAR ERROR: $e');
    }
  },
);

class ClearTypingParams {
  final String chatId;
  final String userId;

  ClearTypingParams({
    required this.chatId,
    required this.userId,
  });
}