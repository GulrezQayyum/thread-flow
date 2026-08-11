import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/thread_model.dart';
import '../../providers/chat_provider.dart';
import 'create_thread_dialog.dart';
import '../../providers/user_provider.dart';

class ThreadsSheet extends ConsumerWidget {
  final String chatId;
  final Function(String) onThreadSelected;

  const ThreadsSheet({
    Key? key,
    required this.chatId,
    required this.onThreadSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(chatThreadsProvider(chatId));

    return Container(
      padding: const EdgeInsets.all(20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Threads',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => _showCreateThreadDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('New Thread'),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: threadsAsync.when(
              data: (threads) {
                if (threads.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.forum_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No threads yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create a new thread to organize conversations',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: threads.length,
                  itemBuilder: (context, index) {
                    final thread = threads[index];
                    return _buildThreadItem(context, thread, ref);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Text('Error loading threads: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreadItem(BuildContext context, ThreadModel thread, WidgetRef ref) {
    final senderAsync = ref.watch(userStreamProvider(thread.firstSenderId));
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: senderAsync.when(
            data: (user) => Text(
              user?.displayName[0].toUpperCase() ?? '?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const Icon(Icons.person),
          ),
        ),
        title: Text(
          thread.firstMessage,
          style: const TextStyle(fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            senderAsync.when(
              data: (user) => Text(
                'by ${user?.displayName ?? 'Unknown'}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            Text(
              '${thread.messageCount} messages',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (thread.lastMessageAt != null)
              Text(
                'Last: ${_formatTime(thread.lastMessageAt!)}',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            if (thread.summary != null)
              Text(
                '📝 ${thread.summary}',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => onThreadSelected(thread.threadId),
        ),
        onTap: () => onThreadSelected(thread.threadId),
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

  void _showCreateThreadDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => CreateThreadDialog(
        chatId: chatId,
        onThreadCreated: (threadId) {
          onThreadSelected(threadId);
          Navigator.pop(context);
        },
      ),
    );
  }
}