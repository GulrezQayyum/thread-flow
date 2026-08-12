// lib/ui/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../widgets/chat_list.dart';
import '../widgets/create_chat_dialog.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ThreadFlow'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        // FIX: Use authControllerProvider instead of authServiceProvider
                        ref.read(authControllerProvider.notifier).signOut();
                        Navigator.pop(context);
                      },
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Not logged in'));
          }
          
          return ChatList(userId: user.uid);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const CreateChatDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Chat'),
      ),
    );
  }
}