import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config/firebase_config.dart';
import 'ui/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/auth/signup_screen.dart';
import 'ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (.env file)
  try {
    await dotenv.load();
    print('✅ .env file loaded successfully');
  } catch (e) {
    print('⚠️ Warning: Could not load .env file: $e');
    print('💡 Make sure .env exists in project root with GROQ_API_KEY');
  }

  // Initialize Firebase with platform-specific options
  try {
    await FirebaseConfig.initialize();
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
    rethrow;
  }

  runApp(const ProviderScope(child: ThreadFlowApp()));
}

/// Main app widget with theme and routing
class ThreadFlowApp extends ConsumerWidget {
  const ThreadFlowApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth state - automatically rebuilds when auth changes
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'ThreadFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      
      // Home screen that responds to auth state
      home: authState.when(
        // User is logged in
        data: (user) {
          if (user != null) {
            return const HomeScreen();
          } else {
            // User not logged in - show login
            return const LoginScreen();
          }
        },
        
        // Still checking auth state
        loading: () => const _LoadingScreen(),
        
        // Error during auth check
        error: (error, stackTrace) {
          print('❌ Auth state error: $error');
          return _ErrorScreen(error: error.toString());
        },
      ),
      
      // Named routes for navigation
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomeScreen(),
      },
      
      // Handle unknown routes
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: const Center(child: Text('404 - Page not found')),
          ),
        );
      },
    );
  }
}

/// Loading screen shown while checking authentication state
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.chat_outlined,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            
            // Loading spinner
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            
            // App name
            Text(
              'ThreadFlow',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Status text
            Text(
              'Initializing...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Error screen shown if authentication fails
class _ErrorScreen extends StatelessWidget {
  final String error;

  const _ErrorScreen({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            
            // Error title
            Text(
              'Initialization Error',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            
            // Error message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            
            // Help text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Troubleshooting:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Check Firebase options in lib/config/firebase_options.dart\n'
                      '2. Verify .env file has GROQ_API_KEY\n'
                      '3. Check internet connection\n'
                      '4. Run: flutter clean && flutter pub get',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}