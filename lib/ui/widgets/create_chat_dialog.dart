import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateChatDialog extends HookConsumerWidget {
  const CreateChatDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatNameController = useTextEditingController();
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);

    return AlertDialog(
      title: const Text('Create New Chat'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chat name input
            TextField(
              controller: chatNameController,
              decoration: const InputDecoration(
                labelText: 'Chat Name',
                hintText: 'e.g., Project Discussion',
                prefixIcon: Icon(Icons.chat_outlined),
              ),
              enabled: !isLoading.value,
              onChanged: (_) {
                // Clear error when user types
                if (errorMessage.value != null) {
                  errorMessage.value = null;
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Members info
            Text(
              'Members',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You will be added automatically. Add more members after creation.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            
            // Error message display
            if (errorMessage.value != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorMessage.value!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        // Cancel button
        TextButton(
          onPressed: isLoading.value ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        
        // Create chat button
        ElevatedButton(
          onPressed: isLoading.value
              ? null
              : () async {
                  errorMessage.value = null;

                  // Validate chat name
                  if (chatNameController.text.trim().isEmpty) {
                    errorMessage.value = 'Please enter a chat name';
                    return;
                  }

                  isLoading.value = true;
                  try {
                    // Get auth service and current Firebase user
                    final authService = ref.read(authServiceProvider);
                    final firebaseUser = authService.currentUser;

                    // Check if user is logged in
                    if (firebaseUser == null) {
                      errorMessage.value = 'Please sign in first';
                      isLoading.value = false;
                      return;
                    }

                    print('👤 Creating chat for user: ${firebaseUser.uid}');

                    // Create chat with current user as member
                    final chat = await ref.read(
                      createChatProvider(
                        CreateChatParams(
                          name: chatNameController.text.trim(),
                          members: [firebaseUser.uid],
                          createdBy: firebaseUser.uid,
                        ),
                      ).future,
                    );

                    print('✅ Chat created: ${chat.id}');

                    // Close dialog and show success message
                    if (context.mounted) {
                      Navigator.pop(context);
                      
                      // Show success snackbar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Chat "${chat.name}" created successfully! 🎉',
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } on FirebaseAuthException catch (e) {
                    print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
                    errorMessage.value = 'Auth error: ${e.message}';
                  } catch (e) {
                    print('❌ Error creating chat: $e');
                    errorMessage.value = 
                        e.toString().replaceFirst('Exception: ', '');
                  } finally {
                    isLoading.value = false;
                  }
                },
          child: isLoading.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Create Chat'),
        ),
      ],
    );
  }
}