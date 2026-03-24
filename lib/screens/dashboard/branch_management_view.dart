import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class BranchManagementView extends StatefulWidget {
  const BranchManagementView({super.key});

  @override
  State<BranchManagementView> createState() => _BranchManagementViewState();
}

class _BranchManagementViewState extends State<BranchManagementView> {
  List<dynamic> _branches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBranches();
  }

  Future<void> _fetchBranches() async {
    setState(() => _isLoading = true);
    final res = await ApiClient.get('/merchant/branches', requireAuth: true);
    if (res['success'] == true) {
      setState(() {
        _branches = res['data'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to load branches')),
        );
      }
    }
  }

  void _showAddBranchDialog() {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final managerNameController = TextEditingController();
    final managerEmailController = TextEditingController();
    final managerPhoneController = TextEditingController();
    final managerPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Branch'),
        backgroundColor: const Color(0xFF1E293B),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Branch Name (e.g. Manda Hill)'),
              ),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location (City/Street)'),
              ),
              const Divider(height: 32),
              const Text('Branch Manager Account', style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: managerNameController,
                decoration: const InputDecoration(labelText: 'Manager Full Name'),
              ),
              TextField(
                controller: managerEmailController,
                decoration: const InputDecoration(labelText: 'Manager Email'),
              ),
              TextField(
                controller: managerPhoneController,
                decoration: const InputDecoration(labelText: 'Manager Phone (+260...)'),
              ),
              TextField(
                controller: managerPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Initial Password'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  locationController.text.isEmpty ||
                  managerNameController.text.isEmpty ||
                  managerEmailController.text.isEmpty ||
                  managerPhoneController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all required fields.')),
                );
                return;
              }

              final res = await ApiClient.post('/merchant/branch/create', {
                'branch_name': nameController.text,
                'location': locationController.text,
                'manager_name': managerNameController.text,
                'manager_email': managerEmailController.text,
                'manager_phone': managerPhoneController.text,
                'manager_password': managerPasswordController.text,
              }, requireAuth: true);

              if (res['success'] == true) {
                if (mounted) Navigator.pop(context);
                _fetchBranches();
              } else {
                 if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text(res['message'] ?? 'Error creating branch')),
                   );
                 }
              }
            },
            child: const Text('Create Branch'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Registered Branches',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _showAddBranchDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Branch'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: ListView.separated(
                itemCount: _branches.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final branch = _branches[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.store, color: Colors.white),
                    ),
                    title: Text(branch['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(branch['location'] ?? 'No location set'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Manager: ${branch['manager']}', style: const TextStyle(color: Colors.white70)),
                        const Text('Active', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
