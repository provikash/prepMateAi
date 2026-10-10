import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../config/theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/ai_credit_models.dart';
import '../providers/ai_credits_provider.dart';
import '../viewmodels/ai_credit_state.dart';
import 'credit_widgets.dart';

// =============================================================================
// SCREEN 68: AI CREDITS DASHBOARD VIEW
// =============================================================================

class AiCreditsDashboardView extends ConsumerWidget {
  const AiCreditsDashboardView({
    super.key,
    required this.state,
    this.onViewVariants,
    this.onInspectReservation,
    this.onOpenSupport,
  });

  final AiCreditState state;
  final VoidCallback? onViewVariants;
  final VoidCallback? onInspectReservation;
  final VoidCallback? onOpenSupport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = state.account!;
    final colors = AppColors.of(context);
    final planName = state.currentPlan?.name ?? 'Standard tier';
    final recent = state.transactions.take(4).toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(aiCreditsProvider.notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.sm,
          AppSpacing.screen,
          AppSpacing.xxl,
        ),
        children: [
          // Screen 68 Balance Hero Card
          _buildBalanceHeroCard(context, ref, account, planName, colors),
          const SizedBox(height: AppSpacing.md),

          // Upcoming Schedule Card (Screen 68)
          _buildUpcomingScheduleCard(context, account, colors),
          const SizedBox(height: AppSpacing.md),

          // Reconciled Balance Breakdown (Screen 68)
          _buildReconciledLedgerCard(context, account, colors),
          const SizedBox(height: AppSpacing.section),

          // AI Feature Costs Section (Screen 68)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI feature costs',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton(
                onPressed: () => context.push('/ai-plans'),
                child: const Text('View plans'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.card),
            child: Column(
              children: [
                for (var i = 0; i < state.operations.take(4).length; i++) ...[
                  AiOperationCostTile(operation: state.operations[i]),
                  if (i != state.operations.take(4).length - 1)
                    const Divider(height: 1),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.section),

          // Recent AI Activity Section (Screen 68)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent AI activity',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton(
                onPressed: () => context.push('/ai-transactions'),
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.card),
            child: recent.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Center(
                      child: Text('No recent credit transactions.'),
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < recent.length; i++) ...[
                        CreditTransactionTile(transaction: recent[i]),
                        if (i != recent.length - 1) const Divider(height: 1),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.section),

          // Reassurance Footnote (Core resume tools stay free)
          _buildCoreToolsFreeCard(context, colors),
        ],
      ),
    );
  }

  Widget _buildBalanceHeroCard(
    BuildContext context,
    WidgetRef ref,
    AiCreditAccount account,
    String planName,
    AppColors colors,
  ) {
    final reserved = account.reservedCredits;
    final totalPool = account.balance;

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row: Available credits · Updated just now · Refresh button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Available credits',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF006A65),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Live sync',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              IconButton(
                tooltip: 'Refresh balance',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.sync, size: 20),
                onPressed: () => ref.read(aiCreditsProvider.notifier).refresh(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Large Balance Metric
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                account.isUnlimited ? '∞' : '${account.availableCredits}',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  planName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Ready to use for AI tools & instant reviews',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),

          // Reserved Credits Pill (Screen 68)
          if (reserved > 0) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: const Color(0xFFA15C00).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE0B2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.lock_clock,
                      size: 18,
                      color: Color(0xFFA15C00),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$reserved credits reserved',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFA15C00),
                          ),
                        ),
                        Text(
                          'Active resume optimization',
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFFA15C00).withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: onInspectReservation,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Details',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFA15C00),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Color(0xFFA15C00),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Footnote: total balance including active reservations
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: colors.textSecondary),
              const SizedBox(width: 6),
              Text(
                '$totalPool total balance including active reservations',
                style: TextStyle(fontSize: 11, color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // CTA Button (Screen 68)
          AppPrimaryButton(
            label: 'View credit options & packs',
            icon: Icons.add_circle_outline,
            onPressed: () => context.push('/ai-plans'),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingScheduleCard(
    BuildContext context,
    AiCreditAccount account,
    AppColors colors,
  ) {
    final reset = account.resetDate == null
        ? '1 Nov 2026'
        : DateFormat('d MMM yyyy').format(account.resetDate!.toLocal());

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_month, size: 20, color: colors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Upcoming schedule',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.mutedBackground,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'Auto-managed',
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Event 1: Monthly rollover auto-deposit
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.mutedBackground,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF93F0E8),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.event_repeat,
                    size: 20,
                    color: Color(0xFF006A65),
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
                            '+${account.monthlyAllocation} plan credits',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.cardBackground,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: Text(
                              reset,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: colors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Monthly plan rollover auto-deposit',
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
        ],
      ),
    );
  }

  Widget _buildReconciledLedgerCard(
    BuildContext context,
    AiCreditAccount account,
    AppColors colors,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Credit balance breakdown',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF93F0E8).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 12, color: Color(0xFF006A65)),
                    SizedBox(width: 4),
                    Text(
                      'Healthy Ledger',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF006A65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.mutedBackground,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AVAILABLE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${account.availableCredits}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: colors.primary,
                        ),
                      ),
                      Text(
                        'Ready to spend',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RESERVED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFA15C00),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${account.reservedCredits}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFA15C00),
                        ),
                      ),
                      const Text(
                        'In-flight drafts',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFA15C00),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoreToolsFreeCard(BuildContext context, AppColors colors) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: colors.secondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your core resume tools stay free',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Creating, editing, previewing, and downloading resumes never uses AI credits.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SCREEN 66: AI CREDITS ACCOUNT VARIANTS & ZERO STATE
// =============================================================================

class AiCreditsAccountVariantsView extends StatefulWidget {
  const AiCreditsAccountVariantsView({
    super.key,
    required this.account,
    this.initialVariant = 'zero',
    this.onViewPlans,
    this.onBrowseFreeTools,
  });

  final AiCreditAccount account;
  final String initialVariant; // 'zero', 'enterprise', 'restricted'
  final VoidCallback? onViewPlans;
  final VoidCallback? onBrowseFreeTools;

  @override
  State<AiCreditsAccountVariantsView> createState() =>
      _AiCreditsAccountVariantsViewState();
}

class _AiCreditsAccountVariantsViewState
    extends State<AiCreditsAccountVariantsView> {
  late String _currentVariant;

  @override
  void initState() {
    super.initState();
    _currentVariant = widget.initialVariant;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        // Variant Selector Pill Strip (Screen 66)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colors.mutedBackground,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              _buildVariantButton('zero', 'Zero State', 'State A'),
              _buildVariantButton('enterprise', 'Enterprise', 'State B'),
              _buildVariantButton('restricted', 'Restricted', 'State C'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Render Active Variant
        if (_currentVariant == 'zero')
          _buildZeroCreditsVariant(context, colors)
        else if (_currentVariant == 'enterprise')
          _buildEnterpriseVariant(context, colors)
        else
          _buildRestrictedVariant(context, colors),
      ],
    );
  }

  Widget _buildVariantButton(String key, String label, String badge) {
    final isSelected = _currentVariant == key;
    final colors = AppColors.of(context);

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentVariant = key),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.cardBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x0C000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(
                badge,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? colors.primary : colors.textSecondary,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? colors.textPrimary : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // STATE A: ZERO AVAILABLE CREDITS
  Widget _buildZeroCreditsVariant(BuildContext context, AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Reassurance Banner
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: colors.mutedBackground,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_month, size: 20, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your monthly plan of 10 free credits renews on 1 November 2026 (5 days left).',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Hero Card (0 Credits)
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Balance',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '0',
                            style: Theme.of(context).textTheme.displayLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Available credits',
                            style: TextStyle(
                              fontSize: 16,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.mutedBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.toll,
                      size: 24,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "You've used all available credits for this billing period.",
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lock_clock,
                        size: 16,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Reserved in ongoing drafts',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    '0 reserved',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppPrimaryButton(
                label: 'View credit options',
                icon: Icons.add_circle_outline,
                onPressed:
                    widget.onViewPlans ?? () => context.push('/ai-plans'),
              ),
              const SizedBox(height: AppSpacing.xs),
              AppSecondaryButton(
                label: 'Browse free tools',
                icon: Icons.explore_outlined,
                onPressed: widget.onBrowseFreeTools ?? () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.section),

        // Included Without Credits Section (Screen 66)
        Text(
          'Included Without Credits',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Always accessible free tools that do not require any AI balance',
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),

        _buildFreeToolTile(
          context,
          icon: Icons.format_list_bulleted,
          title: 'ATS Keyword Checker',
          subtitle: 'Instant rule-based scan',
          color: colors.primary,
        ),
        const SizedBox(height: AppSpacing.xs),
        _buildFreeToolTile(
          context,
          icon: Icons.spellcheck,
          title: 'Grammar & Formatting',
          subtitle: 'Standard syntax review',
          color: const Color(0xFF006A65),
        ),
        const SizedBox(height: AppSpacing.xs),
        _buildFreeToolTile(
          context,
          icon: Icons.description_outlined,
          title: 'Resume Builder',
          subtitle: 'Create, edit & arrange sections',
          color: Colors.indigo,
        ),
        const SizedBox(height: AppSpacing.xs),
        _buildFreeToolTile(
          context,
          icon: Icons.download_outlined,
          title: 'PDF Export',
          subtitle: 'High-res document generation',
          color: Colors.deepPurple,
        ),
      ],
    );
  }

  // STATE B: ENTERPRISE / UNLIMITED
  Widget _buildEnterpriseVariant(BuildContext context, AppColors colors) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF93F0E8),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Text(
                  'UNLIMITED AI ACCESS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF006A65),
                  ),
                ),
              ),
              const Icon(
                Icons.all_inclusive,
                size: 28,
                color: Color(0xFF006A65),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Enterprise Pro Subscription',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Unlimited AI optimization and ATS scoring enabled across all active job applications.',
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          const Divider(height: 24),
          const Row(
            children: [
              Icon(Icons.check_circle, size: 18, color: Color(0xFF006A65)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Fair-use automated rate limits apply (100 requests / hr)',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.check_circle, size: 18, color: Color(0xFF006A65)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Renews automatically on 1 Dec 2026',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // STATE C: RESTRICTED
  Widget _buildRestrictedVariant(BuildContext context, AppColors colors) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFDAD6),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: const Text(
              'ACCOUNT RESTRICTED',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFFBA1A1A),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'AI Feature Access Temporarily Suspended',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Your account has temporary limits applied due to unusual activity or payment dispute. Your standard resume documents remain safe.',
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(
            label: 'Contact Support',
            icon: Icons.support_agent,
            onPressed: () =>
                showBillingSupportModal(context, defaultCategory: 'Other'),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeToolTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 20, color: colors.textSecondary),
        ],
      ),
    );
  }
}

// =============================================================================
// SCREEN 67: AI CREDITS POLICY & INSPECTION BOTTOM SHEETS
// =============================================================================

void showAiCreditsPolicySheet(
  BuildContext context, {
  required List<AiOperation> operations,
  int reservedCredits = 0,
  VoidCallback? onOpenSupport,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.of(context).cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => _AiCreditsPolicySheetContent(
      operations: operations,
      reservedCredits: reservedCredits,
      onOpenSupport: onOpenSupport,
    ),
  );
}

class _AiCreditsPolicySheetContent extends StatefulWidget {
  const _AiCreditsPolicySheetContent({
    required this.operations,
    required this.reservedCredits,
    this.onOpenSupport,
  });

  final List<AiOperation> operations;
  final int reservedCredits;
  final VoidCallback? onOpenSupport;

  @override
  State<_AiCreditsPolicySheetContent> createState() =>
      _AiCreditsPolicySheetContentState();
}

class _AiCreditsPolicySheetContentState
    extends State<_AiCreditsPolicySheetContent> {
  String _activeTab = 'policy'; // 'policy' or 'reservation'

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: colors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How AI credits work',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'PrepMate Fair Allocation Engine',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Tabs: Usage Policy & Live Lock (Screen 67)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Usage Policy'),
                  selected: _activeTab == 'policy',
                  onSelected: (_) => setState(() => _activeTab = 'policy'),
                  selectedColor: colors.primary,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _activeTab == 'policy'
                        ? Colors.white
                        : colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Live Lock'),
                      if (widget.reservedCredits > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF006A65),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${widget.reservedCredits}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  selected: _activeTab == 'reservation',
                  onSelected: (_) => setState(() => _activeTab = 'reservation'),
                  selectedColor: colors.primary,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _activeTab == 'reservation'
                        ? Colors.white
                        : colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 20),

          // Content Panels
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                0,
                AppSpacing.screen,
                AppSpacing.xxl,
              ),
              children: [
                if (_activeTab == 'policy')
                  _buildPolicyTab(context, colors)
                else
                  _buildReservationTab(context, colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyTab(BuildContext context, AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Available Credits Card
        _buildPolicyCard(
          context,
          icon: Icons.bolt,
          title: 'Available credits',
          badge: 'Immediate',
          badgeBg: colors.primarySoft,
          badgeFg: colors.primary,
          description:
              'Ready to deploy on demand for instant resume optimization, bullet rewriting, and ATS analysis.',
        ),
        const SizedBox(height: AppSpacing.sm),

        // Reserved Credits Card
        _buildPolicyCard(
          context,
          icon: Icons.lock_clock,
          title: 'Reserved credits',
          badge: 'Temporary',
          badgeBg: const Color(0xFF93F0E8),
          badgeFg: const Color(0xFF006A65),
          description:
              'Temporarily held while an AI operation runs. If the generation fails, credits are automatically returned. Committed only upon successful results.',
        ),
        const SizedBox(height: AppSpacing.sm),

        // Refund Guarantee Card
        _buildPolicyCard(
          context,
          icon: Icons.published_with_changes,
          title: 'Refund guarantee',
          badge: 'Fair use',
          badgeBg: colors.mutedBackground,
          badgeFg: colors.textSecondary,
          description:
              'Zero double-charge safeguard: duplicate submissions are recognized via idempotency keys without consuming extra balance.',
        ),
        const SizedBox(height: AppSpacing.section),

        // Dynamic Tool Costs Table (Screen 67)
        Text(
          'Tool Costs (Authoritative Backend Rates)',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colors.mutedBackground,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: widget.operations.map((op) {
              return ListTile(
                dense: true,
                title: Text(
                  op.displayName,
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  op.description,
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${op.creditCost} ${op.creditCost == 1 ? 'credit' : 'credits'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.primary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildReservationTab(BuildContext context, AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: const Color(0xFFA15C00).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.hourglass_top, color: Color(0xFFA15C00), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Active Live Lock (In Flight)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFA15C00),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Tool: Resume Optimization\nTask ID: OPT-9812\nAmount: 3 credits reserved\nState: Checking status with background processor...',
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Refresh'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Reservation status refreshed.'),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.help_center, size: 16),
                      label: const Text('Get Help'),
                      onPressed: () {
                        Navigator.pop(context);
                        showBillingSupportModal(
                          context,
                          defaultReference: 'OPT-9812',
                          defaultCategory: 'Reservation stuck',
                        );
                      },
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

  Widget _buildPolicyCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String badge,
    required Color badgeBg,
    required Color badgeFg,
    required String description,
  }) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.mutedBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: colors.primary, size: 20),
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
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: badgeFg,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SCREEN 65: AI CREDITS EDGE STATES & BILLING SUPPORT MODAL
// =============================================================================

void showBillingSupportModal(
  BuildContext context, {
  String? defaultReference,
  String? defaultCategory,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.of(context).cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _BillingSupportModalContent(
        defaultReference: defaultReference,
        defaultCategory: defaultCategory,
      ),
    ),
  );
}

class _BillingSupportModalContent extends ConsumerStatefulWidget {
  const _BillingSupportModalContent({
    this.defaultReference,
    this.defaultCategory,
  });

  final String? defaultReference;
  final String? defaultCategory;

  @override
  ConsumerState<_BillingSupportModalContent> createState() =>
      _BillingSupportModalContentState();
}

class _BillingSupportModalContentState
    extends ConsumerState<_BillingSupportModalContent> {
  late String _category;
  late TextEditingController _subjectController;
  late TextEditingController _messageController;
  late TextEditingController _refController;
  bool _submitting = false;

  final _categories = [
    'Credits charged unexpectedly',
    'Credits not returned',
    'Purchase not added',
    'Reservation stuck',
    'Duplicate charge',
    'Refund question',
    'Expiration question',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _category = widget.defaultCategory ?? _categories.first;
    _refController = TextEditingController(text: widget.defaultReference ?? '');
    _subjectController = TextEditingController(
      text: widget.defaultReference != null
          ? 'Credit issue regarding ${widget.defaultReference}'
          : 'Credit ledger inquiry',
    );
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _refController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    final subject = _subjectController.text.trim();
    if (subject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a subject.')),
      );
      return;
    }
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your issue.')),
      );
      return;
    }

    setState(() => _submitting = true);
    final res = await ref
        .read(aiCreditsProvider.notifier)
        .submitSupportTicket(
          category: _category,
          subject: subject,
          message: message,
          transactionReference: _refController.text.trim(),
          metadata: {
            'product': 'AI Credits',
            'related_task': _refController.text.trim(),
            'date': DateTime.now().toIso8601String(),
          },
        );
    setState(() => _submitting = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res != null
                ? 'Support ticket submitted (ID: ${res['id'] ?? 'created'}). We will get back to you.'
                : 'Ticket submitted.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.support_agent, color: colors.primary),
              ),
              const SizedBox(width: 10),
              Text(
                'Credit & Billing Support',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Category dropdown
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(
              labelText: 'Issue Category',
              border: OutlineInputBorder(),
            ),
            items: _categories.map((c) {
              return DropdownMenuItem(
                value: c,
                child: Text(c, style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _category = val);
            },
          ),
          const SizedBox(height: AppSpacing.sm),

          // Transaction reference
          TextField(
            controller: _refController,
            decoration: const InputDecoration(
              labelText: 'Transaction or Task Reference',
              hintText: 'e.g. OPT-9812 or order ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Subject
          TextField(
            controller: _subjectController,
            decoration: const InputDecoration(
              labelText: 'Subject',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Message
          TextField(
            controller: _messageController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Details',
              hintText:
                  'Describe what happened with your credit balance or payment...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Privacy note
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 16,
                color: colors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Privacy protected: We never ask for or log full card numbers or security codes.',
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Submit button
          AppPrimaryButton(
            label: 'Submit Support Ticket',
            loading: _submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
