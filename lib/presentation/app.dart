import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/chat_page.dart';
import 'widgets/demo_debug_overlay.dart';
import '../data/repositories/trip_repository.dart';
import '../data/sources/agent_api.dart';

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: _AppContent(),
    );
  }
}

class _AppContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Create the repository instance for the entire app
    final repository = TripRepository(agentApi: AgentApi());

    return MaterialApp(
      title: 'Smart Trip Planner',
      theme: buildTheme(),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => DashboardPage(repo: repository),
        '/chat': (context) => ChatPage(repo: repository),
        '/home': (context) => DemoDebugOverlay(
              repository: repository,
              child: const HomePage(),
            ),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    setState(() {
      _isLoggedIn = isLoggedIn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isLoggedIn) {
      final repository = TripRepository(agentApi: AgentApi());
      return DashboardPage(repo: repository);
    } else {
      return const LoginPage();
    }
  }
}
