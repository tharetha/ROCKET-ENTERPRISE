import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/socket_client.dart';
import 'package:intl/intl.dart';
import '../../widgets/access_denied_widget.dart';

class FinancialsView extends StatefulWidget {
  const FinancialsView({super.key});

  @override
  State<FinancialsView> createState() => _FinancialsViewState();
}

class _FinancialsViewState extends State<FinancialsView> {
  bool _isLoading = true;
  bool _isPermissionDenied = false;
  List<dynamic> _transactions = [];
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'K', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _fetchLedger();
    _setupSockets();
  }

  void _setupSockets() {
    SocketClient.init();
    // In this MVP, we listen globally or we would join a room like 'node_ID'
    // For now, let's just refresh when any new transaction hits the feed (if filtered on backend)
    SocketClient.on('new_transaction', (data) {
      debugPrint('[SOCKET] New transaction received via socket: ${data['reference']}');
      if (mounted) {
        _fetchLedger();
      }
    });
  }

  @override
  void dispose() {
    SocketClient.off('new_transaction');
    super.dispose();
  }

  Future<void> _fetchLedger() async {
    final res = await ApiClient.get('/merchant/ledger', requireAuth: true);
    if (res['statusCode'] == 403) {
      if (mounted) {
        setState(() {
          _isPermissionDenied = true;
          _isLoading = false;
        });
      }
      return;
    }

    if (res['success'] == true) {
      if (mounted) {
        setState(() {
          _transactions = res['data'];
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _generateReport() async {
    final res = await ApiClient.get('/merchant/financials/report', requireAuth: true);
    if (res['statusCode'] == 403) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Access Denied: Only HQ Admins can generate aggregate reports."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Report Generated: ${res['message']}"),
          backgroundColor: Colors.green,
          action: SnackBarAction(label: 'Open URL', onPressed: () {}),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_isPermissionDenied) return const AccessDeniedWidget();

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
                  Text("Financial Ledger", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  Text("Complete history of all successful settlements", style: TextStyle(color: Colors.white60)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _generateReport,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("Generate PDF Report"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(Colors.white.withOpacity(0.05)),
                    columns: const [
                      DataColumn(label: Text("Date", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Reference", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Type", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Sender", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Amount", style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: _transactions.map((tx) {
                      final date = DateTime.parse(tx['date']);
                      return DataRow(cells: [
                        DataCell(Text(DateFormat('MMM dd, HH:mm').format(date))),
                        DataCell(Text(tx['reference'], style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.white70))),
                        DataCell(_buildTypeChip(tx['type'])),
                        DataCell(Text(tx['sender'], style: const TextStyle(color: Colors.white))),
                        DataCell(Text(_currencyFormat.format(tx['amount']), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent))),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
      ),
      child: Text(
        type,
        style: const TextStyle(fontSize: 11, color: Colors.blueAccent, fontWeight: FontWeight.bold),
      ),
    );
  }
}
