import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../providers/ai_provider.dart';
import '../widgets/resume_widgets.dart';

class GenerateSummaryInputScreen extends ConsumerStatefulWidget {
  const GenerateSummaryInputScreen({super.key});

  @override
  ConsumerState<GenerateSummaryInputScreen> createState() =>
      _GenerateSummaryInputScreenState();
}

class _GenerateSummaryInputScreenState
    extends ConsumerState<GenerateSummaryInputScreen> {
  final _jobRoleController = TextEditingController();
  final _skillsController = TextEditingController();
  final _highlightsController = TextEditingController();
  final _jdController = TextEditingController();

  @override
  void dispose() {
    _jobRoleController.dispose();
    _skillsController.dispose();
    _highlightsController.dispose();
    _jdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiProvider);
    final colors = AppColors.of(context);

    ref.listen(aiProvider, (previous, next) {
      if (next.status == AIStatus.polling) {
        context.push('/resume/ai-result');
      }
    });

    return Scaffold(
      backgroundColor: colors.screenBackground,
      appBar: _buildAppBar(context, 'Generate Summary'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildHeaderIcon(
              Icons.auto_awesome,
              colors.primarySoft,
              colors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Let AI write a professional summary\nfor your resume.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            _buildTextField(
              'Job Role / Title *',
              _jobRoleController,
              'e.g. Senior Backend Engineer',
              120,
            ),
            _buildTextField(
              'Key Skills *',
              _skillsController,
              'e.g. Python, Django, REST APIs',
              25,
              helperText: 'Add up to 25 skills, separated by commas',
            ),
            _buildTextField(
              'Experience Highlights (Optional)',
              _highlightsController,
              'e.g. Built payment API for X, Led a 4-person team',
              300,
              maxLines: 3,
            ),
            _buildTextField(
              'Target Job Description (Optional)',
              _jdController,
              'e.g. Work on scalable backend services',
              300,
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            AIButton(
              text: 'Generate Summary',
              isLoading: aiState.status == AIStatus.loading,
              onPressed: () {
                ref
                    .read(aiProvider.notifier)
                    .submitAIAction('generate_summary', {
                      // Backend expects: role (str), skills (List<str>),
                      // experience (List<str>), target_job_description (str)
                      'role': _jobRoleController.text.trim(),
                      'skills': _skillsController.text
                          .split(',')
                          .map((s) => s.trim())
                          .where((s) => s.isNotEmpty)
                          .toList(),
                      'experience': _highlightsController.text.trim().isEmpty
                          ? <String>[]
                          : _highlightsController.text
                              .split('\n')
                              .map((s) => s.trim())
                              .where((s) => s.isNotEmpty)
                              .toList(),
                      'target_job_description':
                          _jdController.text.trim(),
                    });
              },
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String title) {
    final colors = AppColors.of(context);
    return AppBar(
      backgroundColor: colors.screenBackground,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: colors.textPrimary),
        onPressed: () => context.pop(),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.close, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ],
    );
  }

  Widget _buildHeaderIcon(IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, color: iconColor, size: 32),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint,
    int maxChars, {
    int maxLines = 1,
    String? helperText,
  }) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label.split('*')[0],
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              children: label.contains('*')
                  ? [
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red),
                      ),
                    ]
                  : [],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: colors.textSecondary.withOpacity(0.5),
                fontSize: 14,
              ),
              counterText: '${controller.text.length}/$maxChars',
              counterStyle: TextStyle(color: colors.textSecondary),
              filled: true,
              fillColor: colors.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
            ),
            onChanged: (v) => setState(() {}),
          ),
          if (helperText != null) ...[
            const SizedBox(height: 8),
            Text(
              helperText,
              style: TextStyle(color: colors.textSecondary, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class ImproveSectionInputScreen extends ConsumerStatefulWidget {
  const ImproveSectionInputScreen({super.key});

  @override
  ConsumerState<ImproveSectionInputScreen> createState() =>
      _ImproveSectionInputScreenState();
}

class _ImproveSectionInputScreenState
    extends ConsumerState<ImproveSectionInputScreen> {
  String _selectedSection = 'Professional Summary';
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiProvider);
    final colors = AppColors.of(context);

    ref.listen(aiProvider, (previous, next) {
      if (next.status == AIStatus.polling) context.push('/resume/ai-result');
    });

    return Scaffold(
      backgroundColor: colors.screenBackground,
      appBar: AppBar(
        backgroundColor: colors.screenBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Improve Section',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: colors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: Colors.purple,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Improve any section content\nfor clarity and impact.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
            ),
            const SizedBox(height: 32),
            _buildDropdown('Section Name *'),
            const SizedBox(height: 20),
            _buildMultilineField(
              'Current Text *',
              _textController,
              'Paste the current text you want to improve...',
              4000,
            ),
            const SizedBox(height: 32),
            AIButton(
              text: 'Improve Section',
              isLoading: aiState.status == AIStatus.loading,
              onPressed: () {
                ref.read(aiProvider.notifier).submitAIAction(
                  'improve_section',
                  {
                    // Backend expects: section_name (str), text (str)
                    'section_name': _selectedSection,
                    'text': _textController.text.trim(),
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedSection,
          dropdownColor: colors.cardBackground,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.border),
            ),
          ),
          items: [
            'Professional Summary',
            'Experience',
            'Projects',
          ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => _selectedSection = v!),
        ),
      ],
    );
  }

  Widget _buildMultilineField(
    String label,
    TextEditingController controller,
    String hint,
    int maxChars,
  ) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 8,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colors.textSecondary.withOpacity(0.5)),
            counterText: '${controller.text.length}/$maxChars',
            counterStyle: TextStyle(color: colors.textSecondary),
            filled: true,
            fillColor: colors.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.border),
            ),
          ),
          onChanged: (v) => setState(() {}),
        ),
      ],
    );
  }
}

class SuggestSkillsInputScreen extends ConsumerStatefulWidget {
  const SuggestSkillsInputScreen({super.key});

  @override
  ConsumerState<SuggestSkillsInputScreen> createState() =>
      _SuggestSkillsInputScreenState();
}

class _SuggestSkillsInputScreenState
    extends ConsumerState<SuggestSkillsInputScreen> {
  final _roleController = TextEditingController();
  final _skillsController = TextEditingController();

  @override
  void dispose() {
    _roleController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiProvider);
    final colors = AppColors.of(context);
    ref.listen(aiProvider, (previous, next) {
      if (next.status == AIStatus.polling) context.push('/resume/ai-result');
    });

    return Scaffold(
      backgroundColor: colors.screenBackground,
      appBar: AppBar(
        backgroundColor: colors.screenBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Suggest Skills',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: colors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.lightbulb_outline,
                color: Colors.orange,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Get relevant skills based on\nyour role and experience.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
            ),
            const SizedBox(height: 32),
            _buildTextField(
              'Job Role / Title *',
              _roleController,
              'e.g. Data Scientist',
              120,
            ),
            _buildTextField(
              'Existing Skills (Optional)',
              _skillsController,
              'e.g. Pandas, SQL, Machine Learning',
              25,
              helperText: 'Add up to 25 skills, separated by commas',
            ),
            const SizedBox(height: 32),
            AIButton(
              text: 'Suggest Skills',
              isLoading: aiState.status == AIStatus.loading,
              onPressed: () {
                ref.read(aiProvider.notifier).submitAIAction('suggest_skills', {
                  // Backend expects: role (str), existing_skills (List<str>)
                  'role': _roleController.text.trim(),
                  'existing_skills': _skillsController.text
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList(),
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint,
    int maxChars, {
    String? helperText,
  }) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: colors.textSecondary.withOpacity(0.5),
              ),
              counterText: '${controller.text.length}/$maxChars',
              counterStyle: TextStyle(color: colors.textSecondary),
              filled: true,
              fillColor: colors.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
            ),
            onChanged: (v) => setState(() {}),
          ),
          if (helperText != null) ...[
            const SizedBox(height: 8),
            Text(
              helperText,
              style: TextStyle(color: colors.textSecondary, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class GenerateBulletsInputScreen extends ConsumerStatefulWidget {
  const GenerateBulletsInputScreen({super.key});

  @override
  ConsumerState<GenerateBulletsInputScreen> createState() =>
      _GenerateBulletsInputScreenState();
}

class _GenerateBulletsInputScreenState
    extends ConsumerState<GenerateBulletsInputScreen> {
  final _detailsController = TextEditingController();

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiProvider);
    final colors = AppColors.of(context);
    ref.listen(aiProvider, (previous, next) {
      if (next.status == AIStatus.polling) context.push('/resume/ai-result');
    });

    return Scaffold(
      backgroundColor: colors.screenBackground,
      appBar: AppBar(
        backgroundColor: colors.screenBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Generate Bullets',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: colors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.primarySoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.list_alt_outlined,
                color: colors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Generate impactful bullet points\nfor your experience.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
            ),
            const SizedBox(height: 32),
            _buildMultilineField(
              'Experience Details *',
              _detailsController,
              'Add your experience details (JSON format or plain text)',
              5000,
            ),
            const SizedBox(height: 20),
            _buildTipsUI(),
            const SizedBox(height: 32),
            AIButton(
              text: 'Generate Bullets',
              isLoading: aiState.status == AIStatus.loading,
              onPressed: () {
                ref.read(aiProvider.notifier).submitAIAction(
                  'generate_bullets',
                  {
                    // Backend expects: experience (List<{job_title, company, ...}>)
                    'experience': [
                      {
                        'job_title': 'Role',
                        'company': 'Company',
                        'responsibilities': _detailsController.text
                            .split('\n')
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty)
                            .toList(),
                      }
                    ],
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultilineField(
    String label,
    TextEditingController controller,
    String hint,
    int maxChars,
  ) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.info_outline,
              size: 16,
              color: colors.textSecondary.withOpacity(0.5),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 8,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colors.textSecondary.withOpacity(0.5)),
            counterText: '${controller.text.length}/$maxChars',
            counterStyle: TextStyle(color: colors.textSecondary),
            filled: true,
            fillColor: colors.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.border),
            ),
          ),
          onChanged: (v) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildTipsUI() {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tips',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 8),
          _tipItem('Include job title, company, duration'),
          _tipItem('Add key responsibilities'),
          _tipItem('Mention technologies used'),
        ],
      ),
    );
  }

  Widget _tipItem(String text) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.circle, size: 6, color: colors.primary),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 12, color: colors.primary)),
        ],
      ),
    );
  }
}
