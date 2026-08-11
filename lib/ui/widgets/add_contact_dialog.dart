// lib/widgets/add_contact_dialog.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/service_providers.dart';

class AddContactDialog extends ConsumerStatefulWidget {
  final String chatId;
  final ChatModel chat;
  final VoidCallback onContactAdded;

  const AddContactDialog({
    Key? key,
    required this.chatId,
    required this.chat,
    required this.onContactAdded,
  }) : super(key: key);

  @override
  ConsumerState<AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends ConsumerState<AddContactDialog> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSearching = false;
  String? _searchResult;
  UserModel? _foundUser;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Contact'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add someone to "${widget.chat.name}"',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'Enter email address',
                prefixIcon: const Icon(Icons.email),
                border: const OutlineInputBorder(),
                suffixIcon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _searchUser,
                      ),
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading,
            ),
            if (_foundUser != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: _foundUser!.photoURL != null
                          ? NetworkImage(_foundUser!.photoURL!)
                          : null,
                      child: _foundUser!.photoURL == null
                          ? Text(_foundUser!.displayName[0].toUpperCase())
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _foundUser!.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _foundUser!.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              ),
            ],
            if (_searchResult != null && _foundUser == null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _searchResult!,
                        style: TextStyle(color: Colors.red[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Current members: ${widget.chat.members.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _foundUser == null || _isLoading ? null : _addContact,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
  }

  void _searchUser() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      if (mounted) {
        setState(() {
          _searchResult = 'Please enter an email address';
          _foundUser = null;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isSearching = true;
        _searchResult = null;
        _foundUser = null;
      });
    }

    try {
      final users = await ref.read(searchUsersProvider(email).future);
      
      if (!mounted) return;

      if (users.isEmpty) {
        setState(() {
          _searchResult = '❌ No user found with this email';
          _foundUser = null;
        });
        return;
      }

      final user = users.first;
      
      if (widget.chat.members.contains(user.uid)) {
        setState(() {
          _searchResult = '⚠️ User is already in this chat';
          _foundUser = null;
        });
        return;
      }

      setState(() {
        _foundUser = user;
        _searchResult = '✅ User found! Ready to add.';
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResult = '❌ Error searching for user: $e';
          _foundUser = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _addContact() async {
    if (_foundUser == null) return;

    setState(() => _isLoading = true);
    
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      
      await firestoreService.addUserToChat(
        chatId: widget.chatId,
        userId: _foundUser!.uid, // Fixed: was 'userid' now 'userId'
      );

      widget.onContactAdded();
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding contact: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}