// lib/ui/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends HookConsumerWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 1,
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
                // Profile header
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ),
                  child: Center(
                    child: Text(
                      (user.displayName ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.displayName ?? 'User',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  user.email ?? 'No email',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),

                // Stats
                Row(
                  children: [
                    _buildStatCard(context, 'Messages', '0'),
                    _buildStatCard(context, 'Chats', '0'),
                    _buildStatCard(context, 'Rating', '4.9'),
                  ],
                ),
                const SizedBox(height: 24),

                // Account info
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.badge),
                    title: const Text('User ID'),
                    subtitle: Text(user.uid.substring(0, 12) + '...'),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('Email Status'),
                    subtitle: Text(user.emailVerified ? '✓ Verified' : 'Not Verified'),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Member Since'),
                    subtitle: Text(_formatDate(user.createdAt)),
                  ),
                ),

                const SizedBox(height: 24),

                // Actions
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showChangePasswordDialog(context),
                    icon: const Icon(Icons.lock),
                    label: const Text('Change Password'),
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
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Current password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'New password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Confirm new password',
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
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password changed successfully')),
              );
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}