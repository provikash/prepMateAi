import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/ats_viewmodel.dart';
import '../../domain/models/ats_analysis.dart';
import '../../../../config/theme.dart';

class AtsAnalysisScreen extends ConsumerWidget {
  const AtsAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(atsViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1D2939)),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'ATS Score Analysis',
          style: TextStyle(color: Color(0xFF1D2939), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: state.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : state.error != null
          ? Center(child: Text('Error: ${state.error}'))
          : _buildContent(context, state.analysis!),
    );
  }

  Widget _buildContent(BuildContext context, AtsAnalysis analysis) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Score Circular Progress
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: analysis.score / 100,
                    strokeWidth: 12,
                    backgroundColor: const Color(0xFFF2F4F7),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${analysis.score}',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 12.0),
                          child: Text(
                            '/100',
                            style: TextStyle(fontSize: 20, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'SCORE',
                      style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          Text(
            analysis.status,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D2939),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Optimized for ${analysis.role}',
            style: const TextStyle(color: Colors.grey, fontSize: 15),
          ),
          
          const SizedBox(height: 40),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Key Insights',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1D2939)),
            ),
          ),
          const SizedBox(height: 16),
          
          // Insights List
          ...analysis.insights.map((insight) => _buildInsightCard(insight)),
          
          const SizedBox(height: 100), // Space for floating button
        ],
      ),
    );
  }

  Widget _buildInsightCard(AtsInsight insight) {
    Color iconBg;
    IconData icon;
    Color iconColor;

    switch (insight.status) {
      case InsightStatus.success:
        iconBg = const Color(0xFFE7F6EC);
        icon = Icons.check_circle;
        iconColor = const Color(0xFF039855);
        break;
      case InsightStatus.warning:
        iconBg = const Color(0xFFFEF9C3);
        icon = Icons.warning_amber_rounded;
        iconColor = const Color(0xFFA16207);
        break;
      case InsightStatus.error:
        iconBg = const Color(0xFFFEE4E2);
        icon = Icons.cancel;
        iconColor = const Color(0xFFD92D20);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1D2939)),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}

// Separate widget for the floating button to handle the overlap as in screenshot
class AtsFloatingButton extends StatelessWidget {
  const AtsFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 24,
      right: 24,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Dark navy as in screenshot
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {},
          child: const Center(
            child: Text(
              'Improve Now',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
