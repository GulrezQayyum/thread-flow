// // lib/ui/screens/auth/reset_password_screen.dart
// import 'package:flutter/material.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';
// import 'package:flutter_hooks/flutter_hooks.dart';
// import '../../../providers/auth_provider.dart';

// class ResetPasswordScreen extends HookConsumerWidget {
//   final String email;

//   const ResetPasswordScreen({Key? key, required this.email}) : super(key: key);

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final emailController = useTextEditingController(text: email);
//     final newPasswordController = useTextEditingController();
//     final confirmPasswordController = useTextEditingController();
//     final isLoading = useState(false);
//     final isPasswordReset = useState(false);
//     final errorMessage = useState<String?>(null);
//     final showNewPassword = useState(false);
//     final showConfirmPassword = useState(false);

//     return Scaffold(
//       appBar: AppBar(title: const Text('Reset Password'), elevation: 1),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 // Icon
//                 Container(
//                   width: 80,
//                   height: 80,
//                   margin: const EdgeInsets.only(bottom: 24),
//                   decoration: BoxDecoration(
//                     color: isPasswordReset.value
//                         ? Colors.green.withOpacity(0.1)
//                         : Theme.of(
//                             context,
//                           ).colorScheme.primary.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Icon(
//                     isPasswordReset.value
//                         ? Icons.check_circle
//                         : Icons.lock_reset_outlined,
//                     size: 40,
//                     color: isPasswordReset.value
//                         ? Colors.green
//                         : Theme.of(context).colorScheme.primary,
//                   ),
//                 ),

//                 // Title
//                 Text(
//                   isPasswordReset.value ? 'Password Reset!' : 'Reset Password',
//                   style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   isPasswordReset.value
//                       ? 'Your password has been changed successfully'
//                       : 'Enter your email and new password',
//                   style: Theme.of(context).textTheme.bodyMedium,
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 32),

//                 // Success Message
//                 if (isPasswordReset.value)
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: Colors.green.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: Colors.green),
//                     ),
//                     child: Column(
//                       children: [
//                         const Icon(
//                           Icons.check_circle,
//                           color: Colors.green,
//                           size: 48,
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           'Password updated successfully!',
//                           style: TextStyle(
//                             color: Colors.green[700],
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//                         ElevatedButton(
//                           onPressed: () {
//                             Navigator.of(
//                               context,
//                             ).pushReplacementNamed('/login');
//                           },
//                           child: const Text('Go to Login'),
//                         ),
//                       ],
//                     ),
//                   ),

//                 // Form fields
//                 if (!isPasswordReset.value) ...[
//                   // Email Field
//                   TextField(
//                     controller: emailController,
//                     decoration: const InputDecoration(
//                       labelText: 'Email',
//                       prefixIcon: Icon(Icons.email_outlined),
//                       hintText: 'you@example.com',
//                     ),
//                     keyboardType: TextInputType.emailAddress,
//                     enabled: !isLoading.value,
//                   ),
//                   const SizedBox(height: 16),

//                   // New Password Field
//                   TextField(
//                     controller: newPasswordController,
//                     decoration: InputDecoration(
//                       labelText: 'New Password',
//                       prefixIcon: const Icon(Icons.lock_outline),
//                       hintText: 'Enter new password (min 6 chars)',
//                       suffixIcon: IconButton(
//                         icon: Icon(
//                           showNewPassword.value
//                               ? Icons.visibility
//                               : Icons.visibility_off,
//                         ),
//                         onPressed: () =>
//                             showNewPassword.value = !showNewPassword.value,
//                       ),
//                     ),
//                     obscureText: !showNewPassword.value,
//                     enabled: !isLoading.value,
//                   ),
//                   const SizedBox(height: 16),

//                   // Confirm Password Field
//                   TextField(
//                     controller: confirmPasswordController,
//                     decoration: InputDecoration(
//                       labelText: 'Confirm Password',
//                       prefixIcon: const Icon(Icons.lock_outline),
//                       hintText: 'Confirm your new password',
//                       suffixIcon: IconButton(
//                         icon: Icon(
//                           showConfirmPassword.value
//                               ? Icons.visibility
//                               : Icons.visibility_off,
//                         ),
//                         onPressed: () => showConfirmPassword.value =
//                             !showConfirmPassword.value,
//                       ),
//                     ),
//                     obscureText: !showConfirmPassword.value,
//                     enabled: !isLoading.value,
//                   ),
//                   const SizedBox(height: 16),
//                 ],

//                 // Error Message
//                 if (errorMessage.value != null)
//                   Container(
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: Theme.of(
//                         context,
//                       ).colorScheme.error.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(
//                         color: Theme.of(context).colorScheme.error,
//                       ),
//                     ),
//                     child: Text(
//                       errorMessage.value!,
//                       style: TextStyle(
//                         color: Theme.of(context).colorScheme.error,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ),
//                 if (errorMessage.value != null) const SizedBox(height: 16),

//                 // Reset Button
//                 if (!isPasswordReset.value)
//                   ElevatedButton(
//                     onPressed: isLoading.value
//                         ? null
//                         : () async {
//                             errorMessage.value = null;

//                             final emailAddr = emailController.text.trim();
//                             final newPassword = newPasswordController.text
//                                 .trim();
//                             final confirmPassword = confirmPasswordController
//                                 .text
//                                 .trim();

//                             if (emailAddr.isEmpty) {
//                               errorMessage.value =
//                                   'Please enter your email address';
//                               return;
//                             }

//                             if (!_isValidEmail(emailAddr)) {
//                               errorMessage.value =
//                                   'Please enter a valid email address';
//                               return;
//                             }

//                             if (newPassword.isEmpty) {
//                               errorMessage.value =
//                                   'Please enter a new password';
//                               return;
//                             }

//                             if (newPassword.length < 6) {
//                               errorMessage.value =
//                                   'Password must be at least 6 characters';
//                               return;
//                             }

//                             if (newPassword != confirmPassword) {
//                               errorMessage.value = 'Passwords do not match';
//                               return;
//                             }

//                             isLoading.value = true;
//                             try {
//                               final authController = ref.read(
//                                 authControllerProvider.notifier,
//                               );
//                               await authController.sendPasswordResetEmail(
//                                 email: emailAddr,
//                               );

//                               if (context.mounted) {
//                                 isPasswordReset.value = true;
//                                 isLoading.value = false;
//                               }
//                             } catch (e) {
//                               if (context.mounted) {
//                                 errorMessage.value = e.toString().replaceFirst(
//                                   'Exception: ',
//                                   '',
//                                 );
//                                 isLoading.value = false;
//                               }
//                             }
//                           },
//                     child: isLoading.value
//                         ? const SizedBox(
//                             width: 20,
//                             height: 20,
//                             child: CircularProgressIndicator(strokeWidth: 2),
//                           )
//                         : const Text('Reset Password'),
//                   ),

//                 const SizedBox(height: 16),

//                 // Back to Login
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       'Remember your password? ',
//                       style: Theme.of(context).textTheme.bodyMedium,
//                     ),
//                     TextButton(
//                       onPressed: () {
//                         Navigator.of(context).pushReplacementNamed('/login');
//                       },
//                       child: const Text('Back to Sign In'),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   bool _isValidEmail(String email) {
//     return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
//   }
// }
