import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../home/data/models/resume_model.dart';

/// Screen 48: Optimization Setup Bottom Sheets & Recovery Modals
///
/// Includes:
/// 1. HowOptimizationWorksSheet (5-stage integrity pipeline, escrow credit explanation, privacy pledge)
/// 2. SelectResumeModalSheet (Select from saved resumes or upload new file)
/// 3. DuplicateOptimizationAlertModal (Warning when resume was recently optimized for the same target)
/// 4. FileUploadErrorModal (Oversized >10MB, unsupported format recovery)

class HowOptimizationWorksSheet extends StatelessWidget {
  const HowOptimizationWorksSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const HowOptimizationWorksSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'AI ASSISTANT ENGINE',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'How Resume Optimization Works',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Transparent, privacy-first career alignment',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // 5-Stage Pipeline Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.screenBackground,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '5-STAGE INTEGRITY PIPELINE',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildPipelineStep(
                          context,
                          step: '1',
                          title: 'Select a saved resume',
                          desc:
                              'Your original resume is locked as an immutable baseline snapshot and never overwritten.',
                        ),
                        _buildPipelineStep(
                          context,
                          step: '2',
                          title: 'Provide target job description',
                          desc:
                              'Paste complete job text or import a link. Text is parsed for core responsibilities and technical taxonomy.',
                        ),
                        _buildPipelineStep(
                          context,
                          step: '3',
                          title: 'AI scans rubric & alignment',
                          desc:
                              'Identifies strong evidence, partial evidence, and potential qualification gaps.',
                        ),
                        _buildPipelineStep(
                          context,
                          step: '4',
                          title: 'Synthesize tailored bullet proposals',
                          desc:
                              'Generates grounded bullet improvements tailored to the role, never fabricating facts or metrics.',
                        ),
                        _buildPipelineStep(
                          context,
                          step: '5',
                          title: 'User inspection & acceptance',
                          desc:
                              'Every proposal requires individual user review and confirmation before applying to the optimized draft.',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Escrow Credit Policy
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1F4F1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: const Color(0xFF087E78).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          color: Color(0xFF087E78),
                          size: 22,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Credit Escrow & Protection',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF087E78),
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Credits are securely reserved during generation. If analysis or synthesis fails due to a network or server timeout, reserved credits are immediately returned to your account balance.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: const Color(0xFF172033)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Privacy Pledge
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          color: colors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Data Privacy & Ethics',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Your career details are never used to train global public models. You retain complete ownership of all generated content.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: colors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Got it, continue setup',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPipelineStep(
    BuildContext context, {
    required String step,
    required String title,
    required String desc,
    bool isLast = false,
  }) {
    final colors = AppColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  step,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 44,
                color: colors.border,
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SelectResumeModalSheet extends StatelessWidget {
  const SelectResumeModalSheet({
    super.key,
    required this.resumes,
    required this.selectedResumeId,
    required this.onSelect,
    required this.onUploadRequested,
  });

  final List<ResumeModel> resumes;
  final String? selectedResumeId;
  final ValueChanged<ResumeModel> onSelect;
  final VoidCallback onUploadRequested;

  static Future<void> show(
    BuildContext context, {
    required List<ResumeModel> resumes,
    required String? selectedResumeId,
    required ValueChanged<ResumeModel> onSelect,
    required VoidCallback onUploadRequested,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SelectResumeModalSheet(
        resumes: resumes,
        selectedResumeId: selectedResumeId,
        onSelect: onSelect,
        onUploadRequested: onUploadRequested,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Resume',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Choose an existing baseline or upload a document',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
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
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // Upload Card
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      onUploadRequested();
                    },
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colors.primary,
                          style: BorderStyle.solid,
                        ),
                        color: colors.primarySoft.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.upload_file,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Upload New Document',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        color: colors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  'PDF or DOCX · Max 10MB',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: colors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: colors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Saved Resumes (${resumes.length})',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (resumes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Center(
                        child: Text(
                          'No saved resumes found. Upload one to start.',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ...resumes.map((resume) {
                      final isSelected = resume.id == selectedResumeId;
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isSelected ? colors.primary : colors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Material(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: ListTile(
                            leading: Icon(
                              Icons.article,
                              color: isSelected
                                  ? colors.primary
                                  : colors.textSecondary,
                              size: 28,
                            ),
                            title: Text(
                              resume.title,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              'Saved · Complete sections ready for analysis',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: colors.primary,
                                  )
                                : null,
                            onTap: () {
                              onSelect(resume);
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DuplicateOptimizationAlertModal extends StatelessWidget {
  const DuplicateOptimizationAlertModal({
    super.key,
    required this.jobTitle,
    required this.company,
    required this.onContinueNew,
    required this.onViewExisting,
  });

  final String jobTitle;
  final String company;
  final VoidCallback onContinueNew;
  final VoidCallback onViewExisting;

  static Future<void> show(
    BuildContext context, {
    required String jobTitle,
    required String company,
    required VoidCallback onContinueNew,
    required VoidCallback onViewExisting,
  }) {
    return showDialog(
      context: context,
      builder: (_) => DuplicateOptimizationAlertModal(
        jobTitle: jobTitle,
        company: company,
        onContinueNew: onContinueNew,
        onViewExisting: onViewExisting,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_edu,
              color: Color(0xFFA15C00),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('Previous Analysis Found')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You previously optimized this resume for $jobTitle at $company.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Starting a new analysis will create a separate session without consuming extra credits for previously reviewed suggestions.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onViewExisting();
          },
          child: const Text('View Existing Result'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            onContinueNew();
          },
          child: const Text('Start New Analysis'),
        ),
      ],
    );
  }
}

class FileUploadErrorModal extends StatelessWidget {
  const FileUploadErrorModal({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) {
    return showDialog(
      context: context,
      builder: (_) => FileUploadErrorModal(
        title: title,
        message: message,
        onRetry: onRetry,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFFDAD6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              color: Color(0xFFBA1A1A),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Dismiss'),
        ),
        if (onRetry != null)
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onRetry!();
            },
            child: const Text('Choose Another File'),
          ),
      ],
    );
  }
}
