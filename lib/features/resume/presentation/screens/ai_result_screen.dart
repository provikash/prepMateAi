import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme.dart';
import '../../../../core/providers/form_provider.dart';
import '../providers/ai_provider.dart';
import '../widgets/ai_inline_edit_apply_modal.dart';

/// Screen 32: AI Result — Professional Summary Options
/// Screen 34: AI Result — Experience Bullet Verification
/// Screen 31: AI Result — Skills & Multi-Tool Adaptations
class AIResultScreen extends ConsumerStatefulWidget {
  const AIResultScreen({super.key});

  @override
  ConsumerState<AIResultScreen> createState() => _AIResultScreenState();
}

class _AIResultScreenState extends ConsumerState<AIResultScreen> {
  // Screen 31 view switcher tab
  String _activeMultiToolTab = 'skills'; // 'skills', 'cover', 'interview'

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiProvider);
    final colors = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.screenBackground,
      appBar: AppBar(
        backgroundColor: colors.screenBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () {
            ref.read(aiProvider.notifier).reset();
            context.pop();
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Back to AI Tools',
              style: textTheme.labelSmall?.copyWith(
                color: colors.textSecondary,
                fontSize: 11,
              ),
            ),
            Text(
              'Ai Result',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            Text(
              state.targetResumeTitle ?? 'Software Engineer Resume',
              style: textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: colors.textSecondary),
            onSelected: (val) {
              if (val == 'reset') {
                ref.read(aiProvider.notifier).reset();
                context.pop();
              } else if (val == 'info') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'AI Model: PrepMate AI Engine v4.2 · ${state.creditsUsed} credit used',
                    ),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18),
                    SizedBox(width: 8),
                    Text('View input details'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Report an issue'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete draft', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
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
      body: switch (state.status) {
        AIStatus.loading => _buildLoadingState(colors, textTheme),
        AIStatus.error => _buildErrorState(colors, textTheme, state),
        AIStatus.success => _buildSuccessContent(colors, textTheme, state),
        _ => _buildEmptyState(colors, textTheme),
      },
    );
  }

  Widget _buildLoadingState(AppColors colors, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              strokeWidth: 3.5,
              valueColor: AlwaysStoppedAnimation(colors.primary),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Synthesizing tailored AI draft...',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Analyzing keywords and aligning experience benchmarks',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    AppColors colors,
    TextTheme textTheme,
    AIState state,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.errorSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 40, color: colors.error),
            ),
            const SizedBox(height: 16),
            Text(
              'AI generation unavailable',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.errorMessage ??
                  'Credits were not charged. Please check your connection and retry.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: () => context.pop(),
              child: const Text('Back to Input'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppColors colors, TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 54,
              color: colors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No AI result active',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose an AI tool to generate professional resume content.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessContent(
    AppColors colors,
    TextTheme textTheme,
    AIState state,
  ) {
    final action = state.action;
    if (action == 'generate_bullets' || action == 'bullets') {
      return _buildBulletsVerificationScreen(colors, textTheme, state);
    } else if (action == 'suggest_skills' || action == 'skills') {
      return _buildSkillsAndMultiToolScreen(colors, textTheme, state);
    } else {
      return _buildSummaryOptionsScreen(colors, textTheme, state);
    }
  }

  // ==========================================
  // Screen 32: Professional Summary Options
  // ==========================================
  Widget _buildSummaryOptionsScreen(
    AppColors colors,
    TextTheme textTheme,
    AIState state,
  ) {
    final variations = state.variations.isNotEmpty
        ? state.variations
        : [state.result ?? ''];
    final labels = ['Concise', 'Balanced', 'Detailed'];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Generation status ribbon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border),
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
                          Icons.check_circle,
                          color: colors.secondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Draft ready',
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.mutedBackground,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.verified,
                                        size: 12,
                                        color: colors.primary,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'Verified',
                                        style: textTheme.labelSmall?.copyWith(
                                          color: colors.primary,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${state.creditsUsed} credit used · Generated just now',
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colors.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Review before applying card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.screenBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colors.mutedBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.shield_outlined,
                          size: 18,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Review before applying',
                              style: textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Check metrics, platforms, and stack claims. Keep only achievements that strictly reflect your real background.',
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
                const SizedBox(height: 18),

                // Variation section title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 18,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Select Variation',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colors.mutedBackground,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${variations.length} Options',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Variations list
                ...variations.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final text = entry.value;
                  final label = idx < labels.length
                      ? labels[idx]
                      : 'Option ${idx + 1}';
                  final isSelected = state.selectedVariationIndex == idx;
                  final words = text.trim().split(RegExp(r'\s+')).length;
                  final isRecommended = idx == 1;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: InkWell(
                      onTap: () {
                        ref.read(aiProvider.notifier).selectVariation(idx);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.mutedBackground
                              : colors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? colors.primary : colors.border,
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? const Color(0x142457D6)
                                  : const Color(0x06000000),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    if (isRecommended) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colors.primary,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              size: 12,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              'Recommended',
                                              style: textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.cardBackground,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: colors.border,
                                        ),
                                      ),
                                      child: Text(
                                        '$label · $words words',
                                        style: textTheme.labelSmall?.copyWith(
                                          color: colors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? colors.primary
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? colors.primary
                                          : colors.border,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 14,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              text,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colors.textPrimary,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$words words · ${text.length} chars',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.copy_rounded,
                                        size: 14,
                                      ),
                                      label: const Text(
                                        'Copy',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      onPressed: () async {
                                        await Clipboard.setData(
                                          ClipboardData(text: text),
                                        );
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Copied variation to clipboard.',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isSelected
                                            ? colors.primary
                                            : colors.cardBackground,
                                        foregroundColor: isSelected
                                            ? Colors.white
                                            : colors.textPrimary,
                                        elevation: isSelected ? 1 : 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(Icons.edit, size: 14),
                                      label: const Text(
                                        'Edit',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      onPressed: () {
                                        ref
                                            .read(aiProvider.notifier)
                                            .selectVariation(idx);
                                        _showApplyModal(context, state);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // Sticky Bottom Bar
        Container(
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
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.cached, size: 18),
                  label: const Text('Regenerate (1 cr)'),
                  onPressed: () {
                    ref.read(aiProvider.notifier).submitAIAction(
                      'generate_summary',
                      {
                        'role': 'Senior Flutter Developer',
                        'skills': ['Flutter', 'Dart', 'Clean Architecture'],
                        'target_job_description': '',
                      },
                    );
                  },
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
                  icon: const Icon(Icons.check, size: 20),
                  label: const Text('Apply to resume'),
                  onPressed: () => _showApplyModal(context, state),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // Screen 34: Experience Bullet Verification
  // ==========================================
  Widget _buildBulletsVerificationScreen(
    AppColors colors,
    TextTheme textTheme,
    AIState state,
  ) {
    final bullets = state.bullets;
    final confirmedCount = state.confirmedBullets.length;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status & cost meta ribbon
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colors.screenBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
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
                          const SizedBox(width: 8),
                          Text(
                            'Draft ready · ${bullets.length} bullets generated',
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.textSecondary,
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
                          color: colors.mutedBackground,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${state.creditsUsed} credit used',
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Fact Check Required Callout Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.secondarySoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.secondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.fact_check,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Fact Check Required',
                                  style: textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.secondary,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text(
                                    'High Impact',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PrepMate highlights numerical claims and percentages. Verify that all highlighted numbers and metrics reflect your authentic work before applying.',
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
                const SizedBox(height: 18),

                // Bullets header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Target Achievements',
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
                            color: colors.primarySoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$confirmedCount of ${bullets.length} confirmed',
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        if (confirmedCount == bullets.length) {
                          for (int i = 0; i < bullets.length; i++) {
                            ref
                                .read(aiProvider.notifier)
                                .toggleBulletConfirmation(i);
                          }
                        } else {
                          for (int i = 0; i < bullets.length; i++) {
                            if (!state.confirmedBullets.contains(i)) {
                              ref
                                  .read(aiProvider.notifier)
                                  .toggleBulletConfirmation(i);
                            }
                          }
                        }
                      },
                      child: Text(
                        confirmedCount == bullets.length
                            ? 'Deselect All'
                            : 'Select All',
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Bullet cards
                ...bullets.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final bullet = entry.value;
                  final isConfirmed = state.confirmedBullets.contains(idx);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isConfirmed ? colors.primary : colors.border,
                        width: isConfirmed ? 1.5 : 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x06000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: isConfirmed,
                          activeColor: colors.primary,
                          onChanged: (_) {
                            ref
                                .read(aiProvider.notifier)
                                .toggleBulletConfirmation(idx);
                          },
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bullet,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colors.textPrimary,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.secondarySoft,
                                      borderRadius: BorderRadius.circular(6),
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
                                          'Verified metric claim',
                                          style: textTheme.labelSmall?.copyWith(
                                            color: colors.secondary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.copy_rounded,
                                      size: 16,
                                    ),
                                    onPressed: () async {
                                      await Clipboard.setData(
                                        ClipboardData(text: bullet),
                                      );
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Copied bullet to clipboard.',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // Bottom apply action
        Container(
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
          child: SizedBox(
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
              icon: const Icon(Icons.check, size: 20),
              label: Text('Apply $confirmedCount verified bullets to resume'),
              onPressed: confirmedCount > 0
                  ? () {
                      ref
                          .read(aiProvider.notifier)
                          .applyToResume(mode: 'append');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Applied $confirmedCount bullets to experience.',
                          ),
                        ),
                      );
                      ref.read(aiProvider.notifier).reset();
                      context.pop();
                    }
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // Screen 31: Skills and Multi-Tool Screen
  // ==========================================
  Widget _buildSkillsAndMultiToolScreen(
    AppColors colors,
    TextTheme textTheme,
    AIState state,
  ) {
    final skills = state.skills;
    final confirmedCount = state.confirmedSkills.length;

    return Column(
      children: [
        // Tabs
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              _buildTabButton('skills', 'Skills Suggestions', colors),
              const SizedBox(width: 8),
              _buildTabButton('cover', 'Cover Letter', colors),
              const SizedBox(width: 8),
              _buildTabButton('interview', 'Interview Qs', colors),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_activeMultiToolTab == 'skills') ...[
                  // Header Context Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.mutedBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                              'ANALYSIS COMPLETE',
                              style: textTheme.labelSmall?.copyWith(
                                color: colors.secondary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${skills.length} Skills suggested for Senior Flutter Developer role',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Draft ready · 1 credit used · 94% JD semantic match',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Candidate Integrity Principle Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.screenBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.handshake_outlined, color: colors.secondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Candidate integrity first',
                                style: textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'PrepMate never adds skills automatically based on a job description. Review each suggestion and select only skills you actually possess and can defend in interviews.',
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
                  const SizedBox(height: 16),

                  // Technical & Architecture group
                  Text(
                    'Technical & Architecture',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  ...skills.map((skill) {
                    final isConfirmed = state.confirmedSkills.contains(skill);
                    final isAlreadyAdded = skill == 'BLoC Pattern';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isAlreadyAdded
                            ? colors.screenBackground.withValues(alpha: 0.6)
                            : colors.cardBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isConfirmed ? colors.primary : colors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isConfirmed
                                  ? colors.primary
                                  : colors.mutedBackground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isAlreadyAdded
                                  ? Icons.verified
                                  : (isConfirmed ? Icons.check : Icons.add),
                              size: 18,
                              color: isConfirmed
                                  ? Colors.white
                                  : colors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  skill,
                                  style: textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  isAlreadyAdded
                                      ? 'Already on your resume'
                                      : 'High priority keyword',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: isAlreadyAdded
                                        ? colors.textSecondary
                                        : colors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isAlreadyAdded)
                            TextButton(
                              onPressed: () {
                                ref
                                    .read(aiProvider.notifier)
                                    .toggleSkillConfirmation(skill);
                              },
                              child: Text(
                                isConfirmed ? 'Selected' : '+ Select',
                                style: TextStyle(
                                  color: isConfirmed
                                      ? colors.primary
                                      : colors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: colors.mutedBackground,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Added',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ] else if (_activeMultiToolTab == 'cover') ...[
                  // Cover Letter Result View
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
                          'Dear Hiring Team at Stripe,',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'I am writing to express my enthusiastic interest in the Senior Mobile SDK Engineer role. With extensive background architecting production-grade Flutter applications and native Android integrations, I specialize in developer ergonomics and low-latency offline systems.',
                          style: textTheme.bodyMedium?.copyWith(height: 1.45),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'At TechSprint Solutions, I led the modernization of our core checkout flow, integrating SQLite caching that cut latency by 35%. I admire Stripe’s dedication to developer documentation and developer tooling precision.',
                          style: textTheme.bodyMedium?.copyWith(height: 1.45),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Sincerely,\nCandidate',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Interview Questions View
                  _buildQuestionCard(
                    colors,
                    textTheme,
                    '1. How do you design an offline-first state management pipeline in Flutter?',
                    'Sample Answer Guidance: Discuss local persistence using SQLite/Hive, optimistic UI updates, conflict resolution with timestamps or CRDTs, and error boundary handling.',
                  ),
                  const SizedBox(height: 10),
                  _buildQuestionCard(
                    colors,
                    textTheme,
                    '2. How would you diagnose UI jank and optimize render tree rebuilds?',
                    'Sample Answer Guidance: Mention Flutter DevTools performance profiler, const constructor usage, RepaintBoundary isolation, and minimizing widget build scopes.',
                  ),
                ],
              ],
            ),
          ),
        ),

        // Bottom apply bar
        if (_activeMultiToolTab == 'skills')
          Container(
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
            child: SizedBox(
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
                icon: const Icon(Icons.check, size: 20),
                label: Text('Apply $confirmedCount confirmed skills to resume'),
                onPressed: confirmedCount > 0
                    ? () {
                        ref.read(aiProvider.notifier).applyToResume();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added $confirmedCount skills.'),
                          ),
                        );
                        ref.read(aiProvider.notifier).reset();
                        context.pop();
                      }
                    : null,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTabButton(String id, String label, AppColors colors) {
    final isSelected = _activeMultiToolTab == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeMultiToolTab = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : colors.mutedBackground,
            borderRadius: BorderRadius.circular(999),
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
      ),
    );
  }

  Widget _buildQuestionCard(
    AppColors colors,
    TextTheme textTheme,
    String question,
    String guidance,
  ) {
    return Container(
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
            question,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.mutedBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              guidance,
              style: textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showApplyModal(BuildContext context, AIState state) {
    final existingSummary = ref.read(resumeFormProvider).summary;

    ApplySummaryModalSheet.show(
      context,
      existingContent: existingSummary,
      newContent: state.activeResult,
      targetResumeTitle: state.targetResumeTitle ?? 'Software Engineer Resume',
      onApplied: () {
        ref.read(resumeFormProvider.notifier).updateSummary(state.activeResult);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully applied summary to resume!'),
          ),
        );
        ref.read(aiProvider.notifier).reset();
        context.pop();
      },
    );
  }
}
