import '../../domain/entities/ai_credit_models.dart';
import '../../domain/repositories/ai_credits_repository.dart';

class MockAiCreditsRepository implements AiCreditsRepository {
  const MockAiCreditsRepository({
    this.delay = const Duration(milliseconds: 220),
  });
  final Duration delay;

  Future<void> _wait() => Future<void>.delayed(delay);

  @override
  Future<AiCreditAccount> getCreditAccount() async {
    await _wait();
    return AiCreditAccount(
      balance: 42,
      monthlyAllocation: 100,
      usedThisCycle: 58,
      lifetimeEarned: 620,
      lifetimeUsed: 578,
      resetDate: DateTime.now().add(const Duration(days: 12)),
    );
  }

  @override
  Future<List<AiOperation>> getOperations() async {
    await _wait();
    return const [
      AiOperation(
        operation: 'summary',
        displayName: 'Resume Summary',
        description: 'Generate a concise professional summary',
        creditCost: 2,
      ),
      AiOperation(
        operation: 'improve_bullet',
        displayName: 'Improve Bullet',
        description: 'Rewrite one achievement bullet',
        creditCost: 1,
      ),
      AiOperation(
        operation: 'skills',
        displayName: 'Skill Suggestions',
        description: 'Find relevant skills to consider',
        creditCost: 1,
      ),
      AiOperation(
        operation: 'ats',
        displayName: 'ATS Analysis',
        description: 'Review structure and ATS readiness',
        creditCost: 5,
      ),
      AiOperation(
        operation: 'jd_optimization',
        displayName: 'JD Optimization',
        description: 'Tailor a resume to a job description',
        creditCost: 10,
      ),
      AiOperation(
        operation: 'cover_letter',
        displayName: 'Cover Letter',
        description: 'Draft a targeted cover letter',
        creditCost: 5,
      ),
      AiOperation(
        operation: 'interview',
        displayName: 'Interview Questions',
        description: 'Create role-specific practice questions',
        creditCost: 5,
      ),
    ];
  }

  @override
  Future<List<SubscriptionPlan>> getPlans() async {
    await _wait();
    return const [
      SubscriptionPlan(
        id: 'free',
        name: 'Free Tier',
        slug: 'free',
        monthlyPrice: 0,
        annualPrice: 0,
        currency: 'INR',
        monthlyAiCredits: 30,
        features: [
          'Unlimited resume builder and editor',
          'All resume templates',
          'Standard PDF downloads',
          '30 AI credits each month',
        ],
      ),
      SubscriptionPlan(
        id: 'pro',
        name: 'Pro Plan',
        slug: 'pro',
        monthlyPrice: 99,
        annualPrice: 950,
        currency: 'INR',
        monthlyAiCredits: 500,
        features: [
          'Everything in Free',
          '500 AI credits each month',
          'Deep job description optimization',
          'Full ATS scoring and keyword diagnostics',
          'Cover letters and interview questions',
        ],
        isRecommended: true,
      ),
    ];
  }

  @override
  Future<UserSubscription?> getCurrentSubscription() async {
    await _wait();
    return UserSubscription(
      planId: 'free',
      status: 'active',
      startedAt: DateTime.now().subtract(const Duration(days: 20)),
    );
  }

  @override
  Future<List<AiCreditTransaction>> getTransactions() async {
    await _wait();
    final now = DateTime.now();
    return [
      AiCreditTransaction(
        id: 'tx-1',
        type: CreditTransactionType.usage,
        amount: -10,
        operation: 'jd_optimization',
        description: 'JD Resume Optimization',
        createdAt: now.subtract(const Duration(hours: 2)),
        status: CreditTransactionStatus.completed,
        balanceBefore: 52,
        balanceAfter: 42,
      ),
      AiCreditTransaction(
        id: 'tx-2',
        type: CreditTransactionType.usage,
        amount: -5,
        operation: 'ats',
        description: 'ATS Analysis',
        createdAt: now.subtract(const Duration(days: 2)),
        status: CreditTransactionStatus.completed,
        balanceBefore: 57,
        balanceAfter: 52,
      ),
      AiCreditTransaction(
        id: 'tx-3',
        type: CreditTransactionType.grant,
        amount: 100,
        description: 'Monthly Credit Grant',
        createdAt: now.subtract(const Duration(days: 18)),
        status: CreditTransactionStatus.completed,
        balanceBefore: 0,
        balanceAfter: 100,
      ),
    ];
  }

  @override
  Future<void> refresh() => _wait();
}
