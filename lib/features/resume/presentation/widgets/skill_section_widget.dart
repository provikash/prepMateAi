import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/template_detail_model.dart';
import '../providers/resume_form_provider.dart';

class SkillSectionWidget extends ConsumerWidget {
  final FormSectionModel section;
  final VoidCallback onAiAction;

  const SkillSectionWidget({
    super.key,
    required this.section,
    required this.onAiAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(resumeFormStateProvider);
    final sectionState =
        formState[section.key] ?? <String, dynamic>{'items': []};
    final items = List<dynamic>.from(sectionState['items'] ?? []);

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  section.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    ref
                        .read(resumeFormStateProvider.notifier)
                        .addSkill(section.key, 'New Skill');
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Skill'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final skill = entry.value.toString();

                return Chip(
                  label: Text(skill),
                  onDeleted: () {
                    ref
                        .read(resumeFormStateProvider.notifier)
                        .removeSkill(section.key, index);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
