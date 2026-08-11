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
  final FocusNode _focusNode = FocusNode();
  
  bool _isLoading = false;
  bool _isSearching = false;
  String? _searchResult;
  UserModel? _foundUser;
  bool _isAlreadyMember = false;

  @override
  void dispose() {
    _emailController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.person_add_alt_1,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('Add Member'),
        ],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subtitle
            Text(
              'Add someone to "${widget.chat.name}"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            
            // Email input with search
            TextField(
              controller: _emailController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Enter email address',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _searchUser,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading,
              onSubmitted: (_) => _searchUser(),
              textInputAction: TextInputAction.search,
            ),
            
            const SizedBox(height: 16),
            
            // Search result - User found
            if (_foundUser != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isAlreadyMember ? Colors.orange[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isAlreadyMember ? Colors.orange[200]! : Colors.green[200]!,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundImage: _foundUser!.photoURL != null
                          ? NetworkImage(_foundUser!.photoURL!)
                          : null,
                      backgroundColor: Colors.grey[200],
                      child: _foundUser!.photoURL == null
                          ? Text(
                              _foundUser!.displayName[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _foundUser!.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _foundUser!.email,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (_isAlreadyMember) ...[
                            const SizedBox(height: 2),
                            Text(
                              '⚠️ Already a member',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!_isAlreadyMember)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Search result - Error / Not found
            if (_searchResult != null && _foundUser == null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _searchResult!,
                        style: TextStyle(
                          color: Colors.red[800],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Current members count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue[200]!, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.people_outline, size: 18, color: Colors.blue[700]),
                  const SizedBox(width: 10),
                  Text(
                    '${widget.chat.members.length} members in this chat',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _foundUser == null || _isAlreadyMember || _isLoading
              ? null
              : _addContact,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: _foundUser != null && !_isAlreadyMember
                ? null
                : Colors.grey,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Text(
                  'Add Member',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }

  // ==================== SEARCH USER ====================

  Future<void> _searchUser() async {
    final email = _emailController.text.trim();
    
    // Validate email
    if (email.isEmpty) {
      setState(() {
        _searchResult = 'Please enter an email address';
        _foundUser = null;
        _isAlreadyMember = false;
      });
      return;
    }

    // Basic email validation
    if (!_isValidEmail(email)) {
      setState(() {
        _searchResult = 'Please enter a valid email address';
        _foundUser = null;
        _isAlreadyMember = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResult = null;
      _foundUser = null;
      _isAlreadyMember = false;
    });

    try {
      final users = await ref.read(searchUsersProvider(email).future);
      
      if (!mounted) return;

      if (users.isEmpty) {
        setState(() {
          _searchResult = '❌ No user found with this email.\nThey need to sign up first.';
          _foundUser = null;
        });
        return;
      }

      final user = users.first;
      
      // Check if user is already a member
      final isAlreadyMember = widget.chat.members.contains(user.uid);
      
      setState(() {
        _foundUser = user;
        _isAlreadyMember = isAlreadyMember;
        _searchResult = isAlreadyMember 
            ? '⚠️ User is already a member of this chat'
            : '✅ User found! Ready to add.';
      });
    } catch (e) {
      setState(() {
        _searchResult = '❌ Error searching for user: $e';
        _foundUser = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  // ==================== ADD CONTACT ====================

  Future<void> _addContact() async {
    if (_foundUser == null) return;

    setState(() => _isLoading = true);
    
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      
      // Add user to chat
      await firestoreService.addUserToChat(
        chatId: widget.chatId,
        userId: _foundUser!.uid,
      );

      // Call the callback
      widget.onContactAdded();
      
      // Navigate back and show success
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${_foundUser!.displayName} added to the chat!',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error adding member: $e',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==================== HELPER METHODS ====================

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}