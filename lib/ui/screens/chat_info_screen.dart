// lib/ui/screens/chat_info_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/chat_model.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';

class ChatInfoScreen extends ConsumerWidget {
  final ChatModel chat;

  const ChatInfoScreen({
    Key? key,
    required this.chat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.read(currentUserStreamProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Info'),
        elevation: 1,
      ),
      body: ListView(
        children: [
          _buildChatHeader(context),
          _buildChatDetails(context, ref),
          _buildMembersSection(context, ref),
          _buildDangerZone(context, ref),
        ],
      ),
    );
  }

  Widget _buildChatHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Icon(Icons.group, color: Colors.white, size: 50),
          ),
          const SizedBox(height: 16),
          Text(
            chat.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${chat.members.length} members',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatDetails(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chat Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailCard(
            context,
            icon: Icons.calendar_today,
            label: 'Created',
            value: _formatDate(chat.createdAt),
          ),
          const SizedBox(height: 12),
          _buildDetailCard(
            context,
            icon: Icons.message,
            label: 'Messages',
            value: '0',
          ),
          const SizedBox(height: 12),
          _buildDetailCard(
            context,
            icon: Icons.schedule,
            label: 'Last Message',
            value: chat.lastMessageAt != null 
                ? _formatDate(chat.lastMessageAt!)
                : 'No messages',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersSection(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Members (${chat.members.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showAddMemberDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: chat.members.length,
            itemBuilder: (context, index) {
              final memberId = chat.members[index];
              final isOwner = memberId == chat.createdBy;
              return _buildMemberTile(context, ref, memberId, isOwner);
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMemberTile(BuildContext context, WidgetRef ref, String memberId, bool isOwner) {
    final userAsync = ref.watch(userStreamProvider(memberId));
    
    return userAsync.when(
      data: (user) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              user?.displayName[0].toUpperCase() ?? '?',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(user?.displayName ?? 'Unknown'),
          subtitle: Text(user?.email ?? ''),
          trailing: isOwner
              ? Chip(
                  label: const Text('Owner'),
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                )
              : PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(child: Text('Remove')),
                  ],
                  onSelected: (_) => _showRemoveMemberDialog(context, memberId),
                ),
        ),
      ),
      loading: () => const Card(
        child: ListTile(
          leading: CircleAvatar(child: CircularProgressIndicator()),
          title: Text('Loading...'),
        ),
      ),
      error: (_, __) => const Card(
        child: ListTile(
          leading: CircleAvatar(child: Icon(Icons.error)),
          title: Text('Error loading user'),
        ),
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context, WidgetRef ref) {
    final currentUser = ref.read(currentUserStreamProvider).value;
    final isOwner = currentUser?.uid == chat.createdBy;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Danger Zone',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 12),
          if (isOwner)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showDeleteChatDialog(context, ref),
                icon: const Icon(Icons.delete),
                label: const Text('Delete Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showLeaveChatDialog(context, ref),
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Leave Chat'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} minutes ago';
    if (diff.inDays < 1) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddMemberDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Member'),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Enter email or username',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Member added')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showRemoveMemberDialog(BuildContext context, String memberId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: const Text('Are you sure you want to remove this member?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Member removed')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showLeaveChatDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Chat'),
        content: const Text('Are you sure you want to leave this chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final currentUser = ref.read(currentUserStreamProvider).value;
              if (currentUser != null) {
                await ref.read(
                  leaveChatProvider(
                    LeaveChatParams(
                      chatId: chat.id,
                      userId: currentUser.uid,
                    ),
                  ).future,
                );
              }
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('You left the chat')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _showDeleteChatDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Are you sure? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final currentUser = ref.read(currentUserStreamProvider).value;
              if (currentUser != null) {
                await ref.read(
                  deleteChatProvider(
                    DeleteChatParams(
                      chatId: chat.id,
                      userId: currentUser.uid,
                    ),
                  ).future,
                );
              }
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}