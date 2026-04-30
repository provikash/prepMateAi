import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/form_provider.dart';
import '../../../../config/theme.dart';
import 'resume_widgets.dart';

class BasicInfoSection extends ConsumerStatefulWidget {
  const BasicInfoSection({super.key});

  @override
  ConsumerState<BasicInfoSection> createState() => _BasicInfoSectionState();
}

class _BasicInfoSectionState extends ConsumerState<BasicInfoSection> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    final basics = ref.read(resumeFormProvider).basics;
    _nameController = TextEditingController(
      text: basics['name']?.toString() ?? '',
    );
    _emailController = TextEditingController(
      text: basics['email']?.toString() ?? '',
    );
    _phoneController = TextEditingController(
      text: basics['phone']?.toString() ?? '',
    );
    _labelController = TextEditingController(
      text: basics['label']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(resumeFormProvider);
    ref.listen(resumeFormProvider, (previous, next) {
      final currentBasics = next.basics;
      _syncController(_nameController, currentBasics['name']);
      _syncController(_emailController, currentBasics['email']);
      _syncController(_phoneController, currentBasics['phone']);
      _syncController(_labelController, currentBasics['label']);
    });

    return SectionCard(
      title: 'Basic Information',
      icon: Icons.person_outline,
      child: Column(
        children: [
          _Field(
            controller: _nameController,
            label: 'Full Name',
            onChanged: (value) => ref
                .read(resumeFormProvider.notifier)
                .updateBasicField('name', value),
          ),
          _Field(
            controller: _labelController,
            label: 'Role / Title',
            onChanged: (value) => ref
                .read(resumeFormProvider.notifier)
                .updateBasicField('label', value),
          ),
          _Field(
            controller: _emailController,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) => ref
                .read(resumeFormProvider.notifier)
                .updateBasicField('email', value),
          ),
          _Field(
            controller: _phoneController,
            label: 'Phone',
            keyboardType: TextInputType.phone,
            onChanged: (value) => ref
                .read(resumeFormProvider.notifier)
                .updateBasicField('phone', value),
          ),
        ],
      ),
    );
  }

  void _syncController(TextEditingController controller, Object? value) {
    final text = value?.toString() ?? '';
    if (controller.text != text) {
      controller.text = text;
    }
  }
}

class SummarySection extends ConsumerStatefulWidget {
  final List<String> aiActions;
  final VoidCallback? onAiPressed;

  const SummarySection({
    super.key,
    this.aiActions = const [],
    this.onAiPressed,
  });

  @override
  ConsumerState<SummarySection> createState() => _SummarySectionState();
}

class _SummarySectionState extends ConsumerState<SummarySection> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(resumeFormProvider).data['summary']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasAi = widget.aiActions.isNotEmpty;
    ref.listen(resumeFormProvider, (previous, next) {
      final text = next.data['summary']?.toString() ?? '';
      if (_controller.text != text) {
        _controller.text = text;
      }
    });

    return SectionCard(
      title: 'Summary',
      icon: Icons.description_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Field(
            controller: _controller,
            label: 'Professional Summary',
            maxLines: 5,
            onChanged: (value) =>
                ref.read(resumeFormProvider.notifier).updateSummary(value),
          ),
          if (hasAi) ...[
            const SizedBox(height: 8),
            AIButton(
              text: 'AI Summary',
              onPressed: widget.onAiPressed ?? () {},
            ),
          ],
        ],
      ),
    );
  }
}

class ExperienceSection extends ConsumerStatefulWidget {
  final List<String> aiActions;
  final VoidCallback? onAiPressed;

  const ExperienceSection({
    super.key,
    this.aiActions = const [],
    this.onAiPressed,
  });

  @override
  ConsumerState<ExperienceSection> createState() => _ExperienceSectionState();
}

class _ExperienceSectionState extends ConsumerState<ExperienceSection> {
  @override
  Widget build(BuildContext context) {
    final items = ref.watch(resumeFormProvider).experienceItems;
    final hasAi = widget.aiActions.isNotEmpty;

    return SectionCard(
      title: 'Experience',
      icon: Icons.work_outline,
      onAdd: () => ref.read(resumeFormProvider.notifier).addExperience(),
      child: Column(
        children: [
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Tap Add to create your first experience entry.',
                style: TextStyle(color: AppColors.of(context).textSecondary),
              ),
            ),
          ...items.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ExperienceItemCard(
                index: entry.key,
                item: entry.value,
                onRemove: () => ref
                    .read(resumeFormProvider.notifier)
                    .removeExperience(entry.key),
                onChanged: (patch) => ref
                    .read(resumeFormProvider.notifier)
                    .updateExperience(entry.key, patch),
              ),
            ),
          ),
          if (hasAi) ...[
            const SizedBox(height: 4),
            AIButton(
              text: 'AI Experience',
              onPressed: widget.onAiPressed ?? () {},
            ),
          ],
        ],
      ),
    );
  }
}

class SkillsSection extends ConsumerStatefulWidget {
  final List<String> aiActions;
  final VoidCallback? onAiPressed;

  const SkillsSection({super.key, this.aiActions = const [], this.onAiPressed});

  @override
  ConsumerState<SkillsSection> createState() => _SkillsSectionState();
}

class _SkillsSectionState extends ConsumerState<SkillsSection> {
  late final TextEditingController _skillController;

  @override
  void initState() {
    super.initState();
    _skillController = TextEditingController();
  }

  @override
  void dispose() {
    _skillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skills = ref.watch(resumeFormProvider).skills;
    final hasAi = widget.aiActions.isNotEmpty;

    return SectionCard(
      title: 'Skills',
      icon: Icons.auto_awesome,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills
                .map(
                  (skill) => Chip(
                    label: Text(skill),
                    onDeleted: () => ref
                        .read(resumeFormProvider.notifier)
                        .removeSkill(skill),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Field(
                  controller: _skillController,
                  label: 'Add skill',
                  onSubmitted: (value) {
                    ref.read(resumeFormProvider.notifier).addSkill(value);
                    _skillController.clear();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  ref
                      .read(resumeFormProvider.notifier)
                      .addSkill(_skillController.text);
                  _skillController.clear();
                },
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          if (hasAi) ...[
            const SizedBox(height: 8),
            AIButton(text: 'AI Skills', onPressed: widget.onAiPressed ?? () {}),
          ],
        ],
      ),
    );
  }
}

class ExperienceItemCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> item;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onRemove;

  const ExperienceItemCard({
    super.key,
    required this.index,
    required this.item,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<ExperienceItemCard> createState() => _ExperienceItemCardState();
}

class _ExperienceItemCardState extends State<ExperienceItemCard> {
  late final TextEditingController _titleController;
  late final TextEditingController _companyController;
  late final TextEditingController _locationController;
  late final TextEditingController _startController;
  late final TextEditingController _endController;
  late final TextEditingController _summaryController;
  late final TextEditingController _bulletsController;

  @override
  void initState() {
    super.initState();
    _bindControllers();
  }

  @override
  void didUpdateWidget(covariant ExperienceItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
      _syncControllers();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _startController.dispose();
    _endController.dispose();
    _summaryController.dispose();
    _bulletsController.dispose();
    super.dispose();
  }

  void _bindControllers() {
    _titleController = TextEditingController(
      text: widget.item['title']?.toString() ?? '',
    );
    _companyController = TextEditingController(
      text: widget.item['company']?.toString() ?? '',
    );
    _locationController = TextEditingController(
      text: widget.item['location']?.toString() ?? '',
    );
    _startController = TextEditingController(
      text: widget.item['startDate']?.toString() ?? '',
    );
    _endController = TextEditingController(
      text: widget.item['endDate']?.toString() ?? '',
    );
    _summaryController = TextEditingController(
      text: widget.item['summary']?.toString() ?? '',
    );
    final bullets = widget.item['bullets'];
    final bulletText = bullets is List
        ? bullets.join(', ')
        : (bullets?.toString() ?? '');
    _bulletsController = TextEditingController(text: bulletText);
  }

  void _syncControllers() {
    _setText(_titleController, widget.item['title']);
    _setText(_companyController, widget.item['company']);
    _setText(_locationController, widget.item['location']);
    _setText(_startController, widget.item['startDate']);
    _setText(_endController, widget.item['endDate']);
    _setText(_summaryController, widget.item['summary']);
    final bullets = widget.item['bullets'];
    final bulletText = bullets is List
        ? bullets.join(', ')
        : (bullets?.toString() ?? '');
    _setText(_bulletsController, bulletText);
  }

  void _setText(TextEditingController controller, Object? value) {
    final text = value?.toString() ?? '';
    if (controller.text != text) {
      controller.text = text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.of(context).mutedBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Experience ${widget.index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            _Field(
              controller: _titleController,
              label: 'Job title',
              onChanged: (value) => _emit({'title': value}),
            ),
            _Field(
              controller: _companyController,
              label: 'Company',
              onChanged: (value) => _emit({'company': value}),
            ),
            _Field(
              controller: _locationController,
              label: 'Location',
              onChanged: (value) => _emit({'location': value}),
            ),
            Row(
              children: [
                Expanded(
                  child: _Field(
                    controller: _startController,
                    label: 'Start date',
                    onChanged: (value) => _emit({'startDate': value}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Field(
                    controller: _endController,
                    label: 'End date',
                    onChanged: (value) => _emit({'endDate': value}),
                  ),
                ),
              ],
            ),
            _Field(
              controller: _summaryController,
              label: 'Summary',
              maxLines: 3,
              onChanged: (value) => _emit({'summary': value}),
            ),
            _Field(
              controller: _bulletsController,
              label: 'Bullets comma separated',
              maxLines: 3,
              onChanged: (value) => _emit({
                'bullets': value
                    .split(',')
                    .map((entry) => entry.trim())
                    .where((entry) => entry.isNotEmpty)
                    .toList(),
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _emit(Map<String, dynamic> patch) {
    widget.onChanged(patch);
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _Field({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: colors.cardBackground,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
