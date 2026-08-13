// lib/widgets/user_avatar.dart
import 'dart:convert';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String? photoURL;
  final String? avatarBase64;
  final String displayName;
  final double size;

  const UserAvatar({
    Key? key,
    this.photoURL,
    this.avatarBase64,
    required this.displayName,
    this.size = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Debug: print if avatar exists
    if (avatarBase64 != null && avatarBase64!.isNotEmpty) {
      print('✅ UserAvatar has Base64 data: ${avatarBase64!.length} chars');
      try {
        final bytes = base64Decode(avatarBase64!);
        return CircleAvatar(
          radius: size / 2,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (e) {
        print('❌ Failed to decode Base64: $e');
      }
    }

    // Check if we have a URL avatar
    if (photoURL != null && photoURL!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(photoURL!),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.1),
          ),
        ),
      );
    }

    // Fallback to initials
    String initials = '?';
    if (displayName.isNotEmpty) {
      final parts = displayName.split(' ');
      if (parts.length >= 2) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        final name = displayName.trim();
        initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
      }
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.8),
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}