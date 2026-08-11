import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final String? mediaUrl;
  final DateTime createdAt;
  final String threadId; // Groups messages into threads
  final bool isThreadStart; // First message in thread
  final List<String> reactions; // emoji reactions
  final String? messageType;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    this.mediaUrl,
    required this.createdAt,
    required this.threadId,
    this.isThreadStart = false,
    this.reactions = const [],
    this.messageType = 'text',

  });
 
  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'text': text,
    'mediaUrl': mediaUrl,
    'createdAt': createdAt,
    'threadId': threadId,
    'isThreadStart': isThreadStart,
    'reactions': reactions,
    'messageType': messageType,

  };
 
  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
    id: json['id'] ?? '',
    senderId: json['senderId'] ?? '',
    text: json['text'] ?? '',
    mediaUrl: json['mediaUrl'],
    createdAt: (json['createdAt'] as Timestamp).toDate(),
    threadId: json['threadId'] ?? '',
    isThreadStart: json['isThreadStart'] ?? false,
    reactions: List<String>.from(json['reactions'] ?? []),
    messageType: json['messageType'] ?? 'text',
  );
 
  MessageModel copyWith({
    String? text,
    List<String>? reactions,
  }) => MessageModel(
    id: id,
    senderId: senderId,
    text: text ?? this.text,
    mediaUrl: mediaUrl,
    createdAt: createdAt,
    threadId: threadId,
    isThreadStart: isThreadStart,
    reactions: reactions ?? this.reactions,
    messageType: messageType,
  );
}