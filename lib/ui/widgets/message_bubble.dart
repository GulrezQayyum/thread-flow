// lib/widgets/message_bubble.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/message_model.dart';
import '../../providers/user_provider.dart';
import 'reaction_picker.dart';

class MessageBubble extends ConsumerWidget {
  final MessageModel message;
  final bool isCurrentUser;
  final bool showSenderName;
  final bool isFirstInThread;
  final VoidCallback? onThreadTap;
  final Function(String)? onReactionTap;
  final VoidCallback? onDeleteTap;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isCurrentUser,
    this.showSenderName = false,
    this.isFirstInThread = false,
    this.onThreadTap,
    this.onReactionTap,
    this.onDeleteTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final senderAsync = ref.watch(userStreamProvider(message.senderId));
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: isCurrentUser 
            ? CrossAxisAlignment.end 
            : CrossAxisAlignment.start,
        children: [
          // Thread start indicator
          if (isFirstInThread) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: 12,
                bottom: 4,
                top: 8,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.forum_outlined,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'New Thread',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Sender name
          if (showSenderName && !isCurrentUser)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 2),
              child: senderAsync.when(
                data: (user) => Text(
                  user?.displayName ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          
          // Message bubble
          GestureDetector(
            onTap: onThreadTap,
            onLongPress: () => _showMessageOptions(context),
            child: Container(
              margin: EdgeInsets.only(
                left: isCurrentUser ? 60 : 8,
                right: isCurrentUser ? 8 : 60,
                top: 2,
                bottom: 2,
              ),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Media (image)
                  if (message.mediaUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        message.mediaUrl!,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            width: 200,
                            color: Colors.grey[300],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 150,
                            width: 200,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image, size: 50),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Text
                  if (message.text.isNotEmpty && message.text != '📷 Image')
                    Text(
                      message.text,
                      style: TextStyle(
                        color: isCurrentUser ? Colors.white : null,
                        fontSize: 15,
                      ),
                    ),
                  
                  // Timestamp and reactions
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: isCurrentUser 
                              ? Colors.white.withOpacity(0.7) 
                              : Colors.grey[600],
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all,
                          size: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ],
                      if (message.reactions.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        ...message.reactions.map((reaction) => Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: Text(
                            reaction,
                            style: const TextStyle(fontSize: 12),
                          ),
                        )),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.add_reaction),
              title: const Text('Add Reaction'),
              onTap: () {
                Navigator.pop(context);
                _showReactionPicker(context);
              },
            ),
            if (isCurrentUser) ...[
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete Message', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  onDeleteTap?.call();
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.forum_outlined),
              title: const Text('View Thread'),
              onTap: () {
                Navigator.pop(context);
                onThreadTap?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReactionPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ReactionPicker(
        onReactionSelected: (reaction) {
          Navigator.pop(context);
          onReactionTap?.call(reaction);
        },
      ),
    );
  }
}