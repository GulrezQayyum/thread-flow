// lib/ui/screens/home_screen_enhanced.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../widgets/chat_list.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';


class HomeScreen extends HookConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserStreamProvider);
    final user = currentUserAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ThreadFlow'),
        elevation: 1,
        actions: [
          // Profile icon
          Consumer(
            builder: (context, ref, _) {
              final userAsync = ref.watch(currentUserStreamProvider);
              return userAsync.when(
                data: (user) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileScreen(),
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      radius: 18,
                      child: Text(
                        (user?.displayName ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                loading: () => const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => const SizedBox(),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, ref),
      body: user != null
          ? ChatList(userId: user.uid)
          : const Center(child: Text('Not logged in')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateChatDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Consumer(
            builder: (context, ref, _) {
              final userAsync = ref.watch(currentUserStreamProvider);
              return userAsync.when(
                data: (user) => UserAccountsDrawerHeader(
                  accountName: Text(user?.displayName ?? 'User'),
                  accountEmail: Text(user?.email ?? 'No email'),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      (user?.displayName ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                loading: () => const DrawerHeader(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const DrawerHeader(child: SizedBox()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help & Support')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ThreadFlow v1.0.0')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () {
              Navigator.pop(context);
              ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
    );
  }

  void _showCreateChatDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Chat'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Chat name',
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
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final currentUser = ref.read(currentUserStreamProvider).value;
                if (currentUser != null) {
                  ref.read(createChatProvider(
                    CreateChatParams(
                      name: name,
                      members: [currentUser.uid],
                      createdBy: currentUser.uid,
                    ),
                  ).future);
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Chat "$name" created')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}