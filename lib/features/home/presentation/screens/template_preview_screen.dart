import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme.dart';
import '../../data/models/template_model.dart';
import '../widgets/template_sample_preview.dart';

class TemplatePreviewScreen extends ConsumerStatefulWidget {
  const TemplatePreviewScreen({super.key, this.template});

  final TemplateModel? template;

  @override
  ConsumerState<TemplatePreviewScreen> createState() =>
      _TemplatePreviewScreenState();
}

class _TemplatePreviewScreenState extends ConsumerState<TemplatePreviewScreen> {
  bool _isCreating = false;

  void _useTemplate() {
    if (_isCreating) return;
    setState(() => _isCreating = true);
    context.push('/resume/form', extra: widget.template?.id ?? 'professional');
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final template = widget.template;
    final title = template?.title ?? 'Professional';
    final category = template?.category ?? 'Professional';
    final previewUrl = template?.thumbnailUrl.trim() ?? '';

    return Scaffold(
      backgroundColor: colors.screenBackground,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Template Preview'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'This is the actual rendered $title template with sample resume data.',
                      style: TextStyle(
                        color: colors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _badge(
                          colors,
                          icon: Icons.auto_awesome,
                          label: category,
                        ),
                        _badge(
                          colors,
                          icon: Icons.picture_as_pdf_outlined,
                          label: 'A4 layout',
                        ),
                        _badge(
                          colors,
                          icon: Icons.zoom_in,
                          label: 'Pinch to zoom',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.border),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: AspectRatio(
                        aspectRatio: 210 / 297,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: previewUrl.isEmpty
                              ? TemplateSamplePreview(
                                  templateId:
                                      template?.id ?? 'offline-professional',
                                )
                              : InteractiveViewer(
                                  minScale: 1,
                                  maxScale: 4,
                                  child: CachedNetworkImage(
                                    imageUrl: previewUrl,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.contain,
                                    alignment: Alignment.topCenter,
                                    placeholder: (_, _) => Center(
                                      child: CircularProgressIndicator(
                                        color: colors.primary,
                                      ),
                                    ),
                                    errorWidget: (_, _, _) =>
                                        TemplateSamplePreview(
                                          templateId:
                                              template?.id ??
                                              'offline-professional',
                                        ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isCreating ? null : _useTemplate,
                  icon: _isCreating
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward),
                  label: const Text('Use this template'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(
    AppColors colors, {
    required IconData icon,
    required String label,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: colors.primarySoft,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: colors.primary),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: colors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
