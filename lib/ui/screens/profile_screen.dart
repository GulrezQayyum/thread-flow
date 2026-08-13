// lib/ui/screens/profile_screen.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/message_provider.dart';
import '../../models/user_model.dart';
import '../../models/chat_model.dart';
import '../widgets/user_avatar.dart';

class ProfileScreen extends HookConsumerWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.value;

    // Get chat count
    final chatsAsync = user != null
        ? ref.watch(userChatsProvider(user.uid))
        : null;
    final chatCount = chatsAsync?.value?.length ?? 0;

    // Get message count from all chats
    final messageCount = useState(0);

    // Load message count when user is available
    useEffect(() {
      if (user != null && chatsAsync?.value != null) {
        _loadMessageCount(ref, user.uid, chatsAsync!.value!, messageCount);
      }
      return null;
    }, [chatsAsync?.value]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditProfileDialog(context, ref, user),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('No user logged in'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Avatar
                _buildProfileAvatar(context, user, ref),
                const SizedBox(height: 16),

                // User Name
                Text(
                  user.displayName ?? 'User',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                // User Email
                Text(
                  user.email ?? 'No email',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),

                // Stats
                Row(
                  children: [
                    _buildStatCard(
                      context,
                      'Messages',
                      messageCount.value.toString(),
                    ),
                    _buildStatCard(context, 'Chats', chatCount.toString()),
                    _buildStatCard(context, 'Rating', '4.9'),
                  ],
                ),
                const SizedBox(height: 24),

                // Account info
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.badge, color: Colors.blue),
                    title: const Text('User ID'),
                    subtitle: Text('${user.uid.substring(0, 12)}...'),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: Icon(
                      user.emailVerified ? Icons.verified : Icons.warning,
                      color: user.emailVerified ? Colors.green : Colors.orange,
                    ),
                    title: const Text('Email Status'),
                    subtitle: Text(
                      user.emailVerified ? '✓ Verified' : '⚠️ Not Verified',
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.calendar_today,
                      color: Colors.purple,
                    ),
                    title: const Text('Member Since'),
                    subtitle: Text(_formatDate(user.createdAt)),
                  ),
                ),

                const SizedBox(height: 24),

                // Actions
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showChangePasswordDialog(context, ref),
                    icon: const Icon(Icons.lock),
                    label: const Text('Change Password'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(authServiceProvider).signOut();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==================== LOAD MESSAGE COUNT ====================

  Future<void> _loadMessageCount(
    WidgetRef ref,
    String userId,
    List<ChatModel> chats,
    ValueNotifier<int> messageCount,
  ) async {
    int totalMessages = 0;
    for (var chat in chats) {
      try {
        final messages = await ref.read(chatMessagesProvider(chat.id).future);
        totalMessages += messages.length;
      } catch (e) {
        // Skip if error
      }
    }
    messageCount.value = totalMessages;
  }

  // ==================== PROFILE AVATAR ====================

  // In the build method, add a key to UserAvatar
  Widget _buildProfileAvatar(
    BuildContext context,
    UserModel user,
    WidgetRef ref,
  ) {
    return GestureDetector(
      onTap: () => _pickAndSetAvatar(context, ref, user),
      child: Stack(
        children: [
          // Add a key that changes when avatar updates
          UserAvatar(
            key: ValueKey(
              'avatar_${user.avatarBase64?.length ?? 0}',
            ), // Force rebuild on change
            photoURL: user.photoURL,
            avatarBase64: user.avatarBase64,
            displayName: user.displayName ?? 'User',
            size: 120,
          ),
          // Edit badge
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== STAT CARD ====================

  Widget _buildStatCard(BuildContext context, String label, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== FORMAT DATE ====================

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // ==================== PICK AND SET AVATAR (Base64) ====================

  Future<void> _pickAndSetAvatar(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 150,
        maxHeight: 150,
        imageQuality: 50,
      );

      if (image == null) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Processing image...')));

      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final sizeInKB = base64Image.length ~/ 1024;
      print('📤 Avatar size: $sizeInKB KB');

      if (sizeInKB > 800) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image too large! Please use a smaller image.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Update profile picture
      await ref
          .read(authControllerProvider.notifier)
          .updateProfilePicture(base64Image: base64Image);

      // Force rebuild by invalidating
      ref.invalidate(currentUserStreamProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Avatar upload error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  // ==================== EDIT PROFILE DIALOG ====================

  void _showEditProfileDialog(
    BuildContext context,
    WidgetRef ref,
    UserModel? user,
  ) {
    if (user == null) return;

    final nameController = TextEditingController(text: user.displayName ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty && newName != user.displayName) {
                await ref
                    .read(authControllerProvider.notifier)
                    .updateDisplayName(newName);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ==================== CHANGE PASSWORD DIALOG ====================

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final currentPwd = currentPasswordController.text.trim();
              final newPwd = newPasswordController.text.trim();
              final confirmPwd = confirmPasswordController.text.trim();

              if (newPwd != confirmPwd) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }

              if (newPwd.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password must be at least 6 characters'),
                  ),
                );
                return;
              }

              try {
                await ref
                    .read(authControllerProvider.notifier)
                    .changePassword(
                      currentPassword: currentPwd,
                      newPassword: newPwd,
                    );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password changed successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}
