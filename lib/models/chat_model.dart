import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final String name;
  final List<String> members; // UIDs of members
  final DateTime createdAt;
  final String createdBy; // UID of creator
  final DateTime? lastMessageAt;
  final String? lastMessage;
  final String? summary; // AI-generated summary
  final String? photoURL;
 
  ChatModel({
    required this.id,
    required this.name,
    required this.members,
    required this.createdAt,
    required this.createdBy,
    this.lastMessageAt,
    this.lastMessage,
    this.summary,
    this.photoURL,
  });
 
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'members': members,
    'createdAt': createdAt,
    'createdBy': createdBy,
    'lastMessageAt': lastMessageAt,
    'lastMessage': lastMessage,
    'summary': summary,
    'photoURL': photoURL,
  };
 
  factory ChatModel.fromJson(Map<String, dynamic> json) => ChatModel(
    id: json['id'] ?? '',
    name: json['name'] ?? 'Untitled Chat',
    members: List<String>.from(json['members'] ?? []),
    createdAt: (json['createdAt'] as Timestamp).toDate(),
    createdBy: json['createdBy'] ?? '',
    lastMessageAt: json['lastMessageAt'] != null
      ? (json['lastMessageAt'] as Timestamp).toDate()
      : null,
    lastMessage: json['lastMessage'],
    summary: json['summary'],
    photoURL: json['photoURL'],
  );
 
  ChatModel copyWith({
    String? name,
    List<String>? members,
    DateTime? lastMessageAt,
    String? onFocusChange,
    String? lastMessage,
    String? summary,
    String? photoURL,
  }) => ChatModel(
    id: id,
    name: name ?? this.name,
    members: members ?? this.members,
    createdAt: createdAt,
    createdBy: createdBy,
    lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    lastMessage: lastMessage ?? this.lastMessage,
    summary: summary ?? this.summary,
    photoURL: photoURL ?? this.photoURL,
  );
}