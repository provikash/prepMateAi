import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../auth/presentation/viewmodel/auth_viewmodel.dart';
import '../../data/models/template_model.dart';

class TemplatePreviewScreen extends ConsumerStatefulWidget {
  final TemplateModel? template;

  const TemplatePreviewScreen({super.key, this.template});

  @override
  ConsumerState<TemplatePreviewScreen> createState() =>
      _TemplatePreviewScreenState();
}

class _TemplatePreviewScreenState extends ConsumerState<TemplatePreviewScreen> {
  bool _isCreating = false;

  void _useTemplate() {
    if (_isCreating) return;
    setState(() => _isCreating = true);

    final templateId = widget.template?.id ?? 'professional';
    context.push('/resume/form', extra: templateId);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final user = ref.watch(authViewModelProvider).user;
    final template = widget.template;
    final title = template?.title ?? 'Professional';
    final category = template?.category ?? 'Standard';

    final userName = (user?.fullName?.trim().isNotEmpty ?? false)
        ? user!.fullName!.trim()
        : 'Alex Morgan';
    final userTitle = (user?.professionalTitle?.trim().isNotEmpty ?? false)
        ? user!.professionalTitle!.trim()
        : 'Aspiring Software Engineer & Mobile Developer';
    final userLocation = (user?.location?.trim().isNotEmpty ?? false)
        ? user!.location!.trim()
        : 'Bengaluru, IN';
    final userEmail = (user != null && user.email.trim().isNotEmpty)
        ? user.email.trim()
        : 'alex.morgan@email.com';

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
          'Template Preview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top sub-bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.secondarySoft,
                            borderRadius: BorderRadius.circular(16),
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
                                'AI Recommendation Match',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.fullscreen,
                                size: 16,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'A4 Preview',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Template Identity Header
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Clean, versatile, and easy to scan for recruiters.',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Badges row
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildBadge(
                          colors.surfaceContainer,
                          colors.textSecondary,
                          Icons.category_outlined,
                          category,
                        ),
                        _buildBadge(
                          colors.secondarySoft,
                          colors.secondary,
                          Icons.verified,
                          'Free Forever',
                        ),
                        _buildBadge(
                          colors.primarySoft,
                          colors.primary,
                          Icons.auto_awesome,
                          'Recommended',
                        ),
                        _buildBadge(
                          colors.surfaceContainer,
                          colors.textSecondary,
                          Icons.speed,
                          '98% ATS Score',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Contextual recommendation banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 18,
                            color: colors.secondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recommended because you’re building a technical resume.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Optimized single-column visual hierarchy for clear recruiter readability.',
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
                    const SizedBox(height: 18),

                    // The Hero A4 Canvas Sheet
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF172033,
                            ).withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: colors.border),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top accent line
                          Container(
                            height: 4,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Header Info
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  userName.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.secondarySoft,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'FRESHER',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: colors.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userTitle,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$userLocation  •  $userEmail  •  github.com/alex-dev',
                            style: TextStyle(
                              fontSize: 10,
                              color: colors.textSecondary,
                            ),
                          ),
                          const Divider(height: 20),

                          // Professional Summary
                          Text(
                            'PROFESSIONAL SUMMARY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Passionate Computer Science graduate with hands-on project experience in Flutter, Dart, and Python. Proven track record building cross-platform mobile apps with responsive UIs and robust REST API integrations.',
                            style: TextStyle(
                              fontSize: 10,
                              height: 1.4,
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Education
                          Text(
                            'EDUCATION',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'B.Tech in Computer Science & Engineering',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'CGPA: 8.7 / 10',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: colors.secondary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'National Institute of Technology • 2021 – 2025',
                            style: TextStyle(
                              fontSize: 9,
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Featured Projects
                          Text(
                            'FEATURED PROJECTS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'PrepMate AI Companion App',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '• Architected responsive UI across 14+ screens implementing Material 3 guidelines and local SQLite offline sync.',
                            style: TextStyle(
                              fontSize: 9,
                              height: 1.35,
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Technical Skills
                          Text(
                            'TECHNICAL SKILLS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dart, Flutter, Python, Django, REST APIs, Git, PostgreSQL',
                            style: TextStyle(
                              fontSize: 9,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Sticky Bottom CTA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isCreating ? null : _useTemplate,
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text(
                    'Use this template',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(Color bg, Color textCol, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textCol),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textCol,
            ),
          ),
        ],
      ),
    );
  }
}
