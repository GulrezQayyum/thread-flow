// lib/ui/screens/chat_screen.dart (UPDATED FOR DAY 3)
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'dart:io';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/message_provider.dart';
import '../../providers/storage_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/user_avatar.dart';

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
    final selectedImage = useState<File?>(null);
    final isUploadingImage = useState(false);
    final scrollController = useScrollController();

    return Scaffold(
      appBar: AppBar(
        title: Text(chatName),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search coming soon')),
              );
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('View Info'),
                onTap: () {
                  // TODO: Show chat info
                },
              ),
              PopupMenuItem(
                child: const Text('Mute Notifications'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifications muted')),
                  );
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
              // Chat summary banner
              // Chat summary banner
              chatAsync.when(
                data: (chat) {
                  if (chat?.summary != null && chat!.summary!.isNotEmpty) {
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
                              'Summary: ${chat.summary}',
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
              // Messages list
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
                              'Start the conversation!',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
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
              // Selected image preview
              if (selectedImage.value != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          selectedImage.value!,
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => selectedImage.value = null,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Message input
              MessageInput(
                controller: messageInputController,
                isLoading: isSending.value || isUploadingImage.value,
                onSend: (text) async {
                  isSending.value = true;
                  try {
                    final currentUser = currentUserAsync.value;
                    if (currentUser != null) {
                      // Send message
                      final message = await ref.read(
                        sendMessageProvider(
                          SendMessageParams(
                            chatId: chatId,
                            senderId: currentUser.uid,
                            text: text,
                            mediaUrl: null,
                          ),
                        ).future,
                      );

                      // If image selected, upload it
                      if (selectedImage.value != null) {
                        isUploadingImage.value = true;
                        try {
                          final imageUrl = await ref.read(
                            uploadImageProvider(
                              UploadImageParams(
                                chatId: chatId,
                                messageId: message.id,
                                imageFile: selectedImage.value!,
                              ),
                            ).future,
                          );

                          // Update message with image URL
                          // (In production, you'd update Firestore here)
                          selectedImage.value = null;
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error uploading image: $e'),
                            ),
                          );
                        } finally {
                          isUploadingImage.value = false;
                        }
                      }

                      messageInputController.clear();

                      // Scroll to bottom
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (scrollController.hasClients) {
                          scrollController.animateTo(
                            0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      });
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  } finally {
                    isSending.value = false;
                  }
                },
                onAttachMedia: () async {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Pick Image From',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      try {
                                        // Using a simple approach - just pick image for display
                                        final imagePicker = ref.read(
                                          storageServiceProvider,
                                        );
                                        final image = await imagePicker
                                            .pickImage();
                                        if (image != null) {
                                          selectedImage.value = image;
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                          }
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    },
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.image,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text('Gallery'),
                                ],
                              ),
                              Column(
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      try {
                                        final imagePicker = ref.read(
                                          storageServiceProvider,
                                        );
                                        final image = await imagePicker
                                            .pickImageFromCamera();
                                        if (image != null) {
                                          selectedImage.value = image;
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                          }
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    },
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.camera_alt,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text('Camera'),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
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
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(width: 200, height: 40, child: Placeholder()),
        ),
      ),
      error: (err, st) => MessageBubble(
        message: message,
        isCurrentUser: message.senderId == currentUserAsync.value?.uid,
      ),
    );
  }
}
