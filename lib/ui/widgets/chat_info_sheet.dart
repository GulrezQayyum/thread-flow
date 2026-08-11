// lib/widgets/chat_info_sheet.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart'; // THIS IMPORT IS MISSING!
import '../../models/chat_model.dart';
import '../../providers/user_provider.dart';

class ChatInfoSheet extends ConsumerWidget { // Now works because of the import
  final ChatModel chat;

  const ChatInfoSheet({
    Key? key,
    required this.chat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) { // WidgetRef now works
    return Container(
      padding: const EdgeInsets.all(20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chat header
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: chat.photoURL != null
                    ? NetworkImage(chat.photoURL!)
                    : null,
                child: chat.photoURL == null
                    ? Text(
                        chat.name.isNotEmpty ? chat.name[0].toUpperCase() : 'C',
                        style: const TextStyle(fontSize: 24),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Created ${_formatDate(chat.createdAt)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (chat.createdBy.isNotEmpty)
                      Text(
                        'Created by: ${chat.createdBy.substring(0, 8)}...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          
          // Chat stats
          Row(
            children: [
              _buildStatItem(
                Icons.people,
                '${chat.members.length} Members',
                context,
              ),
              const SizedBox(width: 32),
              _buildStatItem(
                Icons.forum_outlined,
                '0 Threads',
                context,
              ),
            ],
          ),
          const Divider(height: 32),
          
          // Members list
          Text(
            'Members',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: chat.members.length,
              itemBuilder: (context, index) {
                final memberId = chat.members[index];
                return _buildMemberTile(context, ref, memberId);
              },
            ),
          ),
          
          if (chat.summary != null) ...[
            const Divider(height: 32),
            Text(
              'Chat Summary',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(chat.summary!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary), // Fixed: colorScheme not colors
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildMemberTile(BuildContext context, WidgetRef ref, String memberId) {
    final userAsync = ref.watch(userStreamProvider(memberId));
    
    return userAsync.when(
      data: (user) => ListTile(
        leading: CircleAvatar(
          backgroundImage: user?.photoURL != null
              ? NetworkImage(user!.photoURL!)
              : null,
          child: user?.photoURL == null && user != null
              ? Text(user.displayName[0].toUpperCase())
              : null,
        ),
        title: Text(user?.displayName ?? 'Unknown User'),
        subtitle: Text(user?.email ?? ''),
        dense: true,
        contentPadding: EdgeInsets.zero,
      ),
      loading: () => const ListTile(
        leading: CircleAvatar(child: CircularProgressIndicator()),
        title: Text('Loading...'),
        dense: true,
        contentPadding: EdgeInsets.zero,
      ),
      error: (error, stack) => ListTile(
        leading: const CircleAvatar(child: Icon(Icons.error)),
        title: Text('Error loading user'),
        dense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}