import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class AiInsightsView extends StatefulWidget {
  const AiInsightsView({super.key});

  @override
  State<AiInsightsView> createState() => _AiInsightsViewState();
}

class _AiInsightsViewState extends State<AiInsightsView> {
  List<dynamic> _basicInsights = [];
  List<dynamic> _advancedInsights = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInsights();
  }

  Future<void> _fetchInsights() async {
    final res = await ApiClient.get('/merchant/ai-insights', requireAuth: true);
    if (res['success'] == true) {
      setState(() {
        _basicInsights = res['data']['basic'];
        _advancedInsights = res['data']['advanced'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("AI Business Insights", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const Text("Gemini-powered analysis of your retail performance", style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 32),
          
          const Text("Free Insights", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 3,
            ),
            itemCount: _basicInsights.length,
            itemBuilder: (context, index) {
              final item = _basicInsights[index];
              return _buildInsightCard(item);
            },
          ),
          
          const SizedBox(height: 48),
          Row(
            children: [
              const Text("Advanced Predictive Insights", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.amberAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: const Text("PRO", style: TextStyle(fontSize: 10, color: Colors.amberAccent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 3,
            ),
            itemCount: _advancedInsights.length,
            itemBuilder: (context, index) {
              final item = _advancedInsights[index];
              return _buildInsightCard(item, isPro: true);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(dynamic insight, {bool isPro = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPro ? Colors.amberAccent.withOpacity(0.1) : Colors.white10),
      ),
      child: Row(
        children: [
          Icon(
            isPro ? Icons.lock_outline : _getIcon(insight['icon']), 
            color: isPro ? Colors.amberAccent : Colors.blueAccent, 
            size: 28
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(insight['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  isPro ? "Subscribe to Rocket Enterprise Pro to unlock this insight." : insight['content'],
                  style: TextStyle(color: isPro ? Colors.white38 : Colors.white60, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String? name) {
    switch (name) {
      case 'trending_up': return Icons.trending_up;
      case 'people': return Icons.people;
      default: return Icons.lightbulb_outline;
    }
  }
}
