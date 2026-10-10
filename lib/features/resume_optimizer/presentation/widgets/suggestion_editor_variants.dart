import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';

/// Screen 54: Suggestion Editor Tool-Specific Variants
///
/// Specialized editors for:
/// 1. SummaryEditorVariant (Word count target 40-60 words, executive tone)
/// 2. SkillAuditVariant (Skill chips with proficiency, relevance, confirmation)
/// 3. ProjectRewriteVariant (Problem / Solution / Tech Stack / Impact breakdown)
/// 4. CertificateVariant (Credential name, issuer, issue date, verification link)
class SuggestionEditorVariantsWidget extends StatefulWidget {
  const SuggestionEditorVariantsWidget({
    super.key,
    required this.initialSection,
    required this.onSave,
  });

  final String initialSection;
  final ValueChanged<String> onSave;

  @override
  State<SuggestionEditorVariantsWidget> createState() =>
      _SuggestionEditorVariantsWidgetState();
}

class _SuggestionEditorVariantsWidgetState
    extends State<SuggestionEditorVariantsWidget> {
  late int _activeTab; // 0: Summary, 1: Skills, 2: Projects, 3: Certificates

  // Controllers
  late final TextEditingController _summaryController;
  late final TextEditingController _projectProblemController;
  late final TextEditingController _projectSolutionController;
  late final TextEditingController _projectImpactController;
  late final TextEditingController _certNameController;
  late final TextEditingController _certIssuerController;

  final Set<String> _confirmedSkills = {
    'Riverpod',
    'Clean Architecture',
    'CI/CD Pipelines',
  };

  @override
  void initState() {
    super.initState();
    _activeTab = switch (widget.initialSection.toLowerCase()) {
      'skills' => 1,
      'projects' => 2,
      'certifications' || 'education' => 3,
      _ => 0,
    };

    _summaryController = TextEditingController(
      text:
          'Accomplished Mobile Architect with 4+ years spearheading fintech mobile ecosystems for Tier-1 digital banking products. Champions declarative architecture, sub-second transaction workflows, and multi-disciplinary squad leadership. Consistently accelerates launch cycles while enforcing strict cryptographic and regulatory standards.',
    );
    _projectProblemController = TextEditingController(
      text:
          'Legacy app suffered from 2.4s UI thread jank and frequent unhandled offline state crashes.',
    );
    _projectSolutionController = TextEditingController(
      text:
          'Re-architected core transaction pipeline with Hive local cache and Flutter Riverpod reactive state flow.',
    );
    _projectImpactController = TextEditingController(
      text:
          'Reduced crash rate by 82% and boosted app store ratings from 3.8 to 4.7 stars.',
    );
    _certNameController = TextEditingController(
      text: 'Google Cloud Certified Associate Cloud Engineer',
    );
    _certIssuerController = TextEditingController(
      text: 'Google Cloud Platform',
    );
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _projectProblemController.dispose();
    _projectSolutionController.dispose();
    _projectImpactController.dispose();
    _certNameController.dispose();
    _certIssuerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Selector Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              _buildTabPill(0, 'Executive Summary', Icons.edit_note),
              const SizedBox(width: 8),
              _buildTabPill(1, 'Skill Audit', Icons.verified_user),
              const SizedBox(width: 8),
              _buildTabPill(2, 'Project Rewrite', Icons.rocket_launch),
              const SizedBox(width: 8),
              _buildTabPill(3, 'New Certificate', Icons.workspace_premium),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: switch (_activeTab) {
            0 => _buildSummaryView(context),
            1 => _buildSkillAuditView(context),
            2 => _buildProjectRewriteView(context),
            _ => _buildCertificateView(context),
          },
        ),
      ],
    );
  }

  Widget _buildTabPill(int index, String label, IconData icon) {
    final colors = AppColors.of(context);
    final isSelected = _activeTab == index;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (_) => setState(() => _activeTab = index),
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : colors.textSecondary,
      ),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildSummaryView(BuildContext context) {
    final colors = AppColors.of(context);
    final words = _summaryController.text.trim().isEmpty
        ? 0
        : _summaryController.text.trim().split(RegExp(r'\s+')).length;
    final isGoodLength = words >= 40 && words <= 60;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: colors.screenBackground,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.straighten, size: 16, color: colors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '$words words',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '· Target 40–60 words',
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isGoodLength
                      ? const Color(0xFFE1F4F1)
                      : const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  isGoodLength ? 'Optimal Length' : 'Trim to 50w',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isGoodLength
                        ? const Color(0xFF087E78)
                        : const Color(0xFFA15C00),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Executive Summary Content',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _summaryController,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Enter executive summary...',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Apply Executive Summary',
          onPressed: () => widget.onSave(_summaryController.text),
        ),
      ],
    );
  }

  Widget _buildSkillAuditView(BuildContext context) {
    final colors = AppColors.of(context);
    final sampleSkills = [
      {'name': 'Riverpod', 'relevance': 'High', 'cat': 'Architecture'},
      {'name': 'Clean Architecture', 'relevance': 'High', 'cat': 'Methodology'},
      {'name': 'CI/CD Pipelines', 'relevance': 'Medium', 'cat': 'DevOps'},
      {'name': 'SQLite / Hive', 'relevance': 'Medium', 'cat': 'Storage'},
      {'name': 'GraphQL', 'relevance': 'Optional', 'cat': 'API'},
      {'name': 'TDD / Mockito', 'relevance': 'High', 'cat': 'Testing'},
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          'Tailored Skill Verification',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Confirm each skill you genuinely possess before adding to the tailored resume.',
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        ...sampleSkills.map((s) {
          final name = s['name']!;
          final isConfirmed = _confirmedSkills.contains(name);
          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: CheckboxListTile(
              value: isConfirmed,
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _confirmedSkills.add(name);
                  } else {
                    _confirmedSkills.remove(name);
                  }
                });
              },
              title: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              subtitle: Text(
                '${s['cat']} · ${s['relevance']} Priority',
                style: const TextStyle(fontSize: 11),
              ),
              secondary: Icon(
                isConfirmed ? Icons.check_circle : Icons.circle_outlined,
                color: isConfirmed ? const Color(0xFF087E78) : Colors.grey,
              ),
            ),
          );
        }),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Apply Confirmed Skills (${_confirmedSkills.length})',
          onPressed: () => widget.onSave(_confirmedSkills.join(', ')),
        ),
      ],
    );
  }

  Widget _buildProjectRewriteView(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          'Structured Project Narrative',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        const Text(
          'Format project accomplishments into Problem, Solution, and Measurable Impact.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '1. The Challenge / Problem',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _projectProblemController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'What challenge did you solve?',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                '2. Technical Solution',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _projectSolutionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'What tools and architecture did you build?',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                '3. Quantified Impact',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _projectImpactController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'What were the business or performance metrics?',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Apply Structured Project',
          onPressed: () {
            final combined =
                '${_projectProblemController.text.trim()} ${_projectSolutionController.text.trim()} ${_projectImpactController.text.trim()}';
            widget.onSave(combined);
          },
        ),
      ],
    );
  }

  Widget _buildCertificateView(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          'Credential & Certification Details',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        const Text(
          'Add verified industry certificates to enhance ATS scoring for this job.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Credential Title',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _certNameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. AWS Certified Solutions Architect',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Issuing Organization',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _certIssuerController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Amazon Web Services',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Add Credential to Draft',
          onPressed: () {
            widget.onSave(
              '${_certNameController.text.trim()} — ${_certIssuerController.text.trim()}',
            );
          },
        ),
      ],
    );
  }
}
