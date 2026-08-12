import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_model.dart';
import '../models/thread_model.dart';
import 'service_providers.dart';

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
  ref.invalidate(userChatsProvider(params.createdBy));
  return chat;
});

// Update chat
final updateChatProvider = FutureProvider.family<void, UpdateChatParams>((ref, params) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  await firestoreService.updateChatSummary(params.chatId, params.summary);
  ref.invalidate(chatProvider(params.chatId));
});

// ==================== DELETE CHAT ====================
final deleteChatProvider = FutureProvider.family<void, DeleteChatParams>((ref, params) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  
  // 1. Delete all messages in the chat
  await firestoreService.deleteAllMessages(params.chatId);
  
  // 2. Remove chat from all members' chat lists
  final chat = await firestoreService.getChat(params.chatId);
  if (chat != null) {
    for (var memberId in chat.members) {
      await firestoreService.removeChatFromUserList(
        userId: memberId,
        chatId: params.chatId,
      );
    }
  }
  
  // 3. Delete the chat document
  await firestoreService.deleteChat(params.chatId);
  
  // Invalidate to refresh
  ref.invalidate(userChatsProvider);
});

// ==================== LEAVE CHAT ====================
final leaveChatProvider = FutureProvider.family<void, LeaveChatParams>((ref, params) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  
  // 1. Remove user from chat members
  await firestoreService.removeUserFromChat(
    chatId: params.chatId,
    userId: params.userId,
  );
  
  // 2. Remove chat from user's list
  await firestoreService.removeChatFromUserList(
    userId: params.userId,
    chatId: params.chatId,
  );
  
  // If chat has no members left, delete it
  final chat = await firestoreService.getChat(params.chatId);
  if (chat != null && chat.members.isEmpty) {
    await firestoreService.deleteChat(params.chatId);
  }
  
  ref.invalidate(userChatsProvider);
});

// ==================== UPDATE CHAT NAME ====================
final updateChatNameProvider = FutureProvider.family<void, UpdateChatNameParams>((ref, params) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  await firestoreService.updateChatName(params.chatId, params.newName);
  ref.invalidate(chatProvider(params.chatId));
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

class DeleteChatParams {
  final String chatId;
  final String userId; // User who is deleting the chat

  DeleteChatParams({
    required this.chatId,
    required this.userId,
  });
}

class LeaveChatParams {
  final String chatId;
  final String userId;

  LeaveChatParams({
    required this.chatId,
    required this.userId,
  });
}

class UpdateChatNameParams {
  final String chatId;
  final String newName;

  UpdateChatNameParams({
    required this.chatId,
    required this.newName,
  });
}