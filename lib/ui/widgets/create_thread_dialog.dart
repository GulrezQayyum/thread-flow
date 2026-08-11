// lib/widgets/create_thread_dialog.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';

class CreateThreadDialog extends ConsumerStatefulWidget {
  final String chatId;
  final Function(String) onThreadCreated;

  const CreateThreadDialog({
    Key? key,
    required this.chatId,
    required this.onThreadCreated,
  }) : super(key: key);

  @override
  ConsumerState<CreateThreadDialog> createState() => _CreateThreadDialogState();
}

class _CreateThreadDialogState extends ConsumerState<CreateThreadDialog> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Thread'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Start a new conversation thread in this chat',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              hintText: 'Type your first message...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.message_outlined),
            ),
            maxLines: 3,
            enabled: !_isLoading,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createThread,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  void _createThread() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final threadId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Send the first message using your existing provider
      await ref.read(
        sendMessageProvider(
          SendMessageParams(
            chatId: widget.chatId,
            senderId: currentUser.uid, // Make sure this is 'uid' not 'id'
            text: text,
            mediaUrl: null,
            threadId: threadId,
            isThreadStart: true, // Now this parameter exists!
          ),
        ).future,
      );

      widget.onThreadCreated(threadId);
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thread created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating thread: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}