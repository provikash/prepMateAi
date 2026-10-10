import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../auth/presentation/state/auth_state.dart';
import '../../auth/presentation/viewmodel/auth_viewmodel.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  Timer? _statusTimer;
  int _currentStatusIndex = 0;
  bool _hasError = false;
  String? _errorMessage;

  final List<Map<String, dynamic>> _stages = const [
    {'text': 'Opening your career workspace…', 'progress': 0.35},
    {'text': 'Loading your profile…', 'progress': 0.68},
    {'text': 'Getting your resume tools ready…', 'progress': 0.95},
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.82,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    _statusTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (mounted) {
        setState(() {
          _currentStatusIndex = (_currentStatusIndex + 1) % _stages.length;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSessionCheck();
    });
  }

  Future<void> _startSessionCheck() async {
    setState(() {
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final startTime = DateTime.now();
      await ref.read(authProvider.notifier).bootstrapSession();

      final elapsed = DateTime.now().difference(startTime);
      final minDuration = const Duration(milliseconds: 1600);
      if (elapsed < minDuration) {
        await Future.delayed(minDuration - elapsed);
      }

      if (!mounted) return;

      final authState = ref.read(authProvider);
      if (authState.status == AuthStatus.authenticated) {
        final user = authState.user;
        if (user != null &&
            (user.onboardingCompleted || user.profileCompleted)) {
          context.go('/home');
        } else {
          // Route to first incomplete onboarding step
          final step = user?.onboardingStep ?? 0;
          if (step <= 0) {
            context.go('/onboarding/welcome');
          } else if (step == 1) {
            context.go('/onboarding/career-progress');
          } else if (step == 2) {
            context.go('/onboarding/profile');
          } else if (step == 3) {
            context.go('/onboarding/experience');
          } else if (step == 4) {
            context.go('/onboarding/goals');
          } else {
            context.go('/onboarding/complete');
          }
        }
      } else {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Could not restore your account. Opening offline.';
        });
        context.go('/dashboard');
      }
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final stage = _stages[_currentStatusIndex];

    return Scaffold(
      backgroundColor: colors.screenBackground,
      body: Stack(
        children: [
          // Ambient organic aura & career rings
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _AmbientAuraPainter(
                  primaryColor: colors.primary,
                  secondaryColor: colors.secondary,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 96x96 Brand Mark Container with Sparkle Pill
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    color: colors.surface,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF172033,
                                        ).withValues(alpha: 0.08),
                                        blurRadius: 24,
                                        offset: const Offset(0, 8),
                                      ),
                                      BoxShadow(
                                        color: colors.primary.withValues(
                                          alpha: 0.12,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: const AppLogo(size: 72),
                                ),
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: colors.surface,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.08,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.auto_awesome,
                                      size: 14,
                                      color: colors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Title with AI badge
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'PrepMate',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: colors.textPrimary,
                                        letterSpacing: -0.5,
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
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'AI',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: colors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Build smarter. Apply stronger.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: 16),

                            // Skill/domain pills
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildDomainTag('Resume', colors),
                                _buildDot(colors),
                                _buildDomainTag('Mock Interview', colors),
                                _buildDot(colors),
                                _buildDomainTag('AI Coach', colors),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Reassurance & Loader or Error Area
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_hasError) ...[
                        Text(
                          _errorMessage ?? 'Connection timeout',
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.error,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _startSessionCheck,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Retry connection'),
                        ),
                      ] else ...[
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            backgroundColor: colors.primarySoft,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            stage['text'] as String,
                            key: ValueKey<String>(stage['text'] as String),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: colors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Mini progress bar
                        Container(
                          width: 128,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colors.primarySoft,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          alignment: Alignment.centerLeft,
                          child: AnimatedFractionallySizedBox(
                            duration: const Duration(milliseconds: 600),
                            widthFactor: stage['progress'] as double,
                            child: Container(
                              decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Trust badge
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_user,
                            size: 15,
                            color: colors.secondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Preparing your private workspace',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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

  Widget _buildDomainTag(String label, AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: colors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDot(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(color: colors.border, shape: BoxShape.circle),
      ),
    );
  }
}

class _AmbientAuraPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  _AmbientAuraPainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);

    final auraPaint1 = Paint()
      ..color = primaryColor.withValues(alpha: 0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);
    canvas.drawCircle(center.translate(0, -30), 160, auraPaint1);

    final auraPaint2 = Paint()
      ..color = secondaryColor.withValues(alpha: 0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
    canvas.drawCircle(center.translate(40, 40), 110, auraPaint2);

    // Subtle concentric trajectory rings
    final ringPaint1 = Paint()
      ..color = primaryColor.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, 120, ringPaint1);

    final ringPaint2 = Paint()
      ..color = primaryColor.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, 170, ringPaint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
