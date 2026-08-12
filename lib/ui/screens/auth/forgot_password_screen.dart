// // lib/ui/screens/auth/forgot_password_screen.dart
// import 'package:flutter/material.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';
// import 'package:flutter_hooks/flutter_hooks.dart';
// import 'reset_password_screen.dart';

// class ForgotPasswordScreen extends HookConsumerWidget {
//   const ForgotPasswordScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final emailController = useTextEditingController();

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Forgot Password'),
//         elevation: 1,
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Container(
//                 width: 80,
//                 height: 80,
//                 margin: const EdgeInsets.only(bottom: 24),
//                 decoration: BoxDecoration(
//                   color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: Icon(
//                   Icons.lock_reset_outlined,
//                   size: 40,
//                   color: Theme.of(context).colorScheme.primary,
//                 ),
//               ),
//               Text(
//                 'Forgot Password',
//                 style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                       fontWeight: FontWeight.bold,
//                     ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Enter your email to receive a password reset link',
//                 style: Theme.of(context).textTheme.bodyMedium,
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 32),
//               TextField(
//                 controller: emailController,
//                 decoration: const InputDecoration(
//                   labelText: 'Email',
//                   prefixIcon: Icon(Icons.email_outlined),
//                   hintText: 'you@example.com',
//                 ),
//                 keyboardType: TextInputType.emailAddress,
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () {
//                   final email = emailController.text.trim();
//                   if (email.isEmpty) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('Please enter your email')),
//                     );
//                     return;
//                   }
//                   Navigator.of(context).push(
//                     MaterialPageRoute(
//                       builder: (context) => ResetPasswordScreen(email: email),
//                     ),
//                   );
//                 },
//                 child: const Text('Continue'),
//               ),
//               const SizedBox(height: 16),
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
// }