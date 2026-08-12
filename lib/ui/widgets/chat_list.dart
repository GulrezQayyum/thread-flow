// lib/ui/widgets/chat_list.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/chat_model.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../screens/chat_screen.dart';
import 'user_avatar.dart';

class ChatList extends ConsumerWidget {
  final String userId;

  const ChatList({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(userChatsProvider(userId));

    return chatsAsync.when(
      data: (chats) {
        if (chats.isEmpty) {
          return _buildEmptyState(context);
        }
        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            return _buildChatTile(context, ref, chat);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => _buildErrorState(context, error, ref),
    );
  }

  // ==================== EMPTY STATE ====================

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No chats yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new chat to get started!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ERROR STATE ====================

  Widget _buildErrorState(BuildContext context, dynamic error, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error loading chats',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(userChatsProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ==================== CHAT TILE ====================

  Widget _buildChatTile(BuildContext context, WidgetRef ref, ChatModel chat) {
    final isCreator = chat.createdBy == userId;

    return Dismissible(
      key: Key(chat.id),
      direction: DismissDirection.endToStart,
      background: _buildDismissBackground(),
      confirmDismiss: (direction) => _showConfirmDialog(context, chat, isCreator),
      onDismissed: (direction) => _onChatDismissed(context, ref, chat, isCreator),
      child: Card(
        margin: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        child: ListTile(
          leading: UserAvatar(
            photoURL: chat.photoURL,
            displayName: chat.name, // ← FIXED: Use displayName instead of name
            size: 40,
          ),
          title: Text(
            chat.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            chat.lastMessage ?? 'No messages yet',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: chat.lastMessageAt != null
              ? Text(
                  _formatTime(chat.lastMessageAt!),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                )
              : null,
          onTap: () => _openChat(context, chat),
        ),
      ),
    );
  }

  // ==================== DISMISSIBLE BACKGROUND ====================

  Widget _buildDismissBackground() {
    return Container(
      color: Colors.red,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(
        Icons.delete,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  // ==================== CONFIRM DIALOG ====================

  Future<bool?> _showConfirmDialog(
    BuildContext context,
    ChatModel chat,
    bool isCreator,
  ) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isCreator ? 'Delete Chat' : 'Leave Chat'),
        content: Text(
          isCreator 
              ? 'Are you sure you want to permanently delete "${chat.name}"? This will delete all messages and cannot be undone.'
              : 'Are you sure you want to leave "${chat.name}"? You can be added back later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              isCreator ? 'Delete' : 'Leave',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ON DISMISSED ====================

  Future<void> _onChatDismissed(
    BuildContext context,
    WidgetRef ref,
    ChatModel chat,
    bool isCreator,
  ) async {
    try {
      if (isCreator) {
        await _deleteChat(context, ref, chat);
      } else {
        await _leaveChat(context, ref, chat);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==================== DELETE CHAT ====================

  Future<void> _deleteChat(
    BuildContext context,
    WidgetRef ref,
    ChatModel chat,
  ) async {
    await ref.read(
      deleteChatProvider(
        DeleteChatParams(
          chatId: chat.id,
          userId: userId,
        ),
      ).future,
    );
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chat "${chat.name}" deleted'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ==================== LEAVE CHAT ====================

  Future<void> _leaveChat(
    BuildContext context,
    WidgetRef ref,
    ChatModel chat,
  ) async {
    await ref.read(
      leaveChatProvider(
        LeaveChatParams(
          chatId: chat.id,
          userId: userId,
        ),
      ).future,
    );
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Left "${chat.name}"'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // ==================== OPEN CHAT ====================

  void _openChat(BuildContext context, ChatModel chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: chat.id,
          chat: chat,
        ),
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
}