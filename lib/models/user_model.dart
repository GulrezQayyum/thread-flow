import 'package:cloud_firestore/cloud_firestore.dart';
 
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime? lastSeen;
 
  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.createdAt,
    this.lastSeen,
  });
 
  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'photoURL': photoURL,
    'createdAt': createdAt,
    'lastSeen': lastSeen,
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
  );
 
  UserModel copyWith({
    String? displayName,
    String? photoURL,
    DateTime? lastSeen,
  }) => UserModel(
    uid: uid,
    email: email,
    displayName: displayName ?? this.displayName,
    photoURL: photoURL ?? this.photoURL,
    createdAt: createdAt,
    lastSeen: lastSeen ?? this.lastSeen,
  );
}