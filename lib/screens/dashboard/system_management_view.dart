import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../widgets/access_denied_widget.dart';

class SystemManagementView extends StatefulWidget {
  const SystemManagementView({super.key});

  @override
  State<SystemManagementView> createState() => _SystemManagementViewState();
}

class _SystemManagementViewState extends State<SystemManagementView> {
  String _settlementStrategy = 'CENTRALIZED';
  String _settlementTime = '18:00';
  bool _marketingSubscription = false;
  bool _autoReportEnabled = false;
  String _autoReportFrequency = 'MONTHLY';
  final TextEditingController _emailController = TextEditingController();
  
  bool _isLoading = true;
  bool _isPermissionDenied = false;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _fetchSettings() async {
    final res = await ApiClient.get('/merchant/settings', requireAuth: true);
    if (res['statusCode'] == 403) {
      setState(() {
        _isPermissionDenied = true;
        _isLoading = false;
      });
      return;
    }

    if (res['success'] == true) {
      final data = res['data'];
      setState(() {
        _settlementStrategy = data['settlement_strategy'] ?? 'CENTRALIZED';
        _settlementTime = data['settlement_time'] ?? '18:00';
        _marketingSubscription = data['marketing_subscription'] ?? false;
        _autoReportEnabled = data['auto_report_enabled'] ?? false;
        _autoReportFrequency = data['auto_report_frequency'] ?? 'MONTHLY';
        _emailController.text = data['auto_report_email'] ?? '';
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSettings(Map<String, dynamic> delta) async {
    final res = await ApiClient.post('/merchant/settings', delta, requireAuth: true);
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Settings saved successfully")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_isPermissionDenied) return const AccessDeniedWidget();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("System Control & Rules", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const Text("Configure profile-wide behavior, settlement, and growth tools", style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 48),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Settlement & Security
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("Settlement Strategy"),
                    const SizedBox(height: 16),
                    _buildStrategyOption(
                      "Centralized Settlement", 
                      "All funds from all branches pool into the HQ primary bank account.", 
                      "CENTRALIZED"
                    ),
                    const SizedBox(height: 12),
                    _buildStrategyOption(
                      "Branch Settlement (Decentralized)", 
                      "Each branch manages its own bank account for direct fund pooling.", 
                      "DECENTRALIZED"
                    ),
                    if (_settlementStrategy == 'DECENTRALIZED')
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: _buildSettlementTimePicker(),
                      ),
                    
                    const SizedBox(height: 48),
                    _buildSectionHeader("Bank Accounts"),
                    const SizedBox(height: 16),
                    _buildBankLinkingCard(),

                    const SizedBox(height: 48),
                    _buildSectionHeader("Security & Encryption"),
                    const SizedBox(height: 16),
                    _buildSecurityCard(),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Right Column: Marketing & Reports
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("Financial Automation"),
                    const SizedBox(height: 16),
                    _buildAutomationCard(),
                    
                    const SizedBox(height: 48),
                    _buildSectionHeader("Growth & Marketing"),
                    const SizedBox(height: 16),
                    _buildMarketingCard(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementTimePicker() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Daily Sweep Time", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("Time branches are swept to main account", style: TextStyle(color: Colors.white60, fontSize: 13)),
            ],
          ),
          DropdownButton<String>(
            value: _settlementTime,
            dropdownColor: const Color(0xFF0F172A),
            underline: const SizedBox(),
            items: const ['08:00', '12:00', '18:00', '22:00'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() => _settlementTime = newValue);
                _updateSettings({"settlement_time": newValue});
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBankLinkingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance, color: Colors.blueAccent),
              SizedBox(width: 12),
              Text("Linked Bank Accounts", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          const Text("Manage external bank accounts where your settlement funds will be deposited.", style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: null, // Disabled for "Coming Soon"
            icon: const Icon(Icons.add),
            label: const Text("Add Bank Account (Coming Soon)"),
            style: OutlinedButton.styleFrom(
              disabledForegroundColor: Colors.white30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent));
  }

  Widget _buildStrategyOption(String title, String subtitle, String value) {
    bool isSelected = _settlementStrategy == value;
    return InkWell(
      onTap: () {
        setState(() => _settlementStrategy = value);
        _updateSettings({"settlement_strategy": value});
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent.withOpacity(0.1) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.blueAccent : Colors.white10),
        ),
        child: Row(
          children: [
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? Colors.blueAccent : Colors.white30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.vpn_key, color: Colors.blueAccent),
              SizedBox(width: 12),
              Text("Profile Encryption Key", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          const Text("Your master encryption key used for terminal signing is managed on-server. You can rotate this key every 90 days.", style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () {}, 
            child: const Text("Rotate Master Key"),
          ),
        ],
      ),
    );
  }

  Widget _buildAutomationCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: const Text("Automated Reports", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text("Email monthly statements automatically", style: TextStyle(fontSize: 12, color: Colors.white60)),
            value: _autoReportEnabled,
            activeColor: Colors.blueAccent,
            onChanged: (val) {
              setState(() => _autoReportEnabled = val);
              _updateSettings({"auto_report_enabled": val});
            },
          ),
          if (_autoReportEnabled) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Finance Email",
                labelStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              style: const TextStyle(fontSize: 14),
              onSubmitted: (val) => _updateSettings({"auto_report_email": val}),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _autoReportFrequency,
              dropdownColor: const Color(0xFF1E293B),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              items: const [
                DropdownMenuItem(value: 'DAILY', child: Text("Daily Summary")),
                DropdownMenuItem(value: 'WEEKLY', child: Text("Weekly Statement")),
                DropdownMenuItem(value: 'MONTHLY', child: Text("Monthly Report")),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _autoReportFrequency = val);
                  _updateSettings({"auto_report_frequency": val});
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMarketingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purpleAccent.withOpacity(0.1), Colors.blueAccent.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rocket_launch, color: Colors.orangeAccent),
              const SizedBox(width: 12),
              const Text("Rocket Marketing", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              Switch(
                value: _marketingSubscription,
                activeColor: Colors.orangeAccent,
                onChanged: (val) {
                  setState(() => _marketingSubscription = val);
                  _updateSettings({"marketing_subscription": val});
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text("Promote your products directly on the Rocket Mobile App used by thousands of customers.", style: TextStyle(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 16),
          const Text("• Target local customers", style: TextStyle(fontSize: 12, color: Colors.white70)),
          const Text("• Featured in 'Deals Near You'", style: TextStyle(fontSize: 12, color: Colors.white70)),
          const Text("• Priority in Merchant Search", style: TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}
