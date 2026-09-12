import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/resume_analysis_model.dart';

class ResultScreen extends ConsumerWidget {
  final ResumeAnalysisModel analysis;
  const ResultScreen({super.key, required this.analysis});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Analysis Result'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHeader(analysis),
            const SizedBox(height: 32),
            _buildSection('Missing Sections', analysis.missingSections),
            _buildSkillGroups('Missing Skills', analysis.missingSkills, Colors.red.shade50, Colors.red),
            _buildSkillGroups('Matched Skills', analysis.matchedSkills, Colors.green.shade50, Colors.green),
            _buildKeywordAnalysis(analysis.keywordAnalysis),
            _buildListSection('Formatting Issues', analysis.formatIssues, Icons.text_fields),
            _buildListSection('Contact Issues', analysis.contactIssues, Icons.contact_mail),
            _buildListSection('Suggestions', analysis.suggestions, Icons.lightbulb_outline),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context), // Go back to AnalyzeScreen
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Reanalyze', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildHeader(ResumeAnalysisModel analysis) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildScoreCircle('ATS Score', analysis.atsScore, Colors.blue),
          _buildScoreCircle('Skill Score', analysis.skillScore, Colors.green),
        ],
      ),
    );
  }

  Widget _buildScoreCircle(String label, int score, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text('$score%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSection(String title, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return _buildCard(
      title,
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((e) => Chip(label: Text(e), backgroundColor: Colors.grey.shade100)).toList(),
      ),
    );
  }

  Widget _buildSkillGroups(String title, Map<String, List<String>> groups, Color bg, Color text) {
    if (groups.isEmpty) return const SizedBox.shrink();
    return _buildCard(
      title,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: groups.entries.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: entry.value.map((s) => Chip(
                  label: Text(s, style: TextStyle(color: text, fontSize: 12)),
                  backgroundColor: bg,
                )).toList(),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildKeywordAnalysis(KeywordAnalysis kw) {
    return _buildCard(
      'Keyword Analysis',
      Column(
        children: [
          LinearProgressIndicator(
            value: kw.matchPercentage / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
            minHeight: 12,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 8),
          Text('Match Percentage: ${kw.matchPercentage}%', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildListSection('Missing Keywords', kw.missingKeywords, Icons.close, color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildListSection(String title, List<String> items, IconData icon, {Color color = Colors.black87}) {
    if (items.isEmpty) return const SizedBox.shrink();
    return _buildCard(
      title,
      Column(
        children: items.map((item) => ListTile(
          leading: Icon(icon, color: color, size: 20),
          title: Text(item, style: const TextStyle(fontSize: 14)),
          contentPadding: EdgeInsets.zero,
          dense: true,
        )).toList(),
      ),
    );
  }

  Widget _buildCard(String title, Widget content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }
}
