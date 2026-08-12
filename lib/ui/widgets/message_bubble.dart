// lib/widgets/message_bubble.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/message_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/storage_provider.dart';
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
          InkWell(
            onTap: onThreadTap,
            onLongPress: () {
              _showMessageOptions(context);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: EdgeInsets.only(
                left: isCurrentUser ? 60 : 8,
                right: isCurrentUser ? 8 : 60,
                top: 2,
                bottom: 2,
              ),
              padding: const EdgeInsets.all(12),
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
                  // Media (image) - Simplified
                  if (message.mediaUrl != null)
                    _buildImageContent(context),
                  
                  // Text
                  if (message.text.isNotEmpty && message.text != '📷 Image')
                    Text(
                      message.text,
                      style: TextStyle(
                        color: isCurrentUser ? Colors.white : null,
                        fontSize: 15,
                      ),
                    ),
                  
                  const SizedBox(height: 4),
                  
                  // ==================== TIMESTAMP & REACTIONS ====================
                  
                  // Timestamp row with reaction button
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
                      // Reaction button (like WhatsApp)
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => _showReactionPicker(context),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.add_reaction,
                            size: 14,
                            color: isCurrentUser 
                                ? Colors.white.withOpacity(0.6) 
                                : Colors.grey[500],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // ==================== REACTIONS DISPLAY (Like WhatsApp) ====================
                  
                  if (message.reactions.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: _groupReactions(message.reactions).entries.map((entry) {
                        final emoji = entry.key;
                        final count = entry.value;
                        return InkWell(
                          onTap: () {
                            onReactionTap?.call(emoji);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrentUser 
                                  ? Colors.white.withOpacity(0.15) 
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isCurrentUser 
                                    ? Colors.white.withOpacity(0.3) 
                                    : Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                if (count > 1) ...[
                                  const SizedBox(width: 2),
                                  Text(
                                    count.toString(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isCurrentUser 
                                          ? Colors.white.withOpacity(0.8) 
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HELPER: GROUP REACTIONS ====================
  
  Map<String, int> _groupReactions(List<String> reactions) {
    final Map<String, int> grouped = {};
    for (var reaction in reactions) {
      grouped[reaction] = (grouped[reaction] ?? 0) + 1;
    }
    return grouped;
  }

  // ==================== IMAGE CONTENT (Simplified - No Firestore) ====================

  Widget _buildImageContent(BuildContext context) {
    final mediaUrl = message.mediaUrl!;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        mediaUrl,
        height: 200,
        width: 200,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 200,
            width: 200,
            color: Colors.grey[200],
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
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.broken_image,
              size: 50,
              color: Colors.grey,
            ),
          );
        },
      ),
    );
  }

  // ==================== HELPERS ====================

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

  // ==================== MESSAGE OPTIONS ====================

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            children: [
              // Reaction option
              ListTile(
                leading: const Icon(Icons.emoji_emotions, color: Colors.orange),
                title: const Text('Add Reaction'),
                onTap: () {
                  Navigator.pop(context);
                  _showReactionPicker(context);
                },
              ),
              // Thread option
              ListTile(
                leading: const Icon(Icons.forum_outlined, color: Colors.blue),
                title: const Text('View Thread'),
                onTap: () {
                  Navigator.pop(context);
                  onThreadTap?.call();
                },
              ),
              // Delete option (only for own messages)
              if (isCurrentUser) ...[
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Delete Message',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onDeleteTap?.call();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==================== REACTION PICKER ====================

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