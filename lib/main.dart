import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/audit/audit_manager.dart';
import 'core/network/network_aware_wrapper.dart';
import 'core/services/notification_service.dart';

import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';

import 'features/dashboard/presentation/screens/main_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // Initialize local notifications & FCM push service
  await NotificationService.initialize();

  // Initialize Audit Framework
  await AuditManager.initialize();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Stock Management',
      debugShowCheckedModeBanner: false,

      home: const AuthStartupScreen(),

      routes: {
        '/login': (context) => const LoginScreen(),
      },

      navigatorObservers: [
        AuditManager.navigatorObserver,
      ],

      builder: (context, child) {
        return NetworkAwareWrapper(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

// ============================================================
// AUTH STARTUP SCREEN
// ============================================================

class AuthStartupScreen extends ConsumerStatefulWidget {
  const AuthStartupScreen({super.key});

  @override
  ConsumerState<AuthStartupScreen> createState() =>
      _AuthStartupScreenState();
}

class _AuthStartupScreenState
    extends ConsumerState<AuthStartupScreen> {

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreSession();
    });
  }

  Future<void> _restoreSession() async {
    final authController =
        ref.read(authControllerProvider.notifier);

    final restored =
        await authController.restoreSession();

    if (!mounted) return;

    if (restored) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              const MainNavigationScreen(),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}