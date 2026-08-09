import 'package:riverpod/riverpod.dart';
import '../models/chat_model.dart';
import '../models/thread_model.dart';
import '../services/firestore_service.dart';

final firestoreServiceProvider = Provider((ref) => FirestoreService());

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
  return firestoreService.watchChatThreads(chatId);
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
  ref.invalidate(userChatsProvider);
  return chat;
});

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

