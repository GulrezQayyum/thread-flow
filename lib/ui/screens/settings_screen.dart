// lib/ui/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SettingsScreen extends HookConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = useState(Theme.of(context).brightness == Brightness.dark);
    final notificationsEnabled = useState(true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 1,
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Display'),
          _buildSwitchTile(
            context,
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            subtitle: 'Enable dark theme',
            value: isDarkMode.value,
            onChanged: (value) => isDarkMode.value = value,
          ),

          _buildSectionHeader(context, 'Notifications'),
          _buildSwitchTile(
            context,
            icon: Icons.notifications,
            title: 'Enable Notifications',
            subtitle: 'Receive message notifications',
            value: notificationsEnabled.value,
            onChanged: (value) => notificationsEnabled.value = value,
          ),

          _buildSectionHeader(context, 'Data & Storage'),
          _buildSimpleTile(
            context,
            icon: Icons.storage,
            title: 'Storage Usage',
            subtitle: '125 MB used',
          ),
          _buildSimpleTile(
            context,
            icon: Icons.delete_sweep,
            title: 'Clear Cache',
            subtitle: 'Delete cached data',
            onTap: () => _showClearCacheDialog(context),
          ),

          _buildSectionHeader(context, 'About'),
          _buildSimpleTile(
            context,
            icon: Icons.info,
            title: 'App Version',
            subtitle: 'ThreadFlow v1.0.0',
          ),
          _buildSimpleTile(
            context,
            icon: Icons.help,
            title: 'Help & Support',
            subtitle: 'Get help or report an issue',
          ),
          _buildSimpleTile(
            context,
            icon: Icons.description,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SwitchListTile(
        secondary: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSimpleTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will delete all cached data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}