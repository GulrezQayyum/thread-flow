import 'package:flutter/material.dart';

class ReactionPicker extends StatelessWidget {
  final Function(String) onReactionSelected;
  final List<String> reactions = const ['❤️', '😊', '😂', '😮', '😢', '🙏', '👍', '👎'];

  const ReactionPicker({Key? key, required this.onReactionSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Select Reaction',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: reactions.map((reaction) {
              return GestureDetector(
                onTap: () => onReactionSelected(reaction),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    reaction,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}