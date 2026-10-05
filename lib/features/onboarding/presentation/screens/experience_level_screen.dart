import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/error_text.dart';
import '../../../../core/widgets/selection_card.dart';
import '../providers/onboarding_provider.dart';

class ExperienceLevelScreen extends ConsumerStatefulWidget {
  const ExperienceLevelScreen({super.key});

  @override
  ConsumerState<ExperienceLevelScreen> createState() =>
      _ExperienceLevelScreenState();
}

class _ExperienceLevelScreenState extends ConsumerState<ExperienceLevelScreen> {
  late String _selectedLevel;

  final List<Map<String, dynamic>> _options = const [
    {
      'id': 'student',
      'title': 'Student',
      'subtitle': 'Building academic, project, or internship experience',
      'icon': Icons.school_outlined,
    },
    {
      'id': 'fresher',
      'title': 'Fresher',
      'subtitle': 'Preparing for a first full-time role',
      'badge': 'Target',
      'icon': Icons.rocket_launch_outlined,
    },
    {
      'id': 'early',
      'title': 'Early career · 1–3 years',
      'subtitle': 'Growing practical experience and achievements',
      'icon': Icons.eco_outlined,
    },
    {
      'id': 'mid',
      'title': 'Mid career · 3–5 years',
      'subtitle': 'Building deeper ownership and specialization',
      'icon': Icons.work_outline,
    },
    {
      'id': 'experienced',
      'title': 'Experienced · 5–10 years',
      'subtitle': 'Showing leadership, impact, and expertise',
      'icon': Icons.trending_up_outlined,
    },
    {
      'id': 'senior',
      'title': 'Senior · 10+ years',
      'subtitle': 'Presenting strategic and leadership experience',
      'icon': Icons.explore_outlined,
    },
    {
      'id': 'pivot',
      'title': 'Career changer',
      'subtitle': 'Transitioning into a new industry or domain',
      'icon': Icons.swap_horiz,
    },
  ];

  @override
  void initState() {
    super.initState();
    final saved = ref.read(onboardingProvider).experienceLevel;
    _selectedLevel = (saved != null && saved.isNotEmpty) ? saved : 'fresher';
  }

  Future<void> _continue() async {
    final success = await ref
        .read(onboardingProvider.notifier)
        .saveExperienceLevel(_selectedLevel);

    if (success && mounted) {
      context.push('/onboarding/goals');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final onboarding = ref.watch(onboardingProvider);

    return Scaffold(
      backgroundColor: colors.screenBackground,
      appBar: AppBar(
        backgroundColor: colors.surface.withValues(alpha: 0.85),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: colors.textPrimary,
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Your Experience',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.push('/onboarding/goals'),
            child: Text(
              'Skip',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              color: colors.surface,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step 2 of 4',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                      Text(
                        '50% Completed',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.50,
                      minHeight: 6,
                      backgroundColor: colors.surfaceContainer,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Where are you in your career?',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'We’ll adapt resume guidance and mock questions to your current stage. You can change this later.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Options list
                    ..._options.map((opt) {
                      final id = opt['id'] as String;
                      final isSelected = _selectedLevel == id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SelectionCard(
                          title: opt['title'] as String,
                          subtitle: opt['subtitle'] as String,
                          icon: opt['icon'] as IconData,
                          badge: opt['badge'] as String?,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() => _selectedLevel = id);
                            ref
                                .read(onboardingProvider.notifier)
                                .setExperienceLevel(id);
                          },
                        ),
                      );
                    }),

                    if (onboarding.errorMessage != null &&
                        onboarding.errorMessage!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ErrorText(message: onboarding.errorMessage),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Sticky Bottom Continue Action
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  key: const Key('experienceLevelContinueButton'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: onboarding.isSaving ? null : _continue,
                  child: onboarding.isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
