import '../models/message_model.dart';
import '../services/groq_service.dart';
import '../services/firestore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


final groqServiceProvider = Provider((ref) => GroqService());
final firestoreServiceProvider = Provider((ref) => FirestoreService());

// Get messages for a chat
final chatMessagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.watchChatMessages(chatId);
});

// Get messages in a specific thread
final threadMessagesProvider = StreamProvider.family<List<MessageModel>, ThreadMessageParams>((ref, params) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.watchThreadMessages(params.chatId, params.threadId);
});

// Send a message
final sendMessageProvider = FutureProvider.family<MessageModel, SendMessageParams>((ref, params) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final message = await firestoreService.sendMessage(
    chatId: params.chatId,
    senderId: params.senderId,
    text: params.text,
    mediaUrl: params.mediaUrl,
    threadId: params.threadId,
  );
  // Invalidate messages to refresh
  ref.invalidate(chatMessagesProvider(params.chatId));
  if (params.threadId != null) {
    ref.invalidate(threadMessagesProvider(
      ThreadMessageParams(chatId: params.chatId, threadId: params.threadId!),
    ));
  }
  return message;
});

// Generate summary for a thread
final generateThreadSummaryProvider = FutureProvider.family<String, GenerateSummaryParams>((ref, params) async {
  final groqService = ref.watch(groqServiceProvider);
  return groqService.generateThreadSummary(params.messages);
});

// Generate title for a thread
final generateThreadTitleProvider = FutureProvider.family<String, String>((ref, firstMessage) async {
  final groqService = ref.watch(groqServiceProvider);
  return groqService.generateThreadTitle(firstMessage);
});

// Delete a message
final deleteMessageProvider = FutureProvider.family<void, DeleteMessageParams>((ref, params) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  await firestoreService.deleteMessage(params.chatId, params.messageId);
  // Refresh messages
  ref.invalidate(chatMessagesProvider(params.chatId));
});

// Search messages in a chat
final searchMessagesProvider = FutureProvider.family<List<MessageModel>, SearchParams>((ref, params) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.searchChatMessages(params.chatId, params.query);
});

// Parameter classes
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

  SendMessageParams({
    required this.chatId,
    required this.senderId,
    required this.text,
    this.mediaUrl,
    this.threadId,
  });
}

class GenerateSummaryParams {
  final List<MessageModel> messages;

  GenerateSummaryParams({required this.messages});
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