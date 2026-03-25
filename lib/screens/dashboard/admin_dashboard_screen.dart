import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_client.dart';
import 'package:fl_chart/fl_chart.dart';
import 'branch_management_view.dart';
import 'node_management_view.dart';
import 'ai_insights_view.dart';
import 'account_management_view.dart';
import 'system_management_view.dart';
import 'financials_view.dart';
import 'manager_settings_view.dart';
import 'profile_settings_view.dart';
// import 'kyc_review_view.dart'; // Preserve for Control App refactor

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  String _adminName = 'Admin';
  int _merchantLevel = 1;
  String _branchId = '';
  
  bool _isLoading = true;
  Map<String, dynamic> _stats = {
    "revenue": 0.0,
    "volume": 0,
    "active_tills": 0,
    "trends": []
  };
  List<dynamic> _recentTransactions = [];

  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _fetchStats();
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _adminName = prefs.getString('full_name') ?? 'Admin';
      _merchantLevel = prefs.getInt('merchant_level') ?? 1;
      _branchId = prefs.getString('managed_branch_id') ?? '';
    });
    
    await _fetchStats();
    setState(() { _isLoading = false; });
  }

  Future<void> _fetchStats() async {
    final res = await ApiClient.get('/merchant/stats', requireAuth: true);
    if (res['success'] == true) {
      if (mounted) {
        setState(() {
          _stats = res['data'];
        });
      }
    }
    // Fetch recent transactions for overview
    final txRes = await ApiClient.get(
      '/transactions/history?per_page=5',
      requireAuth: true,
    );
    if (txRes['success'] == true && mounted) {
      setState(() {
        _recentTransactions = txRes['data']?['transactions'] ?? [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(),
          const VerticalDivider(thickness: 1, width: 1, color: Colors.white12),
          // Main Content
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Container(
                    color: const Color(0xFF0F172A),
                    child: _buildBody(),
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return NavigationRail(
      selectedIndex: _selectedIndex > 5 ? 0 : _selectedIndex, // Logic to handle hidden indices if needed
      onDestinationSelected: (int index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      backgroundColor: const Color(0xFF1E293B),
      labelType: NavigationRailLabelType.all,
      unselectedLabelTextStyle: const TextStyle(color: Colors.white38),
      selectedLabelTextStyle: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
      leading: const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Icon(Icons.rocket_launch, color: Colors.blueAccent, size: 40),
      ),
      destinations: [
        const NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Overview'),
        ),
        if (_merchantLevel == 1)
          const NavigationRailDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business),
            label: Text('Branches'),
          ),
        const NavigationRailDestination(
          icon: Icon(Icons.terminal_outlined),
          selectedIcon: Icon(Icons.terminal),
          label: Text('Till Nodes'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.auto_graph_outlined),
          selectedIcon: Icon(Icons.auto_graph),
          label: Text('AI Insights'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: Text('Financials'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.settings_suggest_outlined),
          selectedIcon: Icon(Icons.settings_suggest),
          label: Text('System'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.manage_accounts_outlined),
          selectedIcon: Icon(Icons.manage_accounts),
          label: Text('Settings'),
        ),
      ],
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String title = 'Overview Dashboard';
    final items = [
      'Overview', 
      _merchantLevel == 1 ? 'Branch Management' : 'Till Nodes',
      _merchantLevel == 1 ? 'Till Node Management' : 'AI Business Insights',
      _merchantLevel == 1 ? 'AI Business Insights' : 'Financial Management',
      _merchantLevel == 1 ? 'Financial Management' : 'System Rules',
      _merchantLevel == 1 ? 'System Rules' : 'Settings',
    ];
    
    // Dynamic naming based on role-filtered list
    title = items[_selectedIndex];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Welcome back, $_adminName", style: const TextStyle(fontSize: 14, color: Colors.blueAccent)),
              Text(
                title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Spacer(),
          _buildHeaderAction(Icons.notifications_none),
          const SizedBox(width: 16),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _merchantLevel == 1
                  ? Colors.blueAccent.withValues(alpha: 0.15)
                  : Colors.amberAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _merchantLevel == 1
                    ? Colors.blueAccent.withValues(alpha: 0.5)
                    : Colors.amberAccent.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              _merchantLevel == 1 ? 'ADMIN' : 'MANAGER',
              style: TextStyle(
                color: _merchantLevel == 1 ? Colors.blueAccent : Colors.amberAccent,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: Colors.blueAccent.withOpacity(0.2),
            child: Text(_adminName[0].toUpperCase(), style: const TextStyle(color: Colors.blueAccent)),
          ),
          const SizedBox(width: 12),
          Text(_adminName, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildHeaderAction(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
      child: Icon(icon, size: 20, color: Colors.white70),
    );
  }

  Widget _buildBody() {
    if (_selectedIndex == 0) return _buildOverview();

    if (_merchantLevel == 1) {
      switch (_selectedIndex) {
        case 1: return const BranchManagementView();
        case 2: return const NodeManagementView();
        case 3: return const AiInsightsView();
        case 4: return const FinancialsView();
        case 5: return const SystemManagementView();
        case 6: return const ProfileSettingsView();
      }
    } else {
      // Level 2 (Manager)
      switch (_selectedIndex) {
        case 1: return NodeManagementView(branchId: _branchId);
        case 2: return const AiInsightsView();
        case 3: return const FinancialsView();
        case 4: return const SystemManagementView();
        case 5: return const ProfileSettingsView();
      }
    }

    return const Center(child: Text("Select an option from the sidebar", style: TextStyle(color: Colors.white38)));
  }

  Widget _buildOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatCard("Account Balance", "K${_stats['wallet_balance'] ?? 0.0}", Icons.account_balance_wallet, Colors.greenAccent),
              const SizedBox(width: 24),
              _buildStatCard("Total Revenue", "K${_stats['revenue']}", Icons.trending_up, Colors.blueAccent),
              const SizedBox(width: 24),
              _buildStatCard("Tx Volume", "${_stats['volume']}", Icons.swap_horiz, Colors.purpleAccent),
            ],
          ),
          const SizedBox(height: 48),
          const Text("Live Transaction Volume", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text("Historical trends for the last 7 days", style: TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 24),
          _buildChart(),
          const SizedBox(height: 48),
          // Recent transactions
          Row(
            children: [
              const Text("Recent Transactions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                    SizedBox(width: 6),
                    Text('LIVE', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecentTransactions(),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final trends = _stats['trends'] as List;
    if (trends.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(16)),
        child: const Center(child: Text("No transaction data available yet", style: TextStyle(color: Colors.white24))),
      );
    }
    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(trends.length, (i) => FlSpot(i.toDouble(), trends[i]['amount'].toDouble())),
              isCurved: true,
              color: Colors.blueAccent,
              barWidth: 4,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: Colors.blueAccent.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    if (_recentTransactions.isEmpty) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('No recent transactions', style: TextStyle(color: Colors.white24)),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF243044),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('Reference', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('From', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Amount', textAlign: TextAlign.right, style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Date', textAlign: TextAlign.right, style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          ..._recentTransactions.map((tx) {
            final isCredit = tx['direction'] == 'CREDIT';
            final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
            String dateStr = '';
            if (tx['date'] != null) {
              final dt = DateTime.tryParse(tx['date'])?.toLocal();
              if (dt != null) dateStr = '${dt.day}/${dt.month}/${dt.year}';
            }
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white10))),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text(tx['reference'] ?? 'N/A', style: const TextStyle(color: Colors.white60, fontSize: 13), overflow: TextOverflow.ellipsis)),
                  Expanded(flex: 2, child: Text(tx['sender_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${isCredit ? '+' : '-'}K${amount.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold, color: isCredit ? Colors.greenAccent : Colors.white70, fontSize: 13),
                    ),
                  ),
                  Expanded(flex: 1, child: Text(dateStr, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white38, fontSize: 12))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }


  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white60, fontSize: 14)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text("Rocket Enterprise", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(4)), child: const Text("OFFICIAL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
              const Spacer(),
              _buildFooterLink("Privacy Policy"),
              const SizedBox(width: 24),
              _buildFooterLink("Terms of Service"),
              const SizedBox(width: 24),
              _buildFooterLink("Support Center"),
              const SizedBox(width: 24),
              _buildFooterLink("Developer API"),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text("© 2026 KTS Technologies Ltd. Licensed by Bank of Zambia.", style: TextStyle(color: Colors.white38, fontSize: 12)),
              const Spacer(),
              const Text("Powered by", style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(width: 12),
              _buildSponsorIcon(Icons.security, "NFS"),
              const SizedBox(width: 12),
              _buildSponsorIcon(Icons.account_balance, "BOZ"),
              const SizedBox(width: 12),
              _buildSponsorIcon(Icons.bolt, "Gemini AI"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String label) {
    return Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13));
  }

  Widget _buildSponsorIcon(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white24),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
