// lib/widgets/reaction_picker.dart
import 'package:flutter/material.dart';

class ReactionPicker extends StatelessWidget {
  final Function(String) onReactionSelected;
  final List<Map<String, dynamic>> reactions = const [
    {'emoji': '❤️', 'label': 'Love'},
    {'emoji': '😊', 'label': 'Smile'},
    {'emoji': '😂', 'label': 'Laugh'},
    {'emoji': '😮', 'label': 'Wow'},
    {'emoji': '😢', 'label': 'Sad'},
    {'emoji': '🙏', 'label': 'Thank'},
    {'emoji': '👍', 'label': 'Like'},
    {'emoji': '👎', 'label': 'Dislike'},
  ];

  const ReactionPicker({
    Key? key,
    required this.onReactionSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Select Reaction',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: reactions.map((reaction) {
              return GestureDetector(
                onTap: () => onReactionSelected(reaction['emoji'] as String),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        reaction['emoji'] as String,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reaction['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}