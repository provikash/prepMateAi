import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/ai_credit_models.dart';
import '../providers/ai_credits_provider.dart';

enum CreditActivityFilter {
  all('All'),
  used('Used'),
  added('Added'),
  reserved('Reserved'),
  returned('Returned'),
  purchases('Purchases'),
  attention('Needs attention');

  const CreditActivityFilter(this.label);
  final String label;
}

class AiTransactionsScreen extends ConsumerStatefulWidget {
  const AiTransactionsScreen({super.key});

  @override
  ConsumerState<AiTransactionsScreen> createState() =>
      _AiTransactionsScreenState();
}

class _AiTransactionsScreenState extends ConsumerState<AiTransactionsScreen>
    with SingleTickerProviderStateMixin {
  CreditActivityFilter _activeFilter = CreditActivityFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  late AnimationController _refreshAnimController;

  @override
  void initState() {
    super.initState();
    _refreshAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    Future.microtask(() {
      ref.read(aiCreditsProvider.notifier).load();
      _fetchTransactions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshAnimController.dispose();
    super.dispose();
  }

  void _fetchTransactions() {
    final filterParam = switch (_activeFilter) {
      CreditActivityFilter.all => null,
      CreditActivityFilter.used => 'used',
      CreditActivityFilter.added => 'added',
      CreditActivityFilter.reserved => 'reserved',
      CreditActivityFilter.returned => 'returned',
      CreditActivityFilter.purchases => 'purchases',
      CreditActivityFilter.attention => 'attention',
    };
    ref
        .read(aiCreditsProvider.notifier)
        .loadTransactions(
          filter: filterParam,
          query: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
        );
  }

  Future<void> _handleRefresh() async {
    _refreshAnimController.forward(from: 0.0);
    await ref.read(aiCreditsProvider.notifier).refresh();
    _fetchTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiCreditsProvider);
    final account = state.account;
    final transactions = state.transactions;

    final filteredList = transactions.where((item) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      final desc = item.description.toLowerCase();
      final op = (item.operation ?? '').toLowerCase();
      final refId = (item.reference ?? item.id).toLowerCase();
      final source = (item.creditSource ?? '').toLowerCase();
      return desc.contains(q) ||
          op.contains(q) ||
          refId.contains(q) ||
          source.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9FF),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leadingWidth: 100,
        leading: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => context.pop(),
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back, color: Color(0xFF172033)),
                const SizedBox(width: 4),
                Text(
                  'Credits',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF667085),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        title: Text(
          'Credit Activity',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xFF172033),
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: const Color(0xFF172033),
            ),
            tooltip: 'Search transactions',
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                  _fetchTransactions();
                }
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF172033)),
            tooltip: 'More options',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (val) {
              if (val == 'plans') {
                context.push('/ai-plans');
              } else if (val == 'help') {
                context.push('/help');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'plans',
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 20,
                      color: Color(0xFF2457D6),
                    ),
                    SizedBox(width: 12),
                    Text('Plans and Credit Packs'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'help',
                child: Row(
                  children: [
                    Icon(
                      Icons.help_outline_rounded,
                      size: 20,
                      color: Color(0xFF667085),
                    ),
                    SizedBox(width: 12),
                    Text('Billing Support'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: Column(
            children: [
              // Balance summary strip & search
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    _buildBalanceSummaryStrip(account),
                    if (_isSearching) ...[
                      const SizedBox(height: 12),
                      _buildSearchBar(),
                    ],
                    const SizedBox(height: 12),
                    _buildFilterChips(transactions),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE9EDFF)),

              // Transactions list
              Expanded(
                child: state.isLoading && transactions.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2457D6),
                        ),
                      )
                    : filteredList.isEmpty
                    ? _buildEmptyState()
                    : _buildGroupedTransactionList(filteredList),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceSummaryStrip(AiCreditAccount? account) {
    final available = account?.availableCredits ?? 0;
    final reserved = account?.reservedCredits ?? 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF172033).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFDDE2EA)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF168653),
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$available available',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF172033),
                                ),
                              ),
                            ],
                          ),
                          if (reserved > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE9EFFF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2457D6),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '$reserved reserved',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2457D6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Text(
                            'Updated just now',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF667085),
                            ),
                          ),
                          Text(
                            ' • ',
                            style: TextStyle(color: Color(0xFF667085)),
                          ),
                          Text(
                            'Server-authoritative ledger',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF667085),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                RotationTransition(
                  turns: Tween(
                    begin: 0.0,
                    end: 1.0,
                  ).animate(_refreshAnimController),
                  child: IconButton(
                    icon: const Icon(
                      Icons.sync_rounded,
                      color: Color(0xFF2457D6),
                    ),
                    tooltip: 'Refresh ledger balance',
                    onPressed: _handleRefresh,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF7F8FB),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Color(0xFF667085)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Current account balance • Does not change with filters',
                    style: TextStyle(fontSize: 11, color: Color(0xFF667085)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE2EA)),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search tool, session, pack, or description',
          hintStyle: const TextStyle(color: Color(0xFF667085), fontSize: 13),
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
            color: Color(0xFF667085),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    _fetchTransactions();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (val) {
          setState(() => _searchQuery = val);
        },
        onSubmitted: (_) => _fetchTransactions(),
      ),
    );
  }

  Widget _buildFilterChips(List<AiCreditTransaction> allTransactions) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: CreditActivityFilter.values.map((filter) {
          final isSelected = _activeFilter == filter;
          int count = 0;
          if (filter == CreditActivityFilter.used) {
            count = allTransactions
                .where((t) => t.type == CreditTransactionType.usage)
                .length;
          } else if (filter == CreditActivityFilter.reserved) {
            count = allTransactions
                .where((t) => t.type == CreditTransactionType.reservation)
                .length;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              selected: isSelected,
              showCheckmark: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(filter.label),
                  if (count > 0 && !isSelected) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDE2EA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              selectedColor: const Color(0xFF2457D6),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF172033),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
              checkmarkColor: Colors.white,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF2457D6)
                      : const Color(0xFFDDE2EA),
                ),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _activeFilter = filter);
                  _fetchTransactions();
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGroupedTransactionList(List<AiCreditTransaction> list) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisMonthStart = DateTime(now.year, now.month, 1);

    final todayItems = <AiCreditTransaction>[];
    final yesterdayItems = <AiCreditTransaction>[];
    final thisMonthItems = <AiCreditTransaction>[];
    final earlierItems = <AiCreditTransaction>[];

    for (final tx in list) {
      final txDate = DateTime(
        tx.createdAt.year,
        tx.createdAt.month,
        tx.createdAt.day,
      );
      if (txDate.isAtSameMomentAs(today)) {
        todayItems.add(tx);
      } else if (txDate.isAtSameMomentAs(yesterday)) {
        yesterdayItems.add(tx);
      } else if (txDate.isAfter(thisMonthStart) ||
          txDate.isAtSameMomentAs(thisMonthStart)) {
        thisMonthItems.add(tx);
      } else {
        earlierItems.add(tx);
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        if (todayItems.isNotEmpty)
          _buildDateGroup(
            'Today · ${DateFormat('d MMM yyyy').format(now)}',
            todayItems,
          ),
        if (yesterdayItems.isNotEmpty)
          _buildDateGroup('Yesterday', yesterdayItems),
        if (thisMonthItems.isNotEmpty)
          _buildDateGroup('This Month', thisMonthItems),
        if (earlierItems.isNotEmpty)
          _buildDateGroup('Earlier Activity', earlierItems),
      ],
    );
  }

  Widget _buildDateGroup(String title, List<AiCreditTransaction> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF172033),
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                '${items.length} ${items.length == 1 ? 'activity' : 'activities'}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
              ),
            ],
          ),
        ),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFDDE2EA)),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFE9EDFF), indent: 56),
            itemBuilder: (context, index) {
              final tx = items[index];
              return _buildTransactionRow(tx);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionRow(AiCreditTransaction tx) {
    final (icon, iconColor, iconBg) = _getTransactionVisuals(tx.type);
    final (amountText, amountColor) = _getSemanticAmount(tx);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showTransactionDetailSheet(context, tx),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.description,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF172033),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        tx.creditSource ?? 'AI Ledger',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF667085),
                        ),
                      ),
                      const Text(
                        ' · ',
                        style: TextStyle(color: Color(0xFF667085)),
                      ),
                      Text(
                        DateFormat('h:mm a').format(tx.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF667085),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildStatusPill(tx.status),
                      if (tx.balanceAfter != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FB),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFDDE2EA)),
                          ),
                          child: Text(
                            '${tx.balanceAfter} balance',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF667085),
                            ),
                          ),
                        ),
                      Text(
                        tx.reference ??
                            'REF-${tx.id.substring(0, tx.id.length.clamp(0, 8)).toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF667085),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              amountText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color, Color) _getTransactionVisuals(CreditTransactionType type) {
    switch (type) {
      case CreditTransactionType.purchase:
        return (
          Icons.shopping_bag_outlined,
          const Color(0xFF168653),
          const Color(0xFFE8F5E9),
        );
      case CreditTransactionType.grant:
        return (
          Icons.stars_rounded,
          const Color(0xFF2457D6),
          const Color(0xFFE9EFFF),
        );
      case CreditTransactionType.reservation:
        return (
          Icons.hourglass_top_rounded,
          const Color(0xFF087E78),
          const Color(0xFFE1F4F1),
        );
      case CreditTransactionType.release:
        return (
          Icons.replay_rounded,
          const Color(0xFF087E78),
          const Color(0xFFE1F4F1),
        );
      case CreditTransactionType.usage:
        return (
          Icons.auto_awesome,
          const Color(0xFF172033),
          const Color(0xFFF0F2F5),
        );
      case CreditTransactionType.refund:
        return (
          Icons.currency_exchange_rounded,
          const Color(0xFF168653),
          const Color(0xFFE8F5E9),
        );
      case CreditTransactionType.expiration:
        return (
          Icons.timer_off_outlined,
          const Color(0xFFB42318),
          const Color(0xFFFEE4E2),
        );
      case CreditTransactionType.adjustment:
        return (
          Icons.tune_rounded,
          const Color(0xFF2457D6),
          const Color(0xFFE9EFFF),
        );
    }
  }

  (String, Color) _getSemanticAmount(AiCreditTransaction tx) {
    final amt = tx.amount;
    switch (tx.type) {
      case CreditTransactionType.grant:
      case CreditTransactionType.purchase:
      case CreditTransactionType.refund:
        return ('+$amt credits', const Color(0xFF168653));
      case CreditTransactionType.usage:
        return ('−$amt credits', const Color(0xFF172033));
      case CreditTransactionType.reservation:
        return ('$amt reserved', const Color(0xFF087E78));
      case CreditTransactionType.release:
        return ('$amt released', const Color(0xFF087E78));
      case CreditTransactionType.expiration:
        return ('−$amt expired', const Color(0xFFB42318));
      case CreditTransactionType.adjustment:
        return (
          amt >= 0 ? '+$amt credits' : '−${amt.abs()} credits',
          const Color(0xFF2457D6),
        );
    }
  }

  Widget _buildStatusPill(CreditTransactionStatus status) {
    final (label, bg, fg) = switch (status) {
      CreditTransactionStatus.completed => (
        'Completed',
        const Color(0xFFE8F5E9),
        const Color(0xFF168653),
      ),
      CreditTransactionStatus.pending => (
        'Pending',
        const Color(0xFFFEF3F2),
        const Color(0xFFA15C00),
      ),
      CreditTransactionStatus.failed => (
        'Failed',
        const Color(0xFFFEE4E2),
        const Color(0xFFB42318),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFE9EFFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 32,
                color: Color(0xFF2457D6),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No matching transactions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF172033),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Activity will appear as you generate content or purchase credit packs.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF667085)),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _activeFilter = CreditActivityFilter.all;
                  _searchController.clear();
                  _searchQuery = '';
                });
                _fetchTransactions();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2457D6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Reset filters'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetailSheet(
    BuildContext context,
    AiCreditTransaction tx,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TransactionDetailSheet(transaction: tx),
    );
  }
}

class _TransactionDetailSheet extends ConsumerWidget {
  const _TransactionDetailSheet({required this.transaction});
  final AiCreditTransaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refCode =
        transaction.reference ??
        'REF-${transaction.id.substring(0, transaction.id.length.clamp(0, 8)).toUpperCase()}';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE2EA),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transaction Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF172033),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDDE2EA)),
            ),
            child: Column(
              children: [
                _buildDetailRow('Description', transaction.description),
                const Divider(height: 16, color: Color(0xFFE9EDFF)),
                _buildDetailRow('Public Reference', refCode, isMonospace: true),
                const Divider(height: 16, color: Color(0xFFE9EDFF)),
                _buildDetailRow('Type', transaction.type.name.toUpperCase()),
                const Divider(height: 16, color: Color(0xFFE9EDFF)),
                _buildDetailRow(
                  'Amount Effect',
                  '${transaction.amount} credits',
                ),
                if (transaction.balanceAfter != null) ...[
                  const Divider(height: 16, color: Color(0xFFE9EDFF)),
                  _buildDetailRow(
                    'Balance After',
                    '${transaction.balanceAfter} credits',
                  ),
                ],
                const Divider(height: 16, color: Color(0xFFE9EDFF)),
                _buildDetailRow(
                  'Date & Time',
                  DateFormat(
                    'd MMMM yyyy, h:mm:ss a',
                  ).format(transaction.createdAt),
                ),
                if (transaction.creditSource != null) ...[
                  const Divider(height: 16, color: Color(0xFFE9EDFF)),
                  _buildDetailRow('Credit Source', transaction.creditSource!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (transaction.receiptAvailable)
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: const Text('View Receipt'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      final receipt = await ref
                          .read(aiCreditsProvider.notifier)
                          .getOrderReceipt(transaction.id);
                      if (context.mounted && receipt != null) {
                        _showReceiptDialog(context, receipt);
                      }
                    },
                  ),
                ),
              if (transaction.receiptAvailable) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.support_agent_outlined, size: 18),
                  label: const Text('Get Help'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2457D6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/help');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isMonospace = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF667085)),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF172033),
              fontFamily: isMonospace ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }

  void _showReceiptDialog(BuildContext context, OrderReceipt receipt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.receipt_rounded, color: Color(0xFF2457D6)),
            const SizedBox(width: 8),
            Text(
              receipt.receiptNumber,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product: ${receipt.productName}'),
            const SizedBox(height: 4),
            Text('Credits added: ${receipt.credits}'),
            const SizedBox(height: 4),
            Text(
              'Amount: ${receipt.currency} ${receipt.amount.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 4),
            Text('Customer: ${receipt.customerName}'),
            const SizedBox(height: 4),
            Text('Provider: ${receipt.billingProvider}'),
            const SizedBox(height: 4),
            Text(
              'Date: ${DateFormat('d MMM yyyy, h:mm a').format(receipt.createdAt)}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
