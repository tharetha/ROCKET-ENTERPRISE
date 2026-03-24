import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../core/api_client.dart';
import '../screens/auth/admin_login_screen.dart';
import '../main.dart';

class SessionManager extends StatefulWidget {
  final Widget child;

  const SessionManager({super.key, required this.child});

  static Future<void> forceLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');

    final context = navigatorKey.currentContext;
    if (context == null) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      (route) => false,
    );
  }

  @override
  State<SessionManager> createState() => _SessionManagerState();
}

class _SessionManagerState extends State<SessionManager> {
  Timer? _sessionTimer;
  bool _isRefreshing = false;

  // Configuration
  static const int _silentRefreshSecondsBeforeExpiry =
      30; // 30s before token dies

  @override
  void initState() {
    super.initState();
    _startSessionTimer();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  void _startSessionTimer() {
    // Check session state every 5 seconds
    _sessionTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkSession();
    });
  }

  Future<void> _checkSession() async {
    if (_isRefreshing) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    // If no token exists, the user is not logged in.
    if (token == null) return;

    if (JwtDecoder.isExpired(token)) {
      // Token is already entirely dead. Log out locally.
      _forceLogout();
      return;
    }

    final DateTime expirationDate = JwtDecoder.getExpirationDate(token);
    final durationUntilExpiry = expirationDate.difference(DateTime.now());

    // SCENARIO 1: Token needs a refresh soon
    if (durationUntilExpiry.inSeconds <= _silentRefreshSecondsBeforeExpiry) {
      _silentRefresh();
    }
  }

  Future<void> _silentRefresh() async {
    _isRefreshing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null) {
        _forceLogout();
        return;
      }

      final res = await ApiClient.post(
        '/auth/refresh',
        {},
        customToken: refreshToken,
      );

      if (res['success'] == true && res['data']?['access_token'] != null) {
        await prefs.setString('access_token', res['data']['access_token']);
      } else {
        _forceLogout();
      }
    } catch (e) {
      debugPrint('Refresh Error: $e');
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _forceLogout() async {
    _sessionTimer?.cancel();
    await SessionManager.forceLogout();
  }

  @override
  Widget build(BuildContext context) {
    // No longer need to listen for interactions for inactivity timeouts
    return widget.child;
  }
}
