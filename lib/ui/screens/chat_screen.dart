import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/message_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';

class ChatScreen extends HookConsumerWidget {
  final String chatId;
  final String chatName;

  const ChatScreen({Key? key, required this.chatId, required this.chatName})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserStreamProvider);
    final chatAsync = ref.watch(chatProvider(chatId));
    final messagesAsync = ref.watch(chatMessagesProvider(chatId));
    final messageInputController = useTextEditingController();
    final isSending = useState(false);

    return Scaffold(
      appBar: AppBar(
        title: Text(chatName),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('View Members'),
                onTap: () {
                  // TODO: Show members
                },
              ),
              PopupMenuItem(
                child: const Text('Mute'),
                onTap: () {
                  // TODO: Mute chat
                },
              ),
            ],
          ),
        ],
      ),
      body: messagesAsync.when(
        data: (messages) {
          return Column(
            children: [
              // Chat summary (if available)
              // Chat summary (if available)
              chatAsync.when(
                data: (chat) {
                  if (chat?.summary != null) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              chat!.summary!,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_outlined,
                              size: 64,
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start a conversation',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return _MessageItem(
                            message: message,
                            chatId: chatId,
                            currentUserAsync: currentUserAsync,
                            ref: ref,
                          );
                        },
                      ),
              ),
              // Message input
              MessageInput(
                controller: messageInputController,
                isLoading: isSending.value,
                onSend: (text) async {
                  isSending.value = true;
                  try {
                    final currentUser = currentUserAsync.value;
                    if (currentUser != null) {
                      await ref.read(
                        sendMessageProvider(
                          SendMessageParams(
                            chatId: chatId,
                            senderId: currentUser.uid,
                            text: text,
                          ),
                        ).future,
                      );
                      messageInputController.clear();
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error sending message: $e')),
                    );
                  } finally {
                    isSending.value = false;
                  }
                },
                onAttachMedia: () {
                  // TODO: Implement media attachment
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Media attachment coming soon'),
                    ),
                  );
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error loading messages: $err')),
      ),
    );
  }
}

class _MessageItem extends ConsumerWidget {
  final MessageModel message;
  final String chatId;
  final AsyncValue<UserModel?> currentUserAsync;
  final WidgetRef ref;

  const _MessageItem({
    required this.message,
    required this.chatId,
    required this.currentUserAsync,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final senderAsync = ref.watch(
      FutureProvider((ref) async {
        final authService = ref.watch(authServiceProvider);
        return authService.getUserById(message.senderId);
      }),
    );

    return senderAsync.when(
      data: (sender) {
        final isCurrentUser = currentUserAsync.value?.uid == message.senderId;

        return MessageBubble(
          message: message,
          sender: sender,
          isCurrentUser: isCurrentUser,
          onDelete: isCurrentUser
              ? () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Message'),
                      content: const Text(
                        'Are you sure you want to delete this message?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            try {
                              await ref.read(
                                deleteMessageProvider(
                                  DeleteMessageParams(
                                    chatId: chatId,
                                    messageId: message.id,
                                  ),
                                ).future,
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                }
              : null,
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Align(
          alignment: message.senderId == currentUserAsync.value?.uid
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: const SizedBox(width: 200, height: 40, child: Placeholder()),
        ),
      ),
      error: (err, st) => MessageBubble(
        message: message,
        isCurrentUser: message.senderId == currentUserAsync.value?.uid,
      ),
    );
  }
}
