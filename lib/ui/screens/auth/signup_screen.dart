import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../providers/auth_provider.dart';

class SignUpScreen extends HookConsumerWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Join ThreadFlow',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your account to start threading',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              // Display Name Field
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  prefixIcon: Icon(Icons.person_outlined),
                  hintText: 'John Doe',
                ),
                enabled: !isLoading.value,
              ),
              const SizedBox(height: 16),
              // Email Field
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  hintText: 'you@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !isLoading.value,
              ),
              const SizedBox(height: 16),
              // Password Field
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outlined),
                  hintText: 'At least 6 characters',
                ),
                obscureText: true,
                enabled: !isLoading.value,
              ),
              const SizedBox(height: 16),
              // Confirm Password Field
              TextField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outlined),
                  hintText: 'Confirm your password',
                ),
                obscureText: true,
                enabled: !isLoading.value,
              ),
              const SizedBox(height: 24),
              // Error Message
              if (errorMessage.value != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  child: Text(
                    errorMessage.value!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 14,
                    ),
                  ),
                ),
              if (errorMessage.value != null) const SizedBox(height: 16),
              // Sign Up Button
              ElevatedButton(
                onPressed: isLoading.value
                    ? null
                    : () async {
                        errorMessage.value = null;

                        // Validation
                        if (nameController.text.isEmpty) {
                          errorMessage.value = 'Please enter your name';
                          return;
                        }
                        if (emailController.text.isEmpty) {
                          errorMessage.value = 'Please enter your email';
                          return;
                        }
                        if (passwordController.text.length < 6) {
                          errorMessage.value =
                              'Password must be at least 6 characters';
                          return;
                        }
                        if (passwordController.text !=
                            confirmPasswordController.text) {
                          errorMessage.value = 'Passwords do not match';
                          return;
                        }

                        isLoading.value = true;
                        try {
                          // Trigger sign up via the new AuthController
                          await ref
                              .read(authControllerProvider.notifier)
                              .signUp(
                                email: emailController.text.trim(),
                                password: passwordController.text,
                                displayName: nameController.text.trim(),
                              );

                          if (context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/home',
                              (route) => false,
                            );
                          }
                        } catch (e) {
                          errorMessage.value = e.toString().replaceFirst(
                            'Exception: ',
                            '',
                          );
                        } finally {
                          isLoading.value = false;
                        }
                      },
                child: isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Account'),
              ),
              const SizedBox(height: 16),
              // Sign In Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
