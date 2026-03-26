import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_client.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiClient.post('/auth/login', {
      'identifier': _phoneController.text.trim(),
      'password': _passwordController.text,
    });

    setState(() {
      _isLoading = false;
    });

    if (res['success'] == true) {
      final data = res['data'];
      final user = data['user'];

      // ── Access Validation ──────────────────────────────────────────────────
      final bool isAuthorized = user['is_enterprise_authorized'] == true;
      final int level = int.tryParse(user['merchant_level']?.toString() ?? '0') ?? 0;
      final String category = user['category']?.toString() ?? 'USER';
      final String profileId = user['merchant_profile_id']?.toString() ?? '';
      final String branchId = user['managed_branch_id']?.toString() ?? '';
      
      debugPrint('[AUTH] Login Attempt: Category=$category, Level=$level, Auth=$isAuthorized');

      // Permanent Resilient Logic:
      // 1. Check if backend explicitly authorized enterprise access
      // 2. Fallback: Check if user has merchant level >= 1
      // 3. Fallback: Check if user is linked to a profile or branch
      bool hasAccess = isAuthorized || (level >= 1) || (profileId.isNotEmpty || branchId.isNotEmpty);

      if (!hasAccess) {
        setState(() {
          _errorMessage =
              'Access Denied: You do not have Enterprise Portal privileges. (Role: $category, Lvl: $level)';
        });
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access_token'].toString());
      await prefs.setString('refresh_token', data['refresh_token'].toString());

      await prefs.setString('user_id', user['id'].toString());
      await prefs.setString('full_name', user['full_name'].toString());
      await prefs.setInt('merchant_level', user['merchant_level'] as int);
      await prefs.setString(
          'merchant_profile_id', user['merchant_profile_id']?.toString() ?? '');
      await prefs.setString(
          'managed_branch_id', user['managed_branch_id']?.toString() ?? '');

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else {
      setState(() {
        _errorMessage = res['message']?.toString() ?? 'Login failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.rocket_launch,
                  size: 64,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Rocket Enterprise',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Management Portal v3.0.1 ALPHA',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 48),

                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade400),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),

                TextField(
                  controller: _phoneController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Admin Phone Number',
                    labelStyle: const TextStyle(color: Colors.blueGrey),
                    prefixIcon: const Icon(Icons.phone, color: Colors.blueGrey),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blueAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Colors.blueGrey),
                    prefixIcon: const Icon(Icons.lock, color: Colors.blueGrey),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blueAccent),
                    ),
                  ),
                  onSubmitted: (_) => _handleLogin(),
                ),
                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text(
                          'Secure Login',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an Enterprise account?",
                      style: TextStyle(color: Colors.white70),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/register');
                      },
                      child: const Text(
                        'Register Business',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
