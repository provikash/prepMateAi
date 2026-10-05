import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme.dart';
import '../../../ai_credits/presentation/providers/ai_credits_provider.dart';

/// Modal bottom sheet matching Stitch screen 25:
/// AI Assistant — Insufficient Credits Sheet.
///
/// Surfaces tool cost vs user balance transparently, shows next free credit refill date,
/// and allows reviewing credit packs and transaction history.
class InsufficientCreditsSheet extends ConsumerWidget {
  const InsufficientCreditsSheet({
    super.key,
    required this.toolName,
    required this.requiredCredits,
  });

  final String toolName;
  final int requiredCredits;

  static Future<void> show(
    BuildContext context, {
    required String toolName,
    required int requiredCredits,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InsufficientCreditsSheet(
        toolName: toolName,
        requiredCredits: requiredCredits,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final creditState = ref.watch(aiCreditsProvider);
    final available = creditState.account?.availableCredits ?? 0;
    final shortage = (requiredCredits - available).clamp(0, 999);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF121B2E).withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Top Icon Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.toll, size: 30, color: colors.primary),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'You need more AI credits',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'This tool ('),
                  TextSpan(
                    text: toolName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  TextSpan(text: ') uses '),
                  TextSpan(
                    text: '$requiredCredits credits',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                  const TextSpan(text: '. You currently have '),
                  TextSpan(
                    text: '$available available',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors.error,
                    ),
                  ),
                  TextSpan(text: ' (need $shortage more).'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Free renewal banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.screenBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colors.secondarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.event_repeat,
                    size: 18,
                    color: colors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Free renewal: complimentary monthly credits refill on the 1st of next month.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Primary Action: View Credit Options
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push('/resume/ai/credits');
              },
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.bolt, size: 20),
              label: const Text(
                'View credit options',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Secondary Action: Not now
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: colors.textSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Not now',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // See credit activity history link
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              context.push('/resume/ai/transactions');
            },
            icon: Icon(Icons.receipt_long, size: 16, color: colors.primary),
            label: Text(
              'See credit activity history',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
