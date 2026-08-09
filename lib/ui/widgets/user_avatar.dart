import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String? photoURL;
  final String displayName;
  final double size;

  const UserAvatar({
    Key? key,
    this.photoURL,
    required this.displayName,
    this.size = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final initials = displayName
        .split(' ')
        .map((e) => e[0].toUpperCase())
        .join()
        .substring(0, 2);

    if (photoURL != null && photoURL!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: CachedNetworkImageProvider(photoURL!),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.1),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.8),
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}