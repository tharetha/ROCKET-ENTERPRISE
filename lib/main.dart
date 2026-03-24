import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'screens/auth/admin_login_screen.dart';
import 'screens/auth/admin_register_screen.dart';
import 'screens/dashboard/admin_dashboard_screen.dart';
import 'widgets/session_manager.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  bool hasValidSession = false;
  if (token != null && token.isNotEmpty) {
    if (!JwtDecoder.isExpired(token)) {
      hasValidSession = true;
    }
  }

  runApp(RocketEnterpriseApp(hasValidSession: hasValidSession));
}

class RocketEnterpriseApp extends StatelessWidget {
  final bool hasValidSession;

  const RocketEnterpriseApp({super.key, required this.hasValidSession});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rocket Enterprise',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          surface: Color(0xFF1E293B),
        ),
        fontFamily: 'Inter',
      ),
      initialRoute: hasValidSession ? '/dashboard' : '/login',
      routes: {
        '/login': (context) => const AdminLoginScreen(),
        '/register': (context) => const AdminRegisterScreen(),
        '/dashboard': (context) =>
            const SessionManager(child: AdminDashboardScreen()),
      },
    );
  }
}
