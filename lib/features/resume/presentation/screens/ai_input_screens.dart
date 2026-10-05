import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../home/data/models/resume_model.dart';
import '../providers/ai_provider.dart';
import '../widgets/ai_selection_sheets.dart';

/// Screen 29: AI Tool Input — Professional Summary
class GenerateSummaryInputScreen extends ConsumerStatefulWidget {
  const GenerateSummaryInputScreen({super.key});

  @override
  ConsumerState<GenerateSummaryInputScreen> createState() =>
      _GenerateSummaryInputScreenState();
}

class _GenerateSummaryInputScreenState
    extends ConsumerState<GenerateSummaryInputScreen> {
  final _jobRoleController = TextEditingController(
    text: 'Senior Flutter Developer',
  );
  final _skillsController = TextEditingController(
    text: 'Flutter, Dart, Clean Architecture, BLoC, REST APIs',
  );
  final _jdController = TextEditingController(
    text:
        'Looking for a Senior Flutter Developer with 5+ years building production-grade iOS & Android applications. Strong command of BLoC state management, Clean Architecture, unit testing, and cross-platform UI animation performance.',
  );
  final _highlightsController = TextEditingController(
    text:
        'Built payment SDK with Hive & SQLite offline caching; reduced latency by 35%.',
  );

  String _selectedStyle = 'balanced';
  String _selectedTone = 'Professional';
  bool _consentChecked = true;
  ResumeModel? _selectedResume;

  @override
  void dispose() {
    _jobRoleController.dispose();
    _skillsController.dispose();
    _jdController.dispose();
    _highlightsController.dispose();
    super.dispose();
  }

  void _submit() {
    final role = _jobRoleController.text.trim();
    if (role.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a target role.')),
      );
      return;
    }

    final skills = _skillsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final highlights = _highlightsController.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    ref
        .read(aiProvider.notifier)
        .submitAIAction(
          'generate_summary',
          {
            'role': role,
            'skills': skills.isNotEmpty ? skills : ['Software Development'],
            'experience': highlights,
            'target_job_description': _jdController.text.trim(),
            'style': _selectedStyle,
            'tone': _selectedTone,
          },
          targetResumeTitle:
              _selectedResume?.title ?? 'Software Engineer Resume',
          targetResumeId: _selectedResume?.id,
        );

    context.push('/resume/ai-result');
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;

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
          'Ai Tool Input',
          style: textTheme.titleLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'About this tool',
            icon: Icon(Icons.help_outline, color: colors.textSecondary),
            onPressed: () {
              ResumeSelectionSheet.show(
                context,
                initialTab: 1,
                toolTitle: 'Professional Summary',
                toolCost: '1 credit',
                toolDescription:
                    'Create an editable summary draft based on your resume and target role. You’ll receive 2–3 summary options.',
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: colors.primary,
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Card: Tool Introduction
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.mutedBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Professional Summary',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.secondarySoft,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.verified,
                                        size: 13,
                                        color: colors.secondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Smart Assistant',
                                        style: textTheme.labelSmall?.copyWith(
                                          color: colors.secondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Create an editable summary draft based on your resume and target role. You’ll receive 2–3 summary options.',
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colors.cardBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, size: 16, color: colors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'AI-generated draft — review before using',
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stepped Navigation Progress Bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '1. Details',
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              '2',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '2. Preferences',
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: colors.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: colors.border,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '3',
                              style: TextStyle(
                                fontSize: 9,
                                color: colors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '3. Review',
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section 1: Resume Selection
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 20,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Selected Resume',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Text(
                  'ACTIVE SOURCE',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.secondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: colors.mutedBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.badge, color: colors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedResume?.title ??
                                  'Software Engineer Resume',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Professional Template · Updated Today, 11:20 AM',
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await ResumeSelectionSheet.show(
                            context,
                            selectedResumeId: _selectedResume?.id,
                          );
                          if (picked != null) {
                            setState(() => _selectedResume = picked);
                          }
                        },
                        child: Text(
                          'Change',
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Profile Data Completeness',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      Text(
                        '80% Ready',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.8,
                      minHeight: 6,
                      backgroundColor: colors.mutedBackground,
                      valueColor: AlwaysStoppedAnimation(colors.secondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 2: Target Role
            Text(
              'Target Role *',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _jobRoleController,
              decoration: InputDecoration(
                hintText: 'e.g. Lead Mobile Architect',
                prefixIcon: Icon(
                  Icons.work_outline,
                  color: colors.textSecondary,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.cancel, size: 20),
                  onPressed: () => _jobRoleController.clear(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Quick role chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    'Popular: ',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  _buildQuickRoleChip('Senior Flutter Developer', colors),
                  _buildQuickRoleChip('Staff Software Engineer', colors),
                  _buildQuickRoleChip('Frontend Lead', colors),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 3: Job Description Input (Optional)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Job Description (Optional)',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _jdController,
                  builder: (context, value, _) {
                    return Text(
                      '${value.text.length} / 3,000',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _jdController,
                    maxLines: 5,
                    maxLength: 3000,
                    buildCounter:
                        (
                          _, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => null,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      hintText:
                          'Paste responsibilities and requirements from the role to tailor keywords...',
                      hintStyle: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.tune, size: 16, color: colors.secondary),
                          const SizedBox(width: 4),
                          Text(
                            'Boosts ATS keyword matching',
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => _jdController.clear(),
                            child: Text(
                              'Clear',
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.mutedBackground,
                              foregroundColor: colors.primary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                            ),
                            icon: const Icon(Icons.content_paste, size: 16),
                            label: const Text(
                              'Paste',
                              style: TextStyle(fontSize: 12),
                            ),
                            onPressed: () async {
                              final data = await Clipboard.getData(
                                Clipboard.kTextPlain,
                              );
                              if (data?.text != null) {
                                _jdController.text = data!.text!;
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 4: Preferences (Style & Tone)
            Text(
              'Preferences & Tone',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Output Style',
              style: textTheme.labelMedium?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildStyleOption(
              colors,
              textTheme,
              id: 'concise',
              title: 'Concise',
              subtitle: 'Short, punchy & high-impact (2–3 sentences)',
            ),
            const SizedBox(height: 8),
            _buildStyleOption(
              colors,
              textTheme,
              id: 'balanced',
              title: 'Balanced',
              subtitle:
                  'Optimal mix of leadership, core skills, and career narrative',
              isRecommended: true,
            ),
            const SizedBox(height: 8),
            _buildStyleOption(
              colors,
              textTheme,
              id: 'detailed',
              title: 'Detailed',
              subtitle:
                  'In-depth background & quantifiable milestones (4–5 lines)',
            ),
            const SizedBox(height: 16),

            Text(
              'Tone of Voice',
              style: textTheme.labelMedium?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildToneChip('Professional', colors),
                _buildToneChip('Confident', colors),
                _buildToneChip('Conversational', colors),
                _buildToneChip('Technical', colors),
              ],
            ),
            const SizedBox(height: 24),

            // Section 5: Credit Confirmation & Consent Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.mutedBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.toll,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'AI Credit Allocation',
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '1 Credit',
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Current balance: 24 credits → 23 credits remaining',
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.cardBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'The credit is reserved when generation starts and charged only upon successful completion. Failed requests are automatically refunded.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _consentChecked,
                        activeColor: colors.primary,
                        onChanged: (v) =>
                            setState(() => _consentChecked = v ?? false),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(
                            () => _consentChecked = !_consentChecked,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              'I understand that my selected resume and input data will be processed to generate this AI draft. AI results may make mistakes and require review.',
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => context.pop(),
                child: const Text('Save & exit'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.auto_awesome, size: 20),
                label: const Text('Generate draft · 1 credit'),
                onPressed: _consentChecked ? _submit : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickRoleChip(String role, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: GestureDetector(
        onTap: () => setState(() => _jobRoleController.text = role),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colors.mutedBackground,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            role,
            style: TextStyle(
              fontSize: 12,
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStyleOption(
    AppColors colors,
    TextTheme textTheme, {
    required String id,
    required String title,
    required String subtitle,
    bool isRecommended = false,
  }) {
    final isSelected = _selectedStyle == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedStyle = id),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? colors.mutedBackground : colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? colors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? colors.primary : colors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? colors.primary
                              : colors.textPrimary,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primarySoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Recommended',
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToneChip(String tone, AppColors colors) {
    final isSelected = _selectedTone == tone;
    return GestureDetector(
      onTap: () => setState(() => _selectedTone = tone),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.cardBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check, size: 16, color: Colors.white),
              const SizedBox(width: 6),
            ],
            Text(
              tone,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Screen 30: AI Tool Input — Tool Adaptations
///
/// Multi-tool input screen providing adaptive typed forms for:
/// - Bullet Writer (1 credit)
/// - Cover Letter (2 credits)
/// - Interview Questions (2 credits)
/// - Skills Finder (1 credit)
class AIToolAdaptationsScreen extends ConsumerStatefulWidget {
  const AIToolAdaptationsScreen({super.key, this.initialTool = 'bullet'});

  final String initialTool;

  @override
  ConsumerState<AIToolAdaptationsScreen> createState() =>
      _AIToolAdaptationsScreenState();
}

class _AIToolAdaptationsScreenState
    extends ConsumerState<AIToolAdaptationsScreen> {
  late String _activeTool;

  // Bullet Writer inputs
  final _bulletNotesController = TextEditingController(
    text:
        'Wrote local database caching with SQLite and Hive, made app faster, fixed 15 bugs in checkout',
  );
  int _bulletCount = 4;
  bool _includeMetrics = true;

  // Cover Letter inputs
  final _companyController = TextEditingController(text: 'Stripe');
  final _positionController = TextEditingController(
    text: 'Senior Mobile SDK Engineer',
  );
  final _recipientController = TextEditingController(
    text: 'Engineering Hiring Team',
  );
  final _pitchController = TextEditingController(
    text:
        'Passionate about developer ergonomics and offline-first mobile payments architecture.',
  );
  String _letterLength = 'standard';

  // Interview Qs inputs
  final _interviewRoleController = TextEditingController(
    text: 'Senior Mobile Architect',
  );
  String _interviewType = 'Technical';
  String _interviewDifficulty = 'Senior';
  int _questionCount = 3;

  // Skills Finder inputs
  final _skillsRoleController = TextEditingController(
    text: 'Lead Flutter Developer',
  );
  final _existingSkillsController = TextEditingController(
    text: 'Flutter, Dart, REST',
  );

  @override
  void initState() {
    super.initState();
    _activeTool = widget.initialTool;
  }

  @override
  void dispose() {
    _bulletNotesController.dispose();
    _companyController.dispose();
    _positionController.dispose();
    _recipientController.dispose();
    _pitchController.dispose();
    _interviewRoleController.dispose();
    _skillsRoleController.dispose();
    _existingSkillsController.dispose();
    super.dispose();
  }

  int get _currentToolCost => switch (_activeTool) {
    'cover' => 2,
    'interview' => 2,
    _ => 1,
  };

  void _submit() {
    switch (_activeTool) {
      case 'bullet':
        ref.read(aiProvider.notifier).submitAIAction('generate_bullets', {
          'experience': [
            {
              'job_title': 'Associate Mobile Engineer',
              'company': 'TechSprint Solutions',
              'responsibilities': _bulletNotesController.text
                  .split('\n')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList(),
              'technologies': ['Flutter', 'SQLite', 'Hive'],
            },
          ],
          'bullet_count': _bulletCount,
          'include_metrics': _includeMetrics,
        }, targetResumeTitle: 'Software Engineer Resume');
        break;
      case 'cover':
        ref.read(aiProvider.notifier).submitAIAction('generate_summary', {
          'role': _positionController.text.trim(),
          'skills': ['Mobile Architecture', 'Dart'],
          'company': _companyController.text.trim(),
          'pitch': _pitchController.text.trim(),
          'length': _letterLength,
        }, targetResumeTitle: 'Cover Letter Draft');
        break;
      case 'interview':
        ref.read(aiProvider.notifier).submitAIAction('suggest_skills', {
          'role': _interviewRoleController.text.trim(),
          'type': _interviewType,
          'difficulty': _interviewDifficulty,
          'count': _questionCount,
        }, targetResumeTitle: 'Interview Prep');
        break;
      case 'skills':
      default:
        ref.read(aiProvider.notifier).submitAIAction('suggest_skills', {
          'role': _skillsRoleController.text.trim(),
          'existing_skills': _existingSkillsController.text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList(),
        }, targetResumeTitle: 'Software Engineer Resume');
        break;
    }

    context.push('/resume/ai-result');
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;

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
          'Ai Tool Input',
          style: textTheme.titleLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'About this tool',
            icon: Icon(Icons.help_outline, color: colors.textSecondary),
            onPressed: () {
              ResumeSelectionSheet.show(
                context,
                initialTab: 1,
                toolTitle: _toolTitle(_activeTool),
                toolCost: '$_currentToolCost credits',
                toolDescription: _toolDescription(_activeTool),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: colors.primary,
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tool selector tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildToolTab(
                    'bullet',
                    'Bullet Writer',
                    '1 cr',
                    Icons.edit_note,
                    colors,
                  ),
                  const SizedBox(width: 8),
                  _buildToolTab(
                    'cover',
                    'Cover Letter',
                    '2 cr',
                    Icons.mail_outline,
                    colors,
                  ),
                  const SizedBox(width: 8),
                  _buildToolTab(
                    'interview',
                    'Interview Qs',
                    '2 cr',
                    Icons.psychology_outlined,
                    colors,
                  ),
                  const SizedBox(width: 8),
                  _buildToolTab(
                    'skills',
                    'Skills Finder',
                    '1 cr',
                    Icons.auto_awesome_motion,
                    colors,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Assistant pulse banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.mutedBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.secondarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.smart_toy,
                      color: colors.secondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PrepMate AI Engine v4.2',
                              style: textTheme.labelSmall?.copyWith(
                                color: colors.secondary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: colors.secondary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Ready',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _toolDescription(_activeTool),
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Active Tool Adaptation View
            if (_activeTool == 'bullet')
              _buildBulletWriterView(colors, textTheme)
            else if (_activeTool == 'cover')
              _buildCoverLetterView(colors, textTheme)
            else if (_activeTool == 'interview')
              _buildInterviewQuestionsView(colors, textTheme)
            else
              _buildSkillsFinderView(colors, textTheme),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'PrepMate Balance:',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '24 credits available',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.auto_awesome, size: 20),
                label: Text(
                  'Generate draft · $_currentToolCost credit${_currentToolCost > 1 ? "s" : ""}',
                ),
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolTab(
    String id,
    String title,
    String cost,
    IconData icon,
    AppColors colors,
  ) {
    final isSelected = _activeTool == id;
    return GestureDetector(
      onTap: () => setState(() => _activeTool = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.mutedBackground,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : colors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : colors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : colors.border,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                cost,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletWriterView(AppColors colors, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Workspace & Block selection card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 18,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Target Resume Context',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.secondarySoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Auto-Synced',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'ACTIVE WORKSPACE',
                style: textTheme.labelSmall?.copyWith(
                  color: colors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.screenBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.badge, size: 20, color: colors.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Software Engineer Resume',
                            style: textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            'TechSprint Solutions (v3.2 draft)',
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.unfold_more, color: colors.textSecondary),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'SELECT EXPERIENCE BLOCK',
                style: textTheme.labelSmall?.copyWith(
                  color: colors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.screenBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colors.primarySoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.terminal,
                        size: 18,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Associate Mobile Engineer',
                            style: textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            'TechSprint Solutions · Jun 2023 - Present',
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.expand_more, color: colors.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Raw Notes Input Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notes, size: 20, color: colors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Raw Notes or Task Dump',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      _bulletNotesController.text =
                          'Wrote local database caching with SQLite and Hive, made app faster, fixed 15 bugs in checkout';
                    },
                    child: Text(
                      'Insert Sample',
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.screenBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _bulletNotesController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        hintText:
                            'Type or paste messy notes, tasks, or Jira ticket summaries...',
                        hintStyle: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _bulletNotesController,
                          builder: (context, value, _) {
                            return Text(
                              '${value.text.length} characters',
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.backspace_outlined, size: 18),
                          onPressed: () => _bulletNotesController.clear(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Metric integrity checkbox
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.mutedBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _includeMetrics,
                      activeColor: colors.primary,
                      onChanged: (v) =>
                          setState(() => _includeMetrics = v ?? true),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Include quantifiable impact & metrics',
                            style: textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'PrepMate AI never invents metrics; only refines provided metrics (e.g. 15 bugs, cache load times).',
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Target Bullet Count
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Target Bullet Count',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    'Standard Resume density',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildBulletCountOption(3, '3 bullets', colors),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildBulletCountOption(
                      4,
                      '4 bullets (Rec.)',
                      colors,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildBulletCountOption(5, '5 bullets', colors),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Live Formulation Preview
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.screenBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LIVE FORMULATION PREVIEW',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Icon(Icons.verified, size: 16, color: colors.secondary),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Architected SQLite & Hive offline caching layer...',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 14, top: 4),
                child: Text(
                  '↳ Will emphasize latency reduction & 15 solved regressions.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBulletCountOption(int count, String label, AppColors colors) {
    final isSelected = _bulletCount == count;
    return GestureDetector(
      onTap: () => setState(() => _bulletCount = count),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.screenBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : colors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildCoverLetterView(AppColors colors, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Target Company & Position',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: 'Company',
                  prefixIcon: Icon(Icons.apartment),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _positionController,
                decoration: const InputDecoration(
                  labelText: 'Target Position',
                  prefixIcon: Icon(Icons.work_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _recipientController,
                decoration: const InputDecoration(
                  labelText: 'Recipient Name / Unit (Optional)',
                  prefixIcon: Icon(Icons.person_pin),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pitchController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Personal Pitch / Passion Angle',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'OUTPUT NARRATIVE LENGTH',
                style: textTheme.labelSmall?.copyWith(
                  color: colors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildLengthChip(
                      'concise',
                      'Concise (1 page short)',
                      colors,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildLengthChip(
                      'standard',
                      'Standard (3 paragraphs)',
                      colors,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLengthChip(String id, String label, AppColors colors) {
    final isSelected = _letterLength == id;
    return GestureDetector(
      onTap: () => setState(() => _letterLength = id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.screenBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : colors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildInterviewQuestionsView(AppColors colors, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Interview Configuration',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _interviewRoleController,
                decoration: const InputDecoration(
                  labelText: 'Target Role',
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'INTERVIEW TYPE',
                style: textTheme.labelSmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: ['Technical', 'Behavioral', 'System Design'].map((t) {
                  final isSel = _interviewType == t;
                  return ChoiceChip(
                    label: Text(t),
                    selected: isSel,
                    onSelected: (_) => setState(() => _interviewType = t),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Text(
                'DIFFICULTY',
                style: textTheme.labelSmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: ['Mid-Level', 'Senior', 'Staff'].map((d) {
                  final isSel = _interviewDifficulty == d;
                  return ChoiceChip(
                    label: Text(d),
                    selected: isSel,
                    onSelected: (_) => setState(() => _interviewDifficulty = d),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Text(
                'QUESTION COUNT',
                style: textTheme.labelSmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [3, 5, 8].map((count) {
                  final isSel = _questionCount == count;
                  return ChoiceChip(
                    label: Text('$count Questions'),
                    selected: isSel,
                    onSelected: (_) => setState(() => _questionCount = count),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsFinderView(AppColors colors, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Skills Discovery Parameters',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _skillsRoleController,
                decoration: const InputDecoration(
                  labelText: 'Target Role',
                  prefixIcon: Icon(Icons.work_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _existingSkillsController,
                decoration: const InputDecoration(
                  labelText: 'Existing Skills (Optional)',
                  prefixIcon: Icon(Icons.auto_awesome),
                  helperText: 'Separate with commas',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _toolTitle(String tool) => switch (tool) {
    'bullet' => 'Experience Bullet Writer',
    'cover' => 'Cover Letter Generator',
    'interview' => 'Interview Questions Generator',
    _ => 'Skills Finder',
  };

  String _toolDescription(String tool) => switch (tool) {
    'bullet' =>
      'Turn raw responsibilities and project notes into quantifiable, action-driven achievement bullets.',
    'cover' =>
      'Compose a personalized cover letter highlighting your background and authentic motivation.',
    'interview' =>
      'Simulate role-specific interview questions with tailored key points to practice.',
    _ =>
      'Discover keywords and high-priority candidate skills from target role requirements.',
  };
}

/// Compatibility wrapper for ImproveSectionInputScreen
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
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.screenBackground,
      appBar: AppBar(
        title: const Text('Improve Section'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedSection,
              items: [
                'Professional Summary',
                'Experience',
                'Projects',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _selectedSection = v!),
              decoration: const InputDecoration(labelText: 'Section Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Current Text',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref
                      .read(aiProvider.notifier)
                      .submitAIAction('improve_section', {
                        'section_name': _selectedSection,
                        'text': _textController.text.trim(),
                      });
                  context.push('/resume/ai-result');
                },
                child: const Text('Improve Section'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compatibility wrapper for SuggestSkillsInputScreen
class SuggestSkillsInputScreen extends StatelessWidget {
  const SuggestSkillsInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AIToolAdaptationsScreen(initialTool: 'skills');
  }
}

/// Compatibility wrapper for GenerateBulletsInputScreen
class GenerateBulletsInputScreen extends StatelessWidget {
  const GenerateBulletsInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AIToolAdaptationsScreen(initialTool: 'bullet');
  }
}
