import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class AccountManagementView extends StatefulWidget {
  const AccountManagementView({super.key});

  @override
  State<AccountManagementView> createState() => _AccountManagementViewState();
}

class _AccountManagementViewState extends State<AccountManagementView> {
  List<dynamic> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    final res = await ApiClient.get('/merchant/settings', requireAuth: true);
    if (res['success'] == true) {
      setState(() {
        _accounts = res['data']['bank_accounts'] ?? [];
        _isLoading = false;
      });
    }
  }

  Future<void> _addAccount() async {
    if (_accounts.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maximum of 2 bank accounts allowed for settlement.")),
      );
      return;
    }

    final bankController = TextEditingController();
    final accController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Add Settlement Bank"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: bankController, decoration: const InputDecoration(labelText: "Bank Name")),
            TextField(controller: accController, decoration: const InputDecoration(labelText: "Account Number")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (bankController.text.isNotEmpty && accController.text.isNotEmpty) {
      final newAccounts = List.from(_accounts)..add({
        "bank": bankController.text,
        "acc": accController.text
      });
      
      final res = await ApiClient.post('/merchant/settings', {"bank_accounts": newAccounts}, requireAuth: true);
      if (res['success'] == true) {
        _fetchSettings();
      }
    }
  }

  Future<void> _removeAccount(int index) async {
    final newAccounts = List.from(_accounts)..removeAt(index);
    final res = await ApiClient.post('/merchant/settings', {"bank_accounts": newAccounts}, requireAuth: true);
    if (res['success'] == true) {
      _fetchSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Financials & Bank Accounts", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  Text("Manage where your funds are settled", style: TextStyle(color: Colors.white60)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _accounts.length < 2 ? _addAccount : null,
                icon: const Icon(Icons.add),
                label: const Text("Add Bank Account"),
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (_accounts.isEmpty)
             const Center(child: Text("No bank accounts linked yet.", style: TextStyle(color: Colors.white30))),
          Expanded(
            child: ListView.builder(
              itemCount: _accounts.length,
              itemBuilder: (context, index) {
                final acc = _accounts[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        child: Icon(Icons.account_balance, color: Colors.white),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(acc['bank'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text("Account: ${acc['acc']}", style: const TextStyle(color: Colors.white60)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _removeAccount(index),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
             child: const Row(
               children: [
                 Icon(Icons.info_outline, color: Colors.blueAccent),
                 SizedBox(width: 12),
                 Text("Rocket initiates automated settlement every 24 hours to your default bank account.", style: TextStyle(fontSize: 12, color: Colors.white70)),
               ],
             ),
          ),
        ],
      ),
    );
  }
}
