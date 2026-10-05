import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../../../core/widgets/error_text.dart';
import '../../../../core/widgets/goal_card.dart';
import '../providers/onboarding_provider.dart';

class CareerPreferencesScreen extends ConsumerStatefulWidget {
  const CareerPreferencesScreen({super.key});

  @override
  ConsumerState<CareerPreferencesScreen> createState() =>
      _CareerPreferencesScreenState();
}

class _CareerPreferencesScreenState
    extends ConsumerState<CareerPreferencesScreen> {
  final List<Map<String, dynamic>> _interests = const [
    {'name': 'Software & Tech', 'icon': Icons.terminal},
    {'name': 'Data & AI', 'icon': Icons.psychology},
    {'name': 'Product Management', 'icon': Icons.alt_route},
    {'name': 'UI/UX & Design', 'icon': Icons.palette_outlined},
    {'name': 'Marketing', 'icon': Icons.campaign_outlined},
    {'name': 'Sales', 'icon': Icons.trending_up},
    {'name': 'Finance', 'icon': Icons.account_balance_outlined},
    {'name': 'Human Resources', 'icon': Icons.groups_outlined},
    {'name': 'Operations', 'icon': Icons.account_tree_outlined},
    {'name': 'Education', 'icon': Icons.school_outlined},
    {'name': 'Healthcare', 'icon': Icons.medical_services_outlined},
    {'name': 'Engineering', 'icon': Icons.precision_manufacturing_outlined},
    {'name': 'Government', 'icon': Icons.assured_workload_outlined},
    {'name': 'Freelancing', 'icon': Icons.laptop_mac},
    {'name': 'Entrepreneurship', 'icon': Icons.rocket_launch_outlined},
  ];

  final List<Map<String, dynamic>> _goals = const [
    {
      'title': 'Create my first resume',
      'subtitle': 'Step-by-step guidance for entry roles',
      'icon': Icons.note_add_outlined,
    },
    {
      'title': 'Improve my existing resume',
      'subtitle': 'Enhance phrasing and impact metrics',
      'icon': Icons.edit_document,
    },
    {
      'title': 'Optimize for a specific job',
      'subtitle': 'Match key requirements precisely',
      'icon': Icons.track_changes,
    },
    {
      'title': 'Improve my ATS alignment',
      'subtitle': 'Pass automated screening parsers',
      'icon': Icons.verified_user_outlined,
    },
    {
      'title': 'Prepare for internships',
      'subtitle': 'Showcase coursework and projects',
      'icon': Icons.badge_outlined,
    },
    {
      'title': 'Change careers',
      'subtitle': 'Highlight transferable strengths',
      'icon': Icons.swap_horiz,
    },
    {
      'title': 'Improve professional writing',
      'subtitle': 'Active tone and executive polish',
      'icon': Icons.history_edu,
    },
    {
      'title': 'Explore better templates',
      'subtitle': 'Clean, recruiter-approved formats',
      'icon': Icons.space_dashboard_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Default select at least one if none selected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(onboardingProvider);
      if (state.careerInterests.isEmpty) {
        ref.read(onboardingProvider.notifier).toggleInterest('Software & Tech');
        ref.read(onboardingProvider.notifier).toggleInterest('Data & AI');
      }
      if (state.careerGoals.isEmpty) {
        ref
            .read(onboardingProvider.notifier)
            .toggleGoal('Create my first resume');
        ref
            .read(onboardingProvider.notifier)
            .toggleGoal('Improve my ATS alignment');
      }
    });
  }

  Future<void> _continue() async {
    final success = await ref
        .read(onboardingProvider.notifier)
        .savePreferencesAndGoals();

    if (success && mounted) {
      context.push('/onboarding/complete');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final onboarding = ref.watch(onboardingProvider);
    final totalSelected =
        onboarding.careerInterests.length + onboarding.careerGoals.length;

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
          'Career Preferences',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.push('/onboarding/complete'),
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
                        'Step 3 of 4',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                      Text(
                        '75% Completed',
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
                      value: 0.75,
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
                      'What are you working toward?',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Choose any interests and goals that fit you. We’ll use them to make PrepMate more relevant.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Micro info badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: colors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Select as many as you like · Change anytime',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 1: Career Interests
                    Text(
                      'Career interests',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Which fields would you like to explore or work in?',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Wrap of filter chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _interests.map((item) {
                        final name = item['name'] as String;
                        final isSelected = onboarding.careerInterests.contains(
                          name,
                        );
                        return AppFilterChip(
                          label: name,
                          icon: item['icon'] as IconData,
                          isSelected: isSelected,
                          onSelected: (_) {
                            ref
                                .read(onboardingProvider.notifier)
                                .toggleInterest(name);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),

                    // Section 2: Career Goals
                    Text(
                      'What would you like help with?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose your primary objectives in PrepMate',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Goal cards column
                    ..._goals.map((goal) {
                      final title = goal['title'] as String;
                      final isSelected = onboarding.careerGoals.contains(title);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GoalCard(
                          title: title,
                          subtitle: goal['subtitle'] as String,
                          icon: goal['icon'] as IconData,
                          isSelected: isSelected,
                          onTap: () {
                            ref
                                .read(onboardingProvider.notifier)
                                .toggleGoal(title);
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 20),

                    // Selection summary card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: colors.secondarySoft,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.tune,
                              size: 18,
                              color: colors.secondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$totalSelected preference${totalSelected == 1 ? '' : 's'} selected',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'We’ll use these to personalize your Home screen and templates.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

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
                  key: const Key('careerPreferencesContinueButton'),
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
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              totalSelected > 0
                                  ? 'Continue ($totalSelected)'
                                  : 'Continue',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 18),
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
