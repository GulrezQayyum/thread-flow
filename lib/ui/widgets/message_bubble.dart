import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final UserModel? sender;
  final bool isCurrentUser;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;

  const MessageBubble({
    Key? key,
    required this.message,
    this.sender,
    required this.isCurrentUser,
    this.onReply,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onDelete != null ? onDelete : null,
        child: Container(
          margin: EdgeInsets.only(
            left: isCurrentUser ? 60 : 8,
            right: isCurrentUser ? 8 : 60,
            top: 4,
            bottom: 4,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isCurrentUser
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sender name (if not current user)
              if (!isCurrentUser && sender != null)
                Text(
                  sender!.displayName,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              // Message text
              Text(
                message.text,
                style: TextStyle(
                  color: isCurrentUser ? Colors.white : null,
                  fontSize: 14,
                ),
              ),
              // Media image (if exists)
              if (message.mediaUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      message.mediaUrl!,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              // Timestamp
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  DateFormat('HH:mm').format(message.createdAt),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isCurrentUser ? Colors.white70 : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
