import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class KycReviewView extends StatefulWidget {
  const KycReviewView({super.key});

  @override
  State<KycReviewView> createState() => _KycReviewViewState();
}

class _KycReviewViewState extends State<KycReviewView> {
  bool _isLoading = true;
  List<dynamic> _submissions = [];

  @override
  void initState() {
    super.initState();
    _fetchSubmissions();
  }

  Future<void> _fetchSubmissions() async {
    final res = await ApiClient.get('/admin/kyc/pending', requireAuth: true);
    if (res['success'] == true) {
      if (mounted) {
        setState(() {
          _submissions = res['submissions'] ?? [];
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reviewSubmission(String id, String decision, {String? reason}) async {
    final res = await ApiClient.post('/admin/kyc/$id/review', {
      'decision': decision,
      'reason': reason,
    }, requireAuth: true);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission ${decision.toLowerCase()}d successfully.')),
      );
      _fetchSubmissions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Failed to review.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_submissions.isEmpty) {
      return const Center(child: Text("No pending KYC submissions.", style: TextStyle(color: Colors.white38)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _submissions.length,
      itemBuilder: (context, index) {
        final item = _submissions[index];
        return _buildSubmissionCard(item);
      },
    );
  }

  Widget _buildSubmissionCard(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(child: Text(item['full_name'][0])),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['full_name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                  Text("Submitted: ${item['submitted_at']?.split('T')[0] ?? 'Unknown'}", style: const TextStyle(color: Colors.white38, fontSize: 13)),
                ],
              ),
              const Spacer(),
              _IdTag(label: item['id_type'] ?? 'ID'),
            ],
          ),
          const Divider(height: 32, color: Colors.white10),
          Row(
            children: [
              Expanded(child: _buildImagePreview("ID Document", item['document_url'])),
              const SizedBox(width: 16),
              Expanded(child: _buildImagePreview("Selfie", item['selfie_url'])),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _showRejectDialog(item['id']),
                child: const Text("REJECT", style: TextStyle(color: Colors.redAccent)),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                onPressed: () => _reviewSubmission(item['id'], 'APPROVE'),
                child: const Text("APPROVE", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(String label, String url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            image: const DecorationImage(
              image: NetworkImage("https://via.placeholder.com/300x150?text=ID+Preview"), 
              fit: BoxFit.cover,
            ),
          ),
          child: const Center(child: Icon(Icons.zoom_in, color: Colors.white24)),
        ),
      ],
    );
  }

  void _showRejectDialog(String id) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Reject Submission", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Reason for rejection", 
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _reviewSubmission(id, 'REJECT', reason: controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text("SUBMIT REJECTION"),
          ),
        ],
      ),
    );
  }
}

class _IdTag extends StatelessWidget {
  final String label;
  const _IdTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}
