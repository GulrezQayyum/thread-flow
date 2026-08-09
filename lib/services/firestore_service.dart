// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/thread_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirestoreService();

  // ==================== CHAT OPERATIONS ====================

  // Create a new chat
  Future<ChatModel> createChat({
    required String name,
    required List<String> members,
    required String createdBy,
    String? photoURL,
  }) async {
    try {
      final chatId = const Uuid().v4();
      final now = DateTime.now();

      final chatModel = ChatModel(
        id: chatId,
        name: name,
        members: members,
        createdAt: now,
        createdBy: createdBy,
        photoURL: photoURL,
      );

      await _firestore.collection('chats').doc(chatId).set(
        chatModel.toJson(),
      );

      return chatModel;
    } catch (e) {
      throw Exception('Failed to create chat: $e');
    }
  }

  // Get chat by ID
  Future<ChatModel?> getChatById(String chatId) async {
    try {
      final doc = await _firestore.collection('chats').doc(chatId).get();
      if (!doc.exists) return null;
      return ChatModel.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to fetch chat: $e');
    }
  }

  // Watch chat in real-time
  Stream<ChatModel?> watchChat(String chatId) {
    return _firestore.collection('chats').doc(chatId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ChatModel.fromJson(doc.data()!);
    });
  }

  // Get all chats for a user
  Future<List<ChatModel>> getUserChats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .where('members', arrayContains: userId)
          .orderBy('lastMessageAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ChatModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user chats: $e');
    }
  }

  // Watch all chats for a user (real-time)
  Stream<List<ChatModel>> watchUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('members', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatModel.fromJson(doc.data()))
          .toList();
    });
  }

  // Update chat summary
  Future<void> updateChatSummary(String chatId, String summary) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'summary': summary,
      });
    } catch (e) {
      throw Exception('Failed to update chat summary: $e');
    }
  }

  // ==================== MESSAGE OPERATIONS ====================

  // Send a message
  Future<MessageModel> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    String? mediaUrl,
    String? threadId,
    bool isThreadStart = false,
  }) async {
    try {
      final messageId = const Uuid().v4();
      final now = DateTime.now();
      final thread = threadId ?? messageId; // If no thread, this message starts one

      final messageModel = MessageModel(
        id: messageId,
        senderId: senderId,
        text: text,
        mediaUrl: mediaUrl,
        createdAt: now,
        threadId: thread,
        isThreadStart: isThreadStart || threadId == null,
      );

      // Add message to Firestore
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(messageModel.toJson());

      // Update chat's last message
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessageAt': now,
        'lastMessage': text.length > 50 ? '${text.substring(0, 50)}...' : text,
      });

      return messageModel;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get messages for a chat
  Future<List<MessageModel>> getChatMessages(
    String chatId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => MessageModel.fromJson(doc.data()))
          .toList()
          .reversed
          .toList(); // Reverse to get chronological order
    } catch (e) {
      throw Exception('Failed to fetch messages: $e');
    }
  }

  // Watch messages for a chat (real-time)
  Stream<List<MessageModel>> watchChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromJson(doc.data()))
          .toList();
    });
  }

  // Get messages in a thread
  Future<List<MessageModel>> getThreadMessages(
    String chatId,
    String threadId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('threadId', isEqualTo: threadId)
          .orderBy('createdAt')
          .get();

      return snapshot.docs
          .map((doc) => MessageModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch thread messages: $e');
    }
  }

  // Watch thread messages (real-time)
  Stream<List<MessageModel>> watchThreadMessages(
    String chatId,
    String threadId,
  ) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('threadId', isEqualTo: threadId)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromJson(doc.data()))
          .toList();
    });
  }

  // Delete a message
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  // ==================== THREAD OPERATIONS ====================

  // Get thread summary (first message + metadata)
  Future<ThreadModel?> getThreadSummary(
    String chatId,
    String threadId,
  ) async {
    try {
      final messages = await getThreadMessages(chatId, threadId);
      if (messages.isEmpty) return null;

      final firstMessage = messages.first;
      final lastMessage = messages.last;

      return ThreadModel(
        threadId: threadId,
        firstMessage: firstMessage.text,
        firstSenderId: firstMessage.senderId,
        startedAt: firstMessage.createdAt,
        messageCount: messages.length,
        lastMessageAt: lastMessage.createdAt,
      );
    } catch (e) {
      throw Exception('Failed to get thread summary: $e');
    }
  }

  // Get all unique threads in a chat
  Future<List<String>> getChatThreads(String chatId) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      final threadIds = <String>{};
      for (var doc in snapshot.docs) {
        threadIds.add(doc['threadId'] as String);
      }

      return threadIds.toList();
    } catch (e) {
      throw Exception('Failed to fetch threads: $e');
    }
  }

  // Watch threads in a chat (real-time)
  Stream<List<ThreadModel>> watchChatThreads(String chatId) async* {
    try {
      await for (var snapshot in _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .snapshots()) {
        final threadMap = <String, ThreadModel>{};

        for (var doc in snapshot.docs) {
          final message = MessageModel.fromJson(doc.data());
          final threadId = message.threadId;

          if (!threadMap.containsKey(threadId)) {
            // Get or create thread summary
            final thread = await getThreadSummary(chatId, threadId);
            if (thread != null) {
              threadMap[threadId] = thread;
            }
          }
        }

        yield threadMap.values.toList();
      }
    } catch (e) {
      throw Exception('Failed to watch threads: $e');
    }
  }

  // ==================== SEARCH OPERATIONS ====================

  // Search messages in a chat
  Future<List<MessageModel>> searchChatMessages(
    String chatId,
    String query,
  ) async {
    try {
      final allMessages = await getChatMessages(chatId, limit: 1000);
      return allMessages
          .where((msg) =>
          msg.text.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      throw Exception('Failed to search messages: $e');
    }
  }
}