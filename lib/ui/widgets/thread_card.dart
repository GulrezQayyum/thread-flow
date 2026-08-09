import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ThreadCard extends StatelessWidget {
  final String threadId;
  final String firstMessage;
  final String firstSenderName;
  final DateTime startedAt;
  final int messageCount;
  final String? summary;
  final VoidCallback onTap;

  const ThreadCard({
    Key? key,
    required this.threadId,
    required this.firstMessage,
    required this.firstSenderName,
    required this.startedAt,
    required this.messageCount,
    this.summary,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isToday = DateTime.now().difference(startedAt).inDays == 0;
    final timeStr = isToday
        ? DateFormat('HH:mm').format(startedAt)
        : DateFormat('MMM d').format(startedAt);

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          child: Text(
            messageCount.toString(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          firstMessage.length > 60
              ? '${firstMessage.substring(0, 60)}...'
              : firstMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (summary != null)
              Text(
                summary!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              Text(
                'Started by $firstSenderName',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 4),
            Text(
              '$messageCount replies • $timeStr',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
