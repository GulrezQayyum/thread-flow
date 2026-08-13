import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime? lastSeen;
  final bool emailVerified;
  final String? avatarBase64;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.createdAt,
    this.lastSeen,
    this.emailVerified = false,
    this.avatarBase64,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'photoURL': photoURL,
    'createdAt': createdAt,
    'lastSeen': lastSeen,
    'emailVerified': emailVerified,
    'avatarBase64': avatarBase64,
  };

  // Create from Firestore document
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    uid: json['uid'] ?? '',
    email: json['email'] ?? '',
    displayName: json['displayName'] ?? 'Anonymous',
    photoURL: json['photoURL'],
    createdAt: (json['createdAt'] as Timestamp).toDate(),
    lastSeen: json['lastSeen'] != null
        ? (json['lastSeen'] as Timestamp).toDate()
        : null,
    emailVerified: json['emailVerified'] ?? false,
    avatarBase64: json['avatarBase64'],
  );

  UserModel copyWith({
    String? displayName,
    String? photoURL,
    DateTime? lastSeen,
    bool? emailVerified,
    String? avatarBase64,
  }) => UserModel(
    uid: uid,
    email: email,
    displayName: displayName ?? this.displayName,
    photoURL: photoURL ?? this.photoURL,
    createdAt: createdAt,
    lastSeen: lastSeen ?? this.lastSeen,
    emailVerified: emailVerified ?? this.emailVerified,
    avatarBase64: avatarBase64 ?? this.avatarBase64,
  );
}
