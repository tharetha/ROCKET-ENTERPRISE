import '../../core/crypto_utils.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/api_client.dart';

class NodeManagementView extends StatefulWidget {
  final String? branchId;
  const NodeManagementView({super.key, this.branchId});

  @override
  State<NodeManagementView> createState() => _NodeManagementViewState();
}

class _NodeManagementViewState extends State<NodeManagementView> {
  final ScreenshotController _screenshotController = ScreenshotController();
  List<dynamic> _nodes = [];
  bool _isLoading = true;
  int _merchantLevel = 1; // Default to HQ Admin level for safety

  @override
  void initState() {
    super.initState();
    _loadUserLevel();
    _fetchNodes();
  }

  Future<void> _loadUserLevel() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _merchantLevel = prefs.getInt('merchant_level') ?? 1;
    });
  }

  Future<void> _fetchNodes() async {
    setState(() => _isLoading = true);
    final url = widget.branchId != null
        ? '/merchant/nodes?branch_id=${widget.branchId}'
        : '/merchant/nodes';

    final res = await ApiClient.get(url, requireAuth: true);
    if (res['success'] == true) {
      setState(() {
        _nodes = res['data'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to load nodes')),
        );
      }
    }
  }

  void _showAddNodeDialog() {
    final tagController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Register New Till Node'),
        backgroundColor: const Color(0xFF1E293B),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Assign a tag to this terminal (e.g. Till 1, Counter A)',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tagController,
              decoration: const InputDecoration(
                labelText: 'Node Tag',
                filled: true,
                fillColor: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final res = await ApiClient.post('/merchant/node/create', {
                'node_tag': tagController.text,
                if (widget.branchId != null) 'branch_id': widget.branchId,
              }, requireAuth: true);

              if (res['success'] == true) {
                if (mounted) Navigator.pop(context);
                _showSuccessKeyDialog(
                  res['data']['secret_key'],
                  res['data']['node_upi'],
                );
                _fetchNodes();
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['message'] ?? 'Error creating node'),
                    ),
                  );
                }
              }
            },
            child: const Text('Generate Terminal Key'),
          ),
        ],
      ),
    );
  }

  void _showSuccessKeyDialog(String key, String upi) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.greenAccent),
            SizedBox(width: 12),
            Text('Terminal Key Generated'),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'IMPORTANT: This key is only shown once. Copy it now for the Till Node setup.',
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black,
              child: SelectableText(
                'UPI: $upi\nKEY: $key',
                style: const TextStyle(
                  fontFamily: 'Courier',
                  color: Colors.greenAccent,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I Have Saved It'),
          ),
        ],
      ),
    );
  }

  void _printQR(String upi, String tag) {
    // Generate the fully interoperable EMVCo QR payload
    final qrData = CryptoUtils.buildEmvcoPayload(merchantId: tag, upiId: upi);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Screenshot(
            controller: _screenshotController,
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(40),
              color: Colors.white, // Explicit white background for screenshot
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Branded Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.rocket_launch,
                        color: Colors.blueAccent,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'ROCKET PAY',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // The QR
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blueAccent, width: 4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 200.0,
                      foregroundColor: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    tag.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    upi,
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'SCAN TO PAY',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Fast. Secure. Cashless Zambia.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final imageBytes = await _screenshotController.capture();
                      if (imageBytes != null) {
                        await Share.shareXFiles(
                          [XFile.fromData(imageBytes, mimeType: 'image/png', name: 'rocket_qr_$tag.png')],
                          text: 'Rocket Pay QR for Till $tag',
                        );
                      }
                      if (mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Download / Print QR'),
                  ),
                ],
              ),
            ),
          ),
        ),
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
                'Active Till Nodes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (_merchantLevel == 2)
                ElevatedButton.icon(
                  onPressed: _showAddNodeDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Node'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                )
              else if (_merchantLevel == 1)
                const Flexible(
                  child: Text(
                    'Node creation is managed by Branch Managers.',
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.right,
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
              child: _nodes.isEmpty
                  ? const Center(
                      child: Text(
                        'No nodes found',
                        style: TextStyle(color: Colors.white60),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _nodes.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, color: Colors.white10),
                      itemBuilder: (context, index) {
                        final node = _nodes[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          leading: const CircleAvatar(
                            backgroundColor: Colors.purpleAccent,
                            child: Icon(Icons.terminal, color: Colors.white),
                          ),
                          title: Text(
                            node['tag'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(node['upi']),
                              if (_merchantLevel == 1 &&
                                  node['branch'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Branch: ${node['branch']}',
                                  style: const TextStyle(
                                    color: Colors.blueAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (node['is_active'] == true)
                                const Chip(
                                  label: Text(
                                    'ONLINE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.greenAccent,
                                    ),
                                  ),
                                  backgroundColor: Colors.black26,
                                  side: BorderSide(color: Colors.greenAccent),
                                ),
                              const SizedBox(width: 12),
                              if (_merchantLevel == 2)
                                IconButton(
                                  icon: const Icon(
                                    Icons.qr_code,
                                    color: Colors.blueAccent,
                                  ),
                                  tooltip: 'Print Branded QR',
                                  onPressed: () =>
                                      _printQR(node['upi'], node['tag']),
                                ),
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
