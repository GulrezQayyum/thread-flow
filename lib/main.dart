// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config/firebase_config.dart';
import 'ui/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/auth/signup_screen.dart';
import 'ui/screens/auth/direct_reset_password_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/profile_screen.dart';
import 'ui/screens/settings_screen.dart'; // This imports themeModeProvider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load();
    print('✅ .env file loaded successfully');
  } catch (e) {
    print('⚠️ Warning: Could not load .env file: $e');
  }

  try {
    await FirebaseConfig.initialize();
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
    rethrow;
  }

  runApp(const ProviderScope(child: ThreadFlowApp()));
}

class ThreadFlowApp extends ConsumerStatefulWidget {
  const ThreadFlowApp({super.key});

  @override
  ConsumerState<ThreadFlowApp> createState() => _ThreadFlowAppState();
}

class _ThreadFlowAppState extends ConsumerState<ThreadFlowApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final currentUser = authState.user;
    
    // Watch theme mode from settings
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'ThreadFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      home: _showSplash
          ? const SplashScreen()
          : currentUser != null
              ? const HomeScreen()
              : const LoginScreen(),
      
     routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomeScreen(),
        '/reset-password': (context) => const DirectResetPasswordScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      
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