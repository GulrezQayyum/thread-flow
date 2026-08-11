// lib/ui/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'dart:io';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/storage_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/chat_info_sheet.dart';
import '../widgets/thread_sheet.dart';
import '../widgets/create_thread_dialog.dart';
import '../widgets/add_contact_dialog.dart';

class ChatScreen extends HookConsumerWidget {
  final String chatId;
  final ChatModel chat;

  const ChatScreen({
    super.key, // Use super.key (Dart 2.17+)
    required this.chatId,
    required this.chat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserStreamProvider);
    final messagesAsync = ref.watch(chatMessagesProvider(chatId));
    final messageInputController = useTextEditingController();
    final isSending = useState(false);
    final scrollController = useScrollController();
    final isUploadingMedia = useState(false);
    final selectedThreadId = useState<String?>(null);
    final searchQuery = useState<String?>(null);
    final isSearching = useState(false);

    // Auto-scroll on new messages - FIX: hasData -> hasValue
    useEffect(() {
      if (messagesAsync.hasValue && messagesAsync.value!.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom(scrollController);
        });
      }
      return null;
    }, [messagesAsync.value?.length]);

    return Scaffold(
      appBar: _buildAppBar(
        context,
        ref,
        isSearching,
        searchQuery,
        selectedThreadId,
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                // Filter messages by thread and search
                var filteredMessages = messages;

                if (selectedThreadId.value != null) {
                  filteredMessages = filteredMessages
                      .where((m) => m.threadId == selectedThreadId.value)
                      .toList();
                }

                if (searchQuery.value != null &&
                    searchQuery.value!.isNotEmpty) {
                  filteredMessages = filteredMessages
                      .where(
                        (m) => m.text.toLowerCase().contains(
                          searchQuery.value!.toLowerCase(),
                        ),
                      )
                      .toList();
                }

                if (filteredMessages.isEmpty) {
                  return _buildEmptyState(
                    context,
                    selectedThreadId.value != null,
                    ref,
                  );
                }

                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  itemCount: filteredMessages.length,
                  itemBuilder: (context, index) {
                    final message = filteredMessages[index];
                    final isCurrentUser =
                        currentUserAsync.value?.uid == message.senderId;
                    final isFirstInThread = message.isThreadStart;
                    final showSenderName =
                        !isCurrentUser && chat.members.length > 2;

                    return MessageBubble(
                      message: message,
                      isCurrentUser: isCurrentUser,
                      showSenderName: showSenderName,
                      isFirstInThread: isFirstInThread,
                      onThreadTap: () {
                        selectedThreadId.value = message.threadId;
                        ref.invalidate(chatMessagesProvider(chatId));
                      },
                      onReactionTap: (reaction) {
                        _handleReaction(context, ref, message.id, reaction);
                      },
                      onDeleteTap: () {
                        _showDeleteConfirmation(context, ref, message.id);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) {
                print('❌ CHAT ERROR: $error');
                return _buildErrorState(context, error, ref);
              },
            ),
          ),
          // Message input
          MessageInput(
            controller: messageInputController,
            isLoading: isSending.value,
            isUploadingMedia: isUploadingMedia.value,
            onSend: (text) async {
              if (text.trim().isEmpty) return;
              await _sendMessage(
                context,
                ref,
                text,
                currentUserAsync.value,
                selectedThreadId,
                isSending,
              );
              messageInputController.clear();
              _scrollToBottom(scrollController);
            },
            onMediaPicked: (File? media) async {
              if (media == null) return;
              await _uploadAndSendMedia(
                context,
                ref,
                media,
                currentUserAsync.value,
                selectedThreadId,
                isUploadingMedia,
              );
              _scrollToBottom(scrollController);
            },
            onCameraPicked: (File? media) async {
              if (media == null) return;
              await _uploadAndSendMedia(
                context,
                ref,
                media,
                currentUserAsync.value,
                selectedThreadId,
                isUploadingMedia,
              );
              _scrollToBottom(scrollController);
            },
            onCreateThread: () {
              _showCreateThreadDialog(context, ref, selectedThreadId);
            },
            onClearThread: () {
              selectedThreadId.value = null;
              ref.invalidate(chatMessagesProvider(chatId));
            },
            selectedThreadId: selectedThreadId.value,
          ),
        ],
      ),
    );
  }

  // ==================== APP BAR ====================

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isSearching,
    ValueNotifier<String?> searchQuery,
    ValueNotifier<String?> selectedThreadId,
  ) {
    return AppBar(
      title: Row(
        children: [
          if (chat.photoURL != null)
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(chat.photoURL!),
            ),
          if (chat.photoURL != null) const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chat.name,
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                if (chat.members.length > 2)
                  Text(
                    '${chat.members.length} members',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ],
      ),
      elevation: 1,
      actions: [
        // Search Button
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () =>
              _toggleSearch(context, ref, isSearching, searchQuery),
          tooltip: 'Search Messages',
        ),
        // Threads Button
        IconButton(
          icon: const Icon(Icons.forum_outlined),
          onPressed: () => _showThreadsSheet(context, ref, selectedThreadId),
          tooltip: 'Threads',
        ),
        // Add Contact Button
        IconButton(
          icon: const Icon(Icons.person_add_alt_1),
          onPressed: () => _showAddContactDialog(context, ref),
          tooltip: 'Add Contact',
        ),
        // Chat Info Button
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showChatInfo(context),
          tooltip: 'Chat Info',
        ),
      ],
      bottom: isSearching.value
          ? PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: _buildSearchBar(context, ref, isSearching, searchQuery),
            )
          : null,
    );
  }

  // ==================== SEARCH BAR ====================

  Widget _buildSearchBar(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isSearching,
    ValueNotifier<String?> searchQuery,
  ) {
    final searchController = useTextEditingController();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search messages...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    searchQuery.value = null;
                    isSearching.value = false;
                    ref.invalidate(chatMessagesProvider(chatId));
                  },
                ),
              ),
              onChanged: (value) {
                searchQuery.value = value;
                ref.invalidate(chatMessagesProvider(chatId));
              },
            ),
          ),
          TextButton(
            onPressed: () {
              isSearching.value = false;
              searchQuery.value = null;
              ref.invalidate(chatMessagesProvider(chatId));
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _toggleSearch(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isSearching,
    ValueNotifier<String?> searchQuery,
  ) {
    isSearching.value = !isSearching.value;
    if (!isSearching.value) {
      searchQuery.value = null;
      ref.invalidate(chatMessagesProvider(chatId));
    }
  }

  // ==================== EMPTY STATE ====================

  Widget _buildEmptyState(
    BuildContext context,
    bool hasThreadSelected,
    WidgetRef ref,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasThreadSelected ? Icons.forum_outlined : Icons.chat_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            hasThreadSelected
                ? 'No messages in this thread'
                : 'No messages yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            hasThreadSelected
                ? 'Switch to another thread'
                : 'Start the conversation!',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (!hasThreadSelected)
            ElevatedButton.icon(
              onPressed: () => _showCreateThreadDialog(context, ref, null),
              icon: const Icon(Icons.forum_outlined),
              label: const Text('Create New Thread'),
            ),
        ],
      ),
    );
  }

  // ==================== ERROR STATE ====================

  Widget _buildErrorState(BuildContext context, dynamic error, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error loading messages',
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
                ref.invalidate(chatMessagesProvider(chatId));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== SCROLL HELPERS ====================

  void _scrollToBottom(ScrollController controller) {
    if (controller.hasClients) {
      controller.animateTo(
        controller.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // ==================== MESSAGE OPERATIONS ====================

  Future<void> _sendMessage(
    BuildContext context,
    WidgetRef ref,
    String text,
    UserModel? currentUser,
    ValueNotifier<String?> selectedThreadId,
    ValueNotifier<bool> isSending,
  ) async {
    if (currentUser == null) {
      print('❌ No current user');
      return;
    }

    isSending.value = true;
    try {
      final threadId =
          selectedThreadId.value ??
          DateTime.now().millisecondsSinceEpoch.toString();
      final isNewThread = selectedThreadId.value == null;

      print('📤 SENDING: text="$text", threadId="$threadId"');

      final message = await ref.read(
        sendMessageProvider(
          SendMessageParams(
            chatId: chatId,
            senderId: currentUser.uid,
            text: text.trim(),
            mediaUrl: null,
            threadId: threadId,
            isThreadStart: isNewThread,
          ),
        ).future,
      );

      print('✅ Message sent: ${message.id}');

      if (isNewThread) {
        selectedThreadId.value = threadId;
      }
    } catch (e) {
      print('❌ Error sending message: $e');
      _showErrorSnackBar(context, e.toString());
    } finally {
      isSending.value = false;
    }
  }

  Future<void> _uploadAndSendMedia(
    BuildContext context,
    WidgetRef ref,
    File media,
    UserModel? currentUser,
    ValueNotifier<String?> selectedThreadId,
    ValueNotifier<bool> isUploadingMedia,
  ) async {
    if (currentUser == null) return;

    isUploadingMedia.value = true;
    try {
      final threadId =
          selectedThreadId.value ??
          DateTime.now().millisecondsSinceEpoch.toString();
      final isNewThread = selectedThreadId.value == null;

      final messageId = DateTime.now().millisecondsSinceEpoch.toString();

      final imageUrl = await ref.read(
        uploadImageProvider(
          UploadImageParams(
            chatId: chatId,
            messageId: messageId,
            imageFile: media,
          ),
        ).future,
      );

      await ref.read(
        sendMessageProvider(
          SendMessageParams(
            chatId: chatId,
            senderId: currentUser.uid,
            text: '📷 Image',
            mediaUrl: imageUrl,
            threadId: threadId,
            isThreadStart: isNewThread,
          ),
        ).future,
      );

      if (isNewThread) {
        selectedThreadId.value = threadId;
      }
    } catch (e) {
      _showErrorSnackBar(context, e.toString());
    } finally {
      isUploadingMedia.value = false;
    }
  }

  void _handleReaction(
    BuildContext context,
    WidgetRef ref,
    String messageId,
    String reaction,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added reaction: $reaction'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    String messageId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(
                  deleteMessageProvider(
                    DeleteMessageParams(chatId: chatId, messageId: messageId),
                  ).future,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message deleted'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                _showErrorSnackBar(context, e.toString());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ==================== ERROR HANDLING ====================

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $message'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ==================== DIALOGS AND SHEETS ====================

  void _showThreadsSheet(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<String?> selectedThreadId,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => ThreadsSheet(
        chatId: chatId,
        onThreadSelected: (threadId) {
          selectedThreadId.value = threadId;
          ref.invalidate(chatMessagesProvider(chatId));
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showCreateThreadDialog(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<String?>? selectedThreadId,
  ) {
    showDialog(
      context: context,
      builder: (context) => CreateThreadDialog(
        chatId: chatId,
        onThreadCreated: (threadId) {
          if (selectedThreadId != null) {
            selectedThreadId.value = threadId;
          }
          ref.invalidate(chatMessagesProvider(chatId));
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('New thread created!')));
        },
      ),
    );
  }

  void _showAddContactDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AddContactDialog(
        chatId: chatId,
        chat: chat,
        onContactAdded: () {
          ref.invalidate(chatMessagesProvider(chatId));
          ref.invalidate(userChatsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contact added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _showChatInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => ChatInfoSheet(chat: chat),
    );
  }
}
