// lib/ui/widgets/create_chat_dialog_simple.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

class CreateChatDialog extends HookConsumerWidget {
  const CreateChatDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final isLoading = useState(false);
    final error = useState<String?>(null);

    return AlertDialog(
      title: const Text('Create New Chat'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Chat Name',
              hintText: 'e.g., Project Work',
            ),
            onChanged: (_) {
              error.value = null;
            },
          ),
          if (error.value != null) ...[
            const SizedBox(height: 16),
            Text(
              error.value!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: isLoading.value ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading.value
              ? null
              : () async {
                  if (nameController.text.trim().isEmpty) {
                    error.value = 'Please enter a chat name';
                    return;
                  }

                  isLoading.value = true;
                  try {
                    print('➕ CREATE: Creating chat...');
                    
                    final authService = ref.read(authServiceProvider);
                    final firebaseUser = authService.currentUser;

                    if (firebaseUser == null) {
                      throw Exception('User not logged in');
                    }

                    print('👤 CREATE: User ID: ${firebaseUser.uid}');

                    final chat = await ref.read(
                      createChatProvider(
                        CreateChatParams(
                          name: nameController.text.trim(),
                          members: [firebaseUser.uid],
                          createdBy: firebaseUser.uid,
                        ),
                      ).future,
                    );

                    print('✅ CREATE: Chat created: ${chat.id}');

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Chat "${chat.name}" created! ✅'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    print('❌ CREATE ERROR: $e');
                    error.value = 'Error: $e';
                  } finally {
                    isLoading.value = false;
                  }
                },
          child: isLoading.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}