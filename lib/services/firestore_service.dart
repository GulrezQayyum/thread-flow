import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../models/thread_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // ==================== CHAT OPERATIONS ====================

  Future<ChatModel> createChat({
    required String name,
    required List<String> members,
    required String createdBy,
    String? photoURL,
  }) async {
    try {
      final chatId = _uuid.v4();
      final now = DateTime.now();

      final chat = ChatModel(
        id: chatId,
        name: name,
        members: members,
        createdAt: now,
        createdBy: createdBy,
        photoURL: photoURL,
      );

      await _firestore.collection('chats').doc(chatId).set(chat.toJson());

      return chat;
    } catch (e) {
      throw Exception('Failed to create chat: $e');
    }
  }

  Future<ChatModel?> getChat(String chatId) async {
    try {
      final doc = await _firestore.collection('chats').doc(chatId).get();
      if (!doc.exists) return null;
      return ChatModel.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get chat: $e');
    }
  }

  Stream<ChatModel?> watchChat(String chatId) {
    return _firestore.collection('chats').doc(chatId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ChatModel.fromJson(doc.data()!);
    });
  }

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
      throw Exception('Failed to get user chats: $e');
    }
  }

  Stream<List<ChatModel>> watchUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatModel.fromJson(doc.data()))
              .toList();
        });
  }

  Future<void> updateChatLastMessage({
    required String chatId,
    required String message,
  }) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessage': message.length > 50
            ? '${message.substring(0, 50)}...'
            : message,
      });
    } catch (e) {
      throw Exception('Failed to update chat last message: $e');
    }
  }

  Future<void> updateChatSummary(String chatId, String summary) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'summary': summary,
      });
    } catch (e) {
      throw Exception('Failed to update chat summary: $e');
    }
  }

  Future<void> updateChatPhoto(String chatId, String photoURL) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'photoURL': photoURL,
      });
    } catch (e) {
      throw Exception('Failed to update chat photo: $e');
    }
  }

  // ==================== THREAD OPERATIONS ====================

  /// Get thread summary
  Future<ThreadModel?> getThreadSummary(String chatId, String threadId) async {
    try {
      final doc = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('threads')
          .doc(threadId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return ThreadModel(
        threadId: data['threadId'] ?? threadId,
        firstMessage: data['firstMessage'] ?? '',
        firstSenderId: data['firstSenderId'] ?? '',
        startedAt: (data['startedAt'] as Timestamp).toDate(),
        messageCount: data['messageCount'] ?? 0,
        lastMessageAt: data['lastMessageAt'] != null
            ? (data['lastMessageAt'] as Timestamp).toDate()
            : null,
        summary: data['summary'],
      );
    } catch (e) {
      throw Exception('Failed to get thread summary: $e');
    }
  }

  /// Get all threads in a chat
  Future<List<ThreadModel>> getThreads(String chatId) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('threads')
          .orderBy('lastMessageAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ThreadModel(
          threadId: data['threadId'] ?? doc.id,
          firstMessage: data['firstMessage'] ?? '',
          firstSenderId: data['firstSenderId'] ?? '',
          startedAt: (data['startedAt'] as Timestamp).toDate(),
          messageCount: data['messageCount'] ?? 0,
          lastMessageAt: data['lastMessageAt'] != null
              ? (data['lastMessageAt'] as Timestamp).toDate()
              : null,
          summary: data['summary'],
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get threads: $e');
    }
  }

  /// Watch threads in a chat (real-time) - ADD THIS METHOD
  Stream<List<ThreadModel>> watchThreads(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('threads')
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return ThreadModel(
              threadId: data['threadId'] ?? doc.id,
              firstMessage: data['firstMessage'] ?? '',
              firstSenderId: data['firstSenderId'] ?? '',
              startedAt: (data['startedAt'] as Timestamp).toDate(),
              messageCount: data['messageCount'] ?? 0,
              lastMessageAt: data['lastMessageAt'] != null
                  ? (data['lastMessageAt'] as Timestamp).toDate()
                  : null,
              summary: data['summary'],
            );
          }).toList();
        });
  }

  /// Update thread summary (AI-generated)
  Future<void> updateThreadSummary({
    required String chatId,
    required String threadId,
    required String summary,
  }) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('threads')
          .doc(threadId)
          .update({'summary': summary});
    } catch (e) {
      throw Exception('Failed to update thread summary: $e');
    }
  }

  // ==================== ADD USER TO CHAT ====================

  Future<void> addUserToChat({
    required String chatId,
    required String userId,
  }) async {
    try {
      print('📤 Adding user $userId to chat $chatId');

      // Check if chat exists
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) {
        print('❌ Chat does not exist');
        return;
      }

      final chatData = chatDoc.data();
      if (chatData == null) {
        print('❌ Chat data is null');
        return;
      }

      final currentMembers = List<String>.from(chatData['members'] ?? []);

      if (currentMembers.contains(userId)) {
        print('⚠️ User is already a member');
        return;
      }

      // Add user to chat members
      await _firestore.collection('chats').doc(chatId).update({
        'members': FieldValue.arrayUnion([userId]),
      });
      print('✅ User added to chat members');

      // Try to add chat to user's list (optional)
      try {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('chats')
            .doc(chatId)
            .set({'chatId': chatId, 'addedAt': FieldValue.serverTimestamp()});
        print('✅ Chat added to user\'s list');
      } catch (e) {
        // This is optional - user is already added to chat
        print('ℹ️ User list update skipped (optional): $e');
      }

      print('✅ User $userId added successfully!');
    } catch (e) {
      // Log but don't throw - the operation likely succeeded
      print('⚠️ Add user completed with warning: $e');
    }
  }

  // ==================== MESSAGE OPERATIONS ====================

  Future<MessageModel> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    String? mediaUrl,
    String? threadId,
    bool isThreadStart = false,
  }) async {
    try {
      final messageId = _uuid.v4();
      final now = DateTime.now();
      final thread = threadId ?? messageId;

      final message = MessageModel(
        id: messageId,
        senderId: senderId,
        text: text,
        mediaUrl: mediaUrl,
        createdAt: now,
        threadId: thread,
        isThreadStart: isThreadStart || threadId == null,
      );

      print('📝 SAVING MESSAGE: ${message.toJson()}');

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(message.toJson());

      print('✅ MESSAGE SAVED TO FIRESTORE');

      await _firestore.collection('chats').doc(chatId).update({
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessage': text.length > 50 ? '${text.substring(0, 50)}...' : text,
      });

      print('✅ CHAT UPDATED');

      return message;
    } catch (e) {
      print('❌ SEND MESSAGE ERROR: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  Future<List<MessageModel>> getMessages(
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
          .toList();
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  Stream<List<MessageModel>> watchMessages(String chatId) {
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
      throw Exception('Failed to get thread messages: $e');
    }
  }

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

  Future<Map<String, dynamic>?> getChatMessage(
    String chatId,
    String messageId,
  ) async {
    try {
      final doc = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .get();

      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      print('❌ Failed to get message: $e');
      return null;
    }
  }

  Future<void> addReaction({
    required String chatId,
    required String messageId,
    required String reaction,
  }) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
            'reactions': FieldValue.arrayUnion([reaction]),
          });
    } catch (e) {
      throw Exception('Failed to add reaction: $e');
    }
  }

  Future<void> removeReaction({
    required String chatId,
    required String messageId,
    required String reaction,
  }) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
            'reactions': FieldValue.arrayRemove([reaction]),
          });
    } catch (e) {
      throw Exception('Failed to remove reaction: $e');
    }
  }

  // ==================== USER OPERATIONS ====================

  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return UserModel.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  Stream<UserModel?> watchUser(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromJson(doc.data()!);
    });
  }

  Future<List<UserModel>> getUsers(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];

      final snapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: userIds)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }

  Future<List<UserModel>> searchUsersByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  Future<List<UserModel>> searchUsersByName(String name) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: name)
          .where('displayName', isLessThan: '${name}z')
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to search users by name: $e');
    }
  }

  Future<void> setUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toJson());
    } catch (e) {
      throw Exception('Failed to set user: $e');
    }
  }

  Future<void> updateUserLastSeen(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update last seen: $e');
    }
  }

  // ==================== REMOVE USER FROM CHAT ====================

  Future<void> removeUserFromChat({
    required String chatId,
    required String userId,
  }) async {
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);

      await chatRef.update({
        'members': FieldValue.arrayRemove([userId]),
      });

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('chats')
          .doc(chatId)
          .delete();
    } catch (e) {
      throw Exception('Failed to remove user from chat: $e');
    }
  }

  // ==================== IMAGE OPERATIONS ====================

  Future<String> uploadChatImage({
    required String chatId,
    required String messageId,
    required File imageFile,
  }) async {
    try {
      final fileSize = await imageFile.length();
      final sizeInMB = fileSize / (1024 * 1024);

      if (sizeInMB > 0.9) {
        throw Exception(
          'Image too large: ${sizeInMB.toStringAsFixed(2)}MB. '
          'Please use a smaller image (max 1MB)',
        );
      }

      print('📤 Storing image: ${sizeInMB.toStringAsFixed(2)}MB');

      List<int> bytes;
      try {
        bytes = await imageFile.readAsBytes();
      } catch (e) {
        throw Exception('Failed to read image file: $e');
      }

      String base64String;
      try {
        final chunks = <String>[];
        const chunkSize = 8192;

        for (var i = 0; i < bytes.length; i += chunkSize) {
          final end = (i + chunkSize < bytes.length)
              ? i + chunkSize
              : bytes.length;
          final chunk = bytes.sublist(i, end);
          chunks.add(base64Encode(chunk));
        }

        base64String = chunks.join();
        print('📤 Base64 encoding complete: ${base64String.length} characters');
      } catch (e) {
        throw Exception('Failed to encode image: $e');
      }

      try {
        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('images')
            .doc(messageId)
            .set({
              'data': base64String,
              'mimeType': 'image/jpeg',
              'size': bytes.length,
              'createdAt': FieldValue.serverTimestamp(),
              'chatId': chatId,
            });
      } catch (e) {
        throw Exception('Failed to save to Firestore: $e');
      }

      final imageRef = 'firestore://$chatId/images/$messageId';
      print('✅ Image stored in Firestore: $imageRef');

      return imageRef;
    } catch (e) {
      print('❌ Failed to store image: $e');
      throw Exception('Failed to store image: $e');
    }
  }

  Future<String?> getImageData(String chatId, String messageId) async {
    try {
      final doc = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('images')
          .doc(messageId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return data['data'] as String?;
    } catch (e) {
      print('❌ Failed to get image: $e');
      return null;
    }
  }

  Future<void> deleteImage(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('images')
          .doc(messageId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  // ==================== SEARCH OPERATIONS ====================

  Future<List<MessageModel>> searchMessages(String chatId, String query) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(1000)
          .get();

      return snapshot.docs
          .map((doc) => MessageModel.fromJson(doc.data()))
          .where((msg) => msg.text.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      throw Exception('Failed to search messages: $e');
    }
  }

  Future<List<MessageModel>> getRecentMessages(
    String chatId, {
    int limit = 20,
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
          .toList();
    } catch (e) {
      throw Exception('Failed to get recent messages: $e');
    }
  }

  // ==================== BATCH OPERATIONS ====================

  Future<void> deleteAllMessages(String chatId) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      await _firestore.collection('chats').doc(chatId).update({
        'lastMessageAt': null,
        'lastMessage': null,
      });
    } catch (e) {
      throw Exception('Failed to delete all messages: $e');
    }
  }
}
