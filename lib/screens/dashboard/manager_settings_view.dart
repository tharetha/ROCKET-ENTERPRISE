import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Limited settings view for Level 2 Branch Managers.
/// Only shows profile info and password change — no system rules.
class ManagerSettingsView extends StatefulWidget {
  const ManagerSettingsView({super.key});

  @override
  State<ManagerSettingsView> createState() => _ManagerSettingsViewState();
}

class _ManagerSettingsViewState extends State<ManagerSettingsView> {
  String _name = '';
  String _branchId = '';
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  bool _pwLoading = false;
  String? _pwError;
  String? _pwSuccess;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('full_name') ?? 'Manager';
      _branchId = prefs.getString('managed_branch_id') ?? 'N/A';
    });
  }

  Future<void> _changePassword() async {
    setState(() {
      _pwError = null;
      _pwSuccess = null;
    });
    if (_newPwCtrl.text.isEmpty || _confirmPwCtrl.text.isEmpty) {
      setState(() => _pwError = 'All fields are required.');
      return;
    }
    if (_newPwCtrl.text != _confirmPwCtrl.text) {
      setState(() => _pwError = 'New passwords do not match.');
      return;
    }
    if (_newPwCtrl.text.length < 8) {
      setState(() => _pwError = 'Password must be at least 8 characters.');
      return;
    }
    setState(() => _pwLoading = true);
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _pwLoading = false;
      _pwSuccess = 'Password updated successfully.';
      _currentPwCtrl.clear();
      _newPwCtrl.clear();
      _confirmPwCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Account',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Manage your profile and security settings',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 36),

          // ── Profile Card ─────────────────────────────────────────────────
          _sectionHeader('Profile'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.amberAccent.withValues(alpha: 0.15),
                  child: Text(
                    _name.isNotEmpty ? _name[0].toUpperCase() : 'M',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.amberAccent,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amberAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.amberAccent.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Text(
                              'BRANCH MANAGER',
                              style: TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Branch: $_branchId',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          // ── Change Password ──────────────────────────────────────────────
          _sectionHeader('Change Password'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_pwError != null)
                  _infoBox(_pwError!, Colors.redAccent),
                if (_pwSuccess != null)
                  _infoBox(_pwSuccess!, Colors.greenAccent),
                _pwField('Current Password', _currentPwCtrl),
                const SizedBox(height: 12),
                _pwField('New Password', _newPwCtrl),
                const SizedBox(height: 12),
                _pwField('Confirm New Password', _confirmPwCtrl),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _pwLoading ? null : _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _pwLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Update Password',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          // ── Access Level Note ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.amberAccent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.amberAccent.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline, color: Colors.amberAccent, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'As a Branch Manager, you can manage nodes and view financials for your branch. System-level settings and settlement rules are managed by Level 1 Admin.',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      );

  Widget _pwField(String label, TextEditingController ctrl) => TextField(
        controller: ctrl,
        obscureText: true,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: const Color(0xFF0F172A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.blueAccent),
          ),
        ),
      );

  Widget _infoBox(String text, Color color) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(text, style: TextStyle(color: color, fontSize: 13)),
      );
}
