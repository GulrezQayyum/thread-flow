import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class MessageInput extends HookWidget {
  final TextEditingController? controller;
  final Function(String) onSend;
  final bool isLoading;
  final VoidCallback? onAttachMedia;

  const MessageInput({
    Key? key,
    this.controller,
    required this.onSend,
    this.isLoading = false,
    this.onAttachMedia,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textController = controller ?? useTextEditingController();
    final focusNode = useFocusNode();
    final isFocused = useState(false);

    useEffect(() {
      void handleFocusChange() {
        isFocused.value = focusNode.hasFocus;
      }
      focusNode.addListener(handleFocusChange);
      return () => focusNode.removeListener(handleFocusChange);
    }, [focusNode]);

    return Container(
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
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: isLoading ? null : onAttachMedia,
            tooltip: 'Attach media',
          ),
          Expanded(
            child: TextField(
              controller: textController,
              focusNode: focusNode,
              onChanged: (_) {},
              maxLines: null,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: isFocused.value
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).dividerColor,
                  ),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
              ),
              enabled: !isLoading,
            ),
          ),
          const SizedBox(width: 8),
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
                    color: textController.text.isEmpty
                        ? Theme.of(context).disabledColor
                        : Theme.of(context).colorScheme.primary,
                  ),
            onPressed: isLoading || textController.text.isEmpty
                ? null
                : () {
                    final text = textController.text;
                    textController.clear();
                    onSend(text);
                  },
            tooltip: 'Send message',
          ),
        ],
      ),
    );
  }
}