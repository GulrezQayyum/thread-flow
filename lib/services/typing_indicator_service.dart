// lib/services/typing_indicator_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class TypingIndicatorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int _typingTimeoutSeconds = 3;

  Future<void> setTyping({
    required String chatId,
    required String userId,
    required String userName,
  }) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('typing')
          .doc(userId)
          .set({
        'userId': userId,
        'userName': userName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ TYPING SET ERROR: $e');
    }
  }

  Future<void> clearTyping({
    required String chatId,
    required String userId,
  }) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('typing')
          .doc(userId)
          .delete();
    } catch (e) {
      print('❌ TYPING CLEAR ERROR: $e');
    }
  }

  Stream<List<String>> watchTypingUsers(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('typing')
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      final typingUsers = <String>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

        if (timestamp != null &&
            now.difference(timestamp).inSeconds < _typingTimeoutSeconds) {
          typingUsers.add(data['userName'] ?? 'Someone');
        } else {
          // Cleanup old entries
          doc.reference.delete();
        }
      }

      return typingUsers;
    });
  }
}