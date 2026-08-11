import 'package:flutter/material.dart';
import '../../models/thread_model.dart';

class ThreadSelector extends StatelessWidget {
  final List<ThreadModel> threads;
  final String? selectedThreadId;
  final Function(String) onThreadSelected;

  const ThreadSelector({
    Key? key,
    required this.threads,
    this.selectedThreadId,
    required this.onThreadSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: threads.length + 1, // +1 for "All" option
        itemBuilder: (context, index) {
          if (index == 0) {
            // "All" threads option
            return _buildThreadChip(
              context,
              'All',
              selectedThreadId == null,
              () => onThreadSelected(''),
            );
          }
          
          final thread = threads[index - 1];
          final isSelected = selectedThreadId == thread.threadId;
          
          return _buildThreadChip(
            context,
            thread.firstMessage.length > 20
                ? '${thread.firstMessage.substring(0, 20)}...'
                : thread.firstMessage,
            isSelected,
            () => onThreadSelected(thread.threadId),
          );
        },
      ),
    );
  }

  Widget _buildThreadChip(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forum_outlined, size: 14),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: Theme.of(context).colorScheme.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : null,
        ),
      ),
    );
  }
}