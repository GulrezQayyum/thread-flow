import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import 'service_providers.dart'; // ← IMPORT THIS (contains firestoreServiceProvider)

// Get messages for a chat
final chatMessagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
  final firestoreService = ref.watch(firestoreServiceProvider); // ← ADD THIS
  return firestoreService.watchMessages(chatId);
});

// Get messages in a specific thread
final threadMessagesProvider = StreamProvider.family<List<MessageModel>, ThreadMessageParams>((ref, params) {
  final firestoreService = ref.watch(firestoreServiceProvider); // ← ADD THIS
  return firestoreService.watchThreadMessages(params.chatId, params.threadId);
});

// Send a message
final sendMessageProvider = FutureProvider.family<MessageModel, SendMessageParams>((ref, params) async {
  final firestoreService = ref.watch(firestoreServiceProvider); // ← ADD THIS
  
  print('📤 SEND MESSAGE: ChatId: ${params.chatId}');
  print('📤 SEND MESSAGE: SenderId: ${params.senderId}');
  print('📤 SEND MESSAGE: Text: ${params.text}');
  print('📤 SEND MESSAGE: ThreadId: ${params.threadId}');
  
  try {
    final message = await firestoreService.sendMessage(
      chatId: params.chatId,
      senderId: params.senderId,
      text: params.text,
      mediaUrl: params.mediaUrl,
      threadId: params.threadId,
      isThreadStart: params.isThreadStart,
    );
    
    print('✅ MESSAGE SENT: ${message.id}');
    
    ref.invalidate(chatMessagesProvider(params.chatId));
    if (params.threadId != null) {
      ref.invalidate(threadMessagesProvider(
        ThreadMessageParams(chatId: params.chatId, threadId: params.threadId!),
      ));
    }
    
    return message;
  } catch (e) {
    print('❌ SEND MESSAGE ERROR: $e');
    throw Exception('Failed to send message: $e');
  }
});

// Generate summary for a thread
final generateThreadSummaryProvider = FutureProvider.family<String, GenerateSummaryParams>((ref, params) async {
  final groqService = ref.watch(groqServiceProvider); // ← ADD THIS
  return groqService.generateThreadSummary(params.messages);
});

// Generate title for a thread
final generateThreadTitleProvider = FutureProvider.family<String, GenerateTitleParams>((ref, params) async {
  final groqService = ref.watch(groqServiceProvider); // ← ADD THIS
  return groqService.generateThreadTitle(params.messages);
});

// Delete a message
final deleteMessageProvider = FutureProvider.family<void, DeleteMessageParams>((ref, params) async {
  final firestoreService = ref.watch(firestoreServiceProvider); // ← ADD THIS
  await firestoreService.deleteMessage(params.chatId, params.messageId);
  ref.invalidate(chatMessagesProvider(params.chatId));
});

// Search messages in a chat
final searchMessagesProvider = FutureProvider.family<List<MessageModel>, SearchParams>((ref, params) async {
  final firestoreService = ref.watch(firestoreServiceProvider); // ← ADD THIS
  return firestoreService.searchMessages(params.chatId, params.query);
});

// ==================== PARAMETER CLASSES ====================

class ThreadMessageParams {
  final String chatId;
  final String threadId;

  ThreadMessageParams({
    required this.chatId,
    required this.threadId,
  });
}

class SendMessageParams {
  final String chatId;
  final String senderId;
  final String text;
  final String? mediaUrl;
  final String? threadId;
  final bool isThreadStart;

  SendMessageParams({
    required this.chatId,
    required this.senderId,
    required this.text,
    this.mediaUrl,
    this.threadId,
    this.isThreadStart = false,
  });
}

class GenerateSummaryParams {
  final List<MessageModel> messages;
  final String? chatId;
  final String? threadId;

  GenerateSummaryParams({
    required this.messages,
    this.chatId,
    this.threadId,
  });
}

class GenerateTitleParams {
  final List<MessageModel> messages;

  GenerateTitleParams({
    required this.messages,
  });
}

class DeleteMessageParams {
  final String chatId;
  final String messageId;

  DeleteMessageParams({
    required this.chatId,
    required this.messageId,
  });
}

class SearchParams {
  final String chatId;
  final String query;

  SearchParams({
    required this.chatId,
    required this.query,
  });
}

// Toggle reaction on a message
final toggleReactionProvider = FutureProvider.family<void, ToggleReactionParams>((ref, params) async {
  final firestoreService = ref.watch(firestoreServiceProvider); // ← ADD THIS
  
  final messageDoc = await firestoreService.getChatMessage(params.chatId, params.messageId);
  if (messageDoc == null) return;
  
  final currentReactions = List<String>.from(messageDoc['reactions'] ?? []);
  final userId = params.userId;
  
  final userReactionIndex = currentReactions.indexWhere((r) => r == params.reaction);
  
  if (userReactionIndex != -1) {
    await firestoreService.removeReaction(
      chatId: params.chatId,
      messageId: params.messageId,
      reaction: params.reaction,
    );
  } else {
    await firestoreService.addReaction(
      chatId: params.chatId,
      messageId: params.messageId,
      reaction: params.reaction,
    );
  }
  
  ref.invalidate(chatMessagesProvider(params.chatId));
});

class ToggleReactionParams {
  final String chatId;
  final String messageId;
  final String userId;
  final String reaction;

  ToggleReactionParams({
    required this.chatId,
    required this.messageId,
    required this.userId,
    required this.reaction,
  });
}