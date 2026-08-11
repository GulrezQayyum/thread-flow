import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'dart:io';
import '../../providers/storage_provider.dart';

class MessageInput extends HookConsumerWidget {
  final TextEditingController controller;
  final Function(String) onSend;
  final Function(File?) onMediaPicked;
  final Function(File?) onCameraPicked;
  final VoidCallback onCreateThread;
  final VoidCallback onClearThread;
  final String? selectedThreadId;
  final bool isLoading;
  final bool isUploadingMedia;

  const MessageInput({
    Key? key,
    required this.controller,
    required this.onSend,
    required this.onMediaPicked,
    required this.onCameraPicked,
    required this.onCreateThread,
    required this.onClearThread,
    this.selectedThreadId,
    this.isLoading = false,
    this.isUploadingMedia = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusNode = useFocusNode();
    final isFocused = useState(false);

    useEffect(() {
      void listener() {
        isFocused.value = focusNode.hasFocus;
      }
      focusNode.addListener(listener);
      return () => focusNode.removeListener(listener);
    }, [focusNode]);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Show current thread indicator
        if (selectedThreadId != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            child: Row(
              children: [
                Icon(
                  Icons.forum_outlined,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Replying in thread: ${selectedThreadId!.substring(0, 8)}...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: onClearThread,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        Container(
          padding: EdgeInsets.only(
            left: 8,
            right: 8,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 8,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: Row(
            children: [
              // Media button using your pickers
              PopupMenuButton<String>(
                icon: isUploadingMedia
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.attach_file,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                onSelected: (value) async {
                  if (value == 'gallery') {
                    final file = await ref.read(pickImageProvider.future);
                    if (file != null) onMediaPicked(file);
                  } else if (value == 'camera') {
                    final file = await ref.read(pickImageFromCameraProvider.future);
                    if (file != null) onCameraPicked(file);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'gallery',
                    child: Row(
                      children: [
                        Icon(Icons.photo_library),
                        SizedBox(width: 8),
                        Text('Gallery'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'camera',
                    child: Row(
                      children: [
                        Icon(Icons.camera_alt),
                        SizedBox(width: 8),
                        Text('Camera'),
                      ],
                    ),
                  ),
                ],
                enabled: !isLoading && !isUploadingMedia,
              ),
              const SizedBox(width: 4),
              // Text input
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: selectedThreadId != null 
                        ? 'Reply in thread...' 
                        : 'Type a message or start a thread...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: isFocused.value
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).dividerColor,
                      ),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  enabled: !isLoading && !isUploadingMedia,
                ),
              ),
              const SizedBox(width: 4),
              // Thread button
              IconButton(
                icon: Icon(
                  selectedThreadId != null ? Icons.forum : Icons.forum_outlined,
                  color: selectedThreadId != null
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                onPressed: isLoading || isUploadingMedia ? null : onCreateThread,
                tooltip: selectedThreadId != null 
                    ? 'Create New Thread' 
                    : 'Start New Thread',
              ),
              // Send button
              IconButton(
                icon: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.send,
                        color: controller.text.isEmpty
                            ? Theme.of(context).disabledColor
                            : Theme.of(context).colorScheme.primary,
                      ),
                onPressed: isLoading || isUploadingMedia || controller.text.isEmpty
                    ? null
                    : () {
                        final text = controller.text;
                        onSend(text);
                      },
              ),
            ],
          ),
        ),
      ],
    );
  }
}