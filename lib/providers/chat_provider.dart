// lib/providers/chat_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_model.dart';
import '../models/thread_model.dart';
import 'service_providers.dart';

// ==================== CHAT PROVIDERS ====================

// Get all chats for current user
final userChatsProvider = StreamProvider.family<List<ChatModel>, String>((ref, userId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.watchUserChats(userId);
});

// Get single chat
final chatProvider = StreamProvider.family<ChatModel?, String>((ref, chatId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.watchChat(chatId);
});

// Get all threads in a chat
final chatThreadsProvider = StreamProvider.family<List<ThreadModel>, String>((ref, chatId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.watchThreads(chatId);
});

// Create new chat
final createChatProvider = FutureProvider.family<ChatModel, CreateChatParams>((ref, params) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final chat = await firestoreService.createChat(
    name: params.name,
    members: params.members,
    createdBy: params.createdBy,
    photoURL: params.photoURL,
  );
  // Invalidate user chats to refresh
  ref.invalidate(userChatsProvider(params.createdBy));
  return chat;
});

// Update chat
final updateChatProvider = FutureProvider.family<void, UpdateChatParams>((ref, params) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  await firestoreService.updateChatSummary(params.chatId, params.summary);
  ref.invalidate(chatProvider(params.chatId));
});

// Delete chat
final deleteChatProvider = FutureProvider.family<void, String>((ref, chatId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  // Note: You'll need to implement deleteChat in firestore_service.dart
  ref.invalidate(userChatsProvider);
});

// ==================== PARAMETER CLASSES ====================

class CreateChatParams {
  final String name;
  final List<String> members;
  final String createdBy;
  final String? photoURL;

  CreateChatParams({
    required this.name,
    required this.members,
    required this.createdBy,
    this.photoURL,
  });
}

class UpdateChatParams {
  final String chatId;
  final String summary;

  UpdateChatParams({
    required this.chatId,
    required this.summary,
  });
}