// // lib/ui/screens/auth/reset_password_screen.dart
// import 'package:flutter/material.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';
// import 'package:flutter_hooks/flutter_hooks.dart';
// import '../../../providers/auth_provider.dart';

// class ResetPasswordScreen extends HookConsumerWidget {
//   final String email;

//   const ResetPasswordScreen({
//     Key? key,
//     required this.email,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final emailController = useTextEditingController(text: email);
//     final isLoading = useState(false);
//     final isEmailSent = useState(false);
//     final errorMessage = useState<String?>(null);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Reset Password'),
//         elevation: 1,
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // Icon
//               Container(
//                 width: 80,
//                 height: 80,
//                 margin: const EdgeInsets.only(bottom: 24),
//                 decoration: BoxDecoration(
//                   color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: Icon(
//                   isEmailSent.value ? Icons.check_circle : Icons.lock_reset_outlined,
//                   size: 40,
//                   color: isEmailSent.value 
//                       ? Colors.green 
//                       : Theme.of(context).colorScheme.primary,
//                 ),
//               ),
              
//               // Title
//               Text(
//                 isEmailSent.value ? 'Check Your Email' : 'Reset Password',
//                 style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                       fontWeight: FontWeight.bold,
//                     ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 isEmailSent.value 
//                     ? 'We\'ve sent a password reset link to your email'
//                     : 'Enter your email address and we\'ll send you a link to reset your password.',
//                 style: Theme.of(context).textTheme.bodyMedium,
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 32),

//               // Success Message
//               if (isEmailSent.value)
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.green.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.green),
//                   ),
//                   child: Column(
//                     children: [
//                       const Icon(
//                         Icons.check_circle,
//                         color: Colors.green,
//                         size: 48,
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Password reset link sent!',
//                         style: TextStyle(
//                           color: Colors.green[700],
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Please check your email inbox and follow the instructions.',
//                         style: TextStyle(
//                           color: Colors.green[600],
//                           fontSize: 14,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                       const SizedBox(height: 8),
//                       TextButton(
//                         onPressed: () {
//                           // Open email app (optional)
//                         },
//                         child: const Text('Open Email App'),
//                       ),
//                     ],
//                   ),
//                 ),
              
//               if (!isEmailSent.value) ...[
//                 const SizedBox(height: 16),
//                 TextField(
//                   controller: emailController,
//                   decoration: const InputDecoration(
//                     labelText: 'Email',
//                     prefixIcon: Icon(Icons.email_outlined),
//                     hintText: 'you@example.com',
//                   ),
//                   keyboardType: TextInputType.emailAddress,
//                   enabled: !isLoading.value,
//                 ),
//                 const SizedBox(height: 16),
//               ],

//               // Error Message
//               if (errorMessage.value != null)
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Theme.of(context).colorScheme.error.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(
//                       color: Theme.of(context).colorScheme.error,
//                     ),
//                   ),
//                   child: Text(
//                     errorMessage.value!,
//                     style: TextStyle(
//                       color: Theme.of(context).colorScheme.error,
//                       fontSize: 14,
//                     ),
//                   ),
//                 ),
              
//               if (errorMessage.value != null) const SizedBox(height: 16),

//               // Send Reset Email Button
//               if (!isEmailSent.value)
//                 ElevatedButton(
//                   onPressed: isLoading.value
//                       ? null
//                       : () async {
//                           errorMessage.value = null;
//                           final emailAddr = emailController.text.trim();
                          
//                           if (emailAddr.isEmpty) {
//                             errorMessage.value = 'Please enter your email address';
//                             return;
//                           }
                          
//                           if (!_isValidEmail(emailAddr)) {
//                             errorMessage.value = 'Please enter a valid email address';
//                             return;
//                           }

//                           isLoading.value = true;
//                           try {
//                             final authController = ref.read(authControllerProvider.notifier);
//                             await authController.sendPasswordResetEmail(email: emailAddr);
                            
//                             if (context.mounted) {
//                               isEmailSent.value = true;
//                               isLoading.value = false;
//                             }
//                           } catch (e) {
//                             if (context.mounted) {
//                               errorMessage.value = e.toString().replaceFirst('Exception: ', '');
//                               isLoading.value = false;
//                             }
//                           }
//                         },
//                   child: isLoading.value
//                       ? const SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(strokeWidth: 2),
//                         )
//                       : const Text('Send Reset Link'),
//                 ),

//               const SizedBox(height: 16),

//               // Resend Email (if sent)
//               if (isEmailSent.value)
//                 TextButton(
//                   onPressed: () async {
//                     isEmailSent.value = false;
//                     emailController.clear();
//                   },
//                   child: const Text('Resend Email'),
//                 ),

//               // Back to Login
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     'Remember your password? ',
//                     style: Theme.of(context).textTheme.bodyMedium,
//                   ),
//                   TextButton(
//                     onPressed: () {
//                       Navigator.of(context).pushReplacementNamed('/login');
//                     },
//                     child: const Text('Back to Sign In'),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   bool _isValidEmail(String email) {
//     return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
//   }
// }