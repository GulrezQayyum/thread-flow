// lib/widgets/typing_indicator.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../providers/typing_provider.dart';

class TypingIndicator extends ConsumerWidget {
  final String chatId;
  final String currentUserId;
  final String currentUserName;

  const TypingIndicator({
    Key? key,
    required this.chatId,
    required this.currentUserId,
    required this.currentUserName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typingUsersAsync = ref.watch(watchTypingUsersProvider(chatId));

    return typingUsersAsync.when(
      data: (typingUsers) {
        // Remove current user from typing list
        final filteredUsers = typingUsers
            .where((name) => name != currentUserName)
            .toList();

        if (filteredUsers.isEmpty) {
          return const SizedBox.shrink();
        }

        final displayText = filteredUsers.length == 1
            ? '${filteredUsers[0]} is typing...'
            : '${filteredUsers.join(', ')} are typing...';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              _AnimatedDots(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// Animated dots for typing indicator
class _AnimatedDots extends HookWidget {
  const _AnimatedDots({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 600),
    );

    useEffect(() {
      controller.repeat();
      return controller.dispose;
    }, []);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final offset = index * 0.15;
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final position = (controller.value + offset) % 1.0;
            final scale = (math.sin(position * math.pi) * 0.5 + 0.5);

            return Transform.scale(
              scale: scale,
              child: Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}