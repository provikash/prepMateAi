import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme.dart';
import '../../../ai_credits/presentation/providers/ai_credits_provider.dart';
import '../../../ai_credits/presentation/viewmodels/ai_credit_state.dart';
import '../../../home/providers/home_providers.dart' as home;
import '../widgets/ai_transparency_sheet.dart';
import '../widgets/insufficient_credits_sheet.dart';

/// Screen 27: AI Assistant Hub & Screen 26: AI Edge States and Outage Handling.
///
/// Functions as a guided AI tools hub connected to real backend credits, active resume
/// context, server-configured tool costs, and recent credit transactions.
class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> {
  String? _selectedResumeId;
  String? _selectedResumeTitle;
  bool _recommendationDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiCreditsProvider.notifier).refreshAfterAiOperation();
    });
  }

  void _launchTool({
    required String toolName,
    required int creditCost,
    required String route,
  }) {
    final creditState = ref.read(aiCreditsProvider);
    final available = creditState.account?.availableCredits ?? 0;

    if (available < creditCost) {
      InsufficientCreditsSheet.show(
        context,
        toolName: toolName,
        requiredCredits: creditCost,
      );
      return;
    }

    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final creditState = ref.watch(aiCreditsProvider);
    final resumeListAsync = ref.watch(home.resumeListProvider);
    final availableCredits = creditState.account?.availableCredits ?? 0;

    // Pick first resume as default active resume if not selected yet
    resumeListAsync.whenData((resumes) {
      if (_selectedResumeId == null && resumes.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedResumeId = resumes.first.id;
              _selectedResumeTitle = resumes.first.title;
            });
          }
        });
      }
    });

    final activeTitle = _selectedResumeTitle ?? 'Software Engineer Resume';

    return Scaffold(
      backgroundColor: colors.screenBackground,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'P',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PrepMate AI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
                Text(
                  'AI Tools',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'About AI tools',
            icon: const Icon(Icons.help_outline),
            onPressed: () => AiTransparencySheet.show(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(aiCreditsProvider.notifier).refreshAfterAiOperation();
          ref.invalidate(home.resumeListProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            // 1. Context Subtitle & Info Pill
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Improve your application with guided AI tools.',
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                ),
                InkWell(
                  onTap: () => AiTransparencySheet.show(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primarySoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'About tools',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2. Outage / Network Banner (Screen 26 edge states)
            if (creditState.status == AiCreditStatus.error)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B626F),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_off,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'You\'re offline · AI tools paused. Saved recent results are accessible.',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref
                            .read(aiCreditsProvider.notifier)
                            .refreshAfterAiOperation(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: const Size(0, 32),
                        ),
                        child: const Text(
                          'Retry',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 3. AI Credit Balance Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.border.withValues(alpha: 0.6)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF121B2E).withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
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
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: colors.primarySoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              size: 18,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AI credits',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colors.secondarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: colors.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Active plan',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$availableCredits',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'credits available',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Credits are used only after a request starts successfully. Zero deductions on interruptions.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              context.push('/resume/ai/transactions'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.history, size: 18),
                          label: const Text('View activity'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context.push('/resume/ai/credits'),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          label: const Text('+ Get credits'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Recommended Tool Banner
            if (!_recommendationDismissed)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.primarySoft.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.2),
                  ),
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
                              Icons.stars,
                              size: 18,
                              color: colors.secondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'RECOMMENDED FOR YOUR LATEST RESUME',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: colors.secondary,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () =>
                              setState(() => _recommendationDismissed = true),
                          borderRadius: BorderRadius.circular(12),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Optimize for a job description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.description,
                                size: 13,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 4),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 160,
                                ),
                                child: Text(
                                  activeTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Uses 3 credits',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Compare your resume with a target role and review tailored keyword improvements.',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: FilledButton.icon(
                        onPressed: () => _launchTool(
                          toolName: 'Resume Optimizer',
                          creditCost: 3,
                          route: '/resume/ai-input/summary',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Text(
                          'Start optimization',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        label: const Icon(Icons.arrow_forward, size: 18),
                      ),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () =>
                            _showResumeSelector(context, resumeListAsync),
                        child: Text(
                          'Choose another resume',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // 5. Explore AI Tools 2-Column Grid
            Text(
              'Explore AI tools',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Launch purpose-built tools with transparent credit pricing.',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.88,
              children: [
                _buildToolCard(
                  context,
                  title: 'Resume Optimizer',
                  description:
                      'Compare resume with a job description and boost relevance.',
                  credits: 3,
                  icon: Icons.document_scanner_outlined,
                  onTap: () => _launchTool(
                    toolName: 'Resume Optimizer',
                    creditCost: 3,
                    route: '/resume/ai-input/summary',
                  ),
                ),
                _buildToolCard(
                  context,
                  title: 'Professional Summary',
                  description:
                      'Draft or refine a concise summary using your experience.',
                  credits: 1,
                  icon: Icons.edit_note,
                  onTap: () => _launchTool(
                    toolName: 'Professional Summary',
                    creditCost: 1,
                    route: '/resume/ai-input/summary',
                  ),
                ),
                _buildToolCard(
                  context,
                  title: 'Bullet Writer',
                  description:
                      'Turn your responsibilities into impact-driven metrics.',
                  credits: 1,
                  icon: Icons.format_list_bulleted,
                  onTap: () => _launchTool(
                    toolName: 'Experience Bullet Writer',
                    creditCost: 1,
                    route: '/resume/ai-input/bullets',
                  ),
                ),
                _buildToolCard(
                  context,
                  title: 'Skills Suggestions',
                  description:
                      'Discover relevant domain skills to review and add.',
                  credits: 1,
                  icon: Icons.lightbulb_outline,
                  onTap: () => _launchTool(
                    toolName: 'Skills Suggestions',
                    creditCost: 1,
                    route: '/resume/ai-input/skills',
                  ),
                ),
                _buildToolCard(
                  context,
                  title: 'Cover Letter',
                  description:
                      'Create an editable tailored draft for a specific job.',
                  credits: 2,
                  icon: Icons.mail_outline,
                  onTap: () => _launchTool(
                    toolName: 'Cover Letter',
                    creditCost: 2,
                    route: '/resume/ai-input/summary',
                  ),
                ),
                _buildToolCard(
                  context,
                  title: 'Improve Section',
                  description:
                      'Enhance tone, grammar, and ATS phrasing for any section.',
                  credits: 1,
                  icon: Icons.auto_fix_high,
                  onTap: () => _launchTool(
                    toolName: 'Improve Section',
                    creditCost: 1,
                    route: '/resume/ai-input/improve',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 6. Recent Activity Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/resume/ai/transactions'),
                  child: Text(
                    'View all',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildRecentActivityList(context, creditState),
            const SizedBox(height: 24),

            // 7. Responsible AI Notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.screenBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border.withValues(alpha: 0.6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.verified_user,
                          color: colors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Review AI suggestions',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'AI can make mistakes. Check every suggestion and keep only information that is accurate and true to your experience.',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 42),
                    child: InkWell(
                      onTap: () => AiTransparencySheet.show(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'How PrepMate uses AI',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.open_in_new,
                            size: 13,
                            color: colors.primary,
                          ),
                        ],
                      ),
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

  Widget _buildToolCard(
    BuildContext context, {
    required String title,
    required String description,
    required int credits,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final colors = AppColors.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF121B2E).withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.screenBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 20, color: colors.primary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$credits cr',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'Launch',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 14, color: colors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityList(BuildContext context, dynamic creditState) {
    final colors = AppColors.of(context);
    final transactions = creditState.transactions;

    if (transactions == null || transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: colors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No recent AI activity recorded yet. Try any tool above to get started.',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: transactions.take(3).map<Widget>((tx) {
        final isRefund = tx.type == 'refund';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isRefund
                      ? colors.secondarySoft
                      : colors.screenBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isRefund ? Icons.replay : Icons.auto_awesome,
                  size: 18,
                  color: isRefund ? colors.secondary : colors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.description.isNotEmpty
                          ? tx.description
                          : (tx.operation ?? 'AI Operation'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isRefund
                          ? 'Credit restored to balance'
                          : '${tx.amount} credits used',
                      style: TextStyle(
                        fontSize: 11,
                        color: isRefund
                            ? colors.secondary
                            : colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isRefund ? colors.secondarySoft : colors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isRefund ? 'Refunded' : 'Completed',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isRefund ? colors.secondary : colors.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showResumeSelector(BuildContext context, dynamic resumeListAsync) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Select Active Resume',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              resumeListAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Could not load resumes: $e'),
                ),
                data: (resumes) {
                  if (resumes.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No resumes found. Create one in Resume Builder!',
                      ),
                    );
                  }
                  return Column(
                    children: resumes.map<Widget>((r) {
                      final isSelected = r.id == _selectedResumeId;
                      return ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: Text(r.title),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Colors.blue)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedResumeId = r.id;
                            _selectedResumeTitle = r.title;
                          });
                          Navigator.pop(ctx);
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
