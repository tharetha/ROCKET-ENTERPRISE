import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_client.dart';

class AdminRegisterScreen extends StatefulWidget {
  const AdminRegisterScreen({super.key});

  @override
  State<AdminRegisterScreen> createState() => _AdminRegisterScreenState();
}

class _AdminRegisterScreenState extends State<AdminRegisterScreen> {
  final _businessNameController = TextEditingController();
  final _regNoController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isVerifyingPacra = false;
  bool _pacraVerified = false;
  Map<String, String>? _pacraResult;
  String? _errorMessage;

  // ── PACRA Simulation ───────────────────────────────────────────────────────

  /// Simulated PACRA lookup — in production, replace with external PACRA API call.
  Future<void> _verifyWithPacra() async {
    final regNo = _regNoController.text.trim();
    if (regNo.isEmpty) {
      setState(() => _errorMessage = 'Please enter a registration number first.');
      return;
    }
    setState(() {
      _isVerifyingPacra = true;
      _errorMessage = null;
      _pacraVerified = false;
    });

    // Simulate network delay (2s)
    await Future.delayed(const Duration(seconds: 2));

    // Simulate result based on regNo format (any non-empty value passes)
    final simulatedCompany = _businessNameController.text.trim().isNotEmpty
        ? _businessNameController.text.trim()
        : 'Company ${regNo.toUpperCase()}';

    if (mounted) {
      setState(() {
        _isVerifyingPacra = false;
        _pacraVerified = true;
        _pacraResult = {
          'company': simulatedCompany,
          'reg_no': regNo,
          'status': 'ACTIVE',
          'type': 'Private Limited Company',
          'registered': '2024-01-15',
        };
        // Auto-fill business name if empty
        if (_businessNameController.text.isEmpty) {
          _businessNameController.text = simulatedCompany;
        }
      });
    }
  }

  // ── Registration ───────────────────────────────────────────────────────────

  Future<void> _handleRegister() async {
    if (!_pacraVerified) {
      setState(() => _errorMessage = 'Please verify your PACRA registration number first.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiClient.post('/auth/register-merchant', {
      'business_name': _businessNameController.text.trim(),
      'registration_no': _regNoController.text.trim(),
      'business_email': _emailController.text.trim(),
      'full_name': _fullNameController.text.trim(),
      'phone_number': _phoneController.text.trim(),
      'password': _passwordController.text,
    });

    setState(() => _isLoading = false);

    if (res['success'] == true) {
      final data = res['data'];
      final user = data['user'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access_token'].toString());
      await prefs.setString('refresh_token', data['refresh_token'].toString());
      await prefs.setString('user_id', user['id'].toString());
      await prefs.setString('full_name', user['full_name'].toString());
      await prefs.setInt('merchant_level', 1);

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else {
      setState(
        () => _errorMessage = res['message']?.toString() ?? 'Registration failed',
      );
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        enabled: enabled,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.blueGrey),
          prefixIcon: Icon(icon, color: Colors.blueGrey),
          filled: true,
          fillColor: const Color(0xFF0F172A),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blueAccent),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 540),
            padding: const EdgeInsets.all(40),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const Icon(
                  Icons.business_center,
                  size: 60,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Register Your Enterprise',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Create a Level 1 HQ Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 28),

                // Error banner
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade400),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),

                // ── Business Details Section ─────────────────────────────
                _sectionLabel('Business Details'),
                const SizedBox(height: 12),

                _buildField(
                  controller: _businessNameController,
                  label: 'Business Name',
                  icon: Icons.store,
                ),

                // PACRA Registration Row
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _regNoController,
                              enabled: !_pacraVerified,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Company Reg No (PACRA)',
                                labelStyle:
                                    const TextStyle(color: Colors.blueGrey),
                                prefixIcon: const Icon(
                                  Icons.assignment,
                                  color: Colors.blueGrey,
                                ),
                                suffixIcon: _pacraVerified
                                    ? const Icon(
                                        Icons.verified,
                                        color: Colors.greenAccent,
                                      )
                                    : null,
                                filled: true,
                                fillColor: const Color(0xFF0F172A),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: Colors.transparent),
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.greenAccent,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: Colors.blueAccent),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed:
                                  (_isVerifyingPacra || _pacraVerified)
                                      ? null
                                      : _verifyWithPacra,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                disabledBackgroundColor: Colors.greenAccent
                                    .withValues(alpha: 0.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isVerifyingPacra
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _pacraVerified ? '✓ Verified' : 'Verify',
                                      style: TextStyle(
                                        color: _pacraVerified
                                            ? Colors.greenAccent
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),

                      // PACRA result chip
                      if (_pacraResult != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.greenAccent.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.verified_outlined,
                                      color: Colors.greenAccent,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'PACRA Registry — VERIFIED',
                                      style: TextStyle(
                                        color: Colors.greenAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _pacraRow('Company', _pacraResult!['company']!),
                                _pacraRow('Status', _pacraResult!['status']!),
                                _pacraRow('Type', _pacraResult!['type']!),
                                _pacraRow(
                                  'Registered',
                                  _pacraResult!['registered']!,
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Loading state text
                      if (_isVerifyingPacra)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Verifying with PACRA registry...',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                _buildField(
                  controller: _emailController,
                  label: 'Business Email',
                  icon: Icons.email,
                ),

                const Divider(color: Colors.white12, height: 32),
                _sectionLabel('Admin Account'),
                const SizedBox(height: 12),

                _buildField(
                  controller: _fullNameController,
                  label: 'Admin Full Name',
                  icon: Icons.person,
                ),
                _buildField(
                  controller: _phoneController,
                  label: 'Admin Phone Number',
                  icon: Icons.phone,
                ),
                _buildField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock,
                  isPassword: true,
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    disabledBackgroundColor: Colors.blueAccent.withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(vertical: 18),
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
                          'Create Account',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.blueAccent,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _pacraRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Text(
              '$label: ',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}
