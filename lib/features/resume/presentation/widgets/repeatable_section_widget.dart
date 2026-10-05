import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/template_detail_model.dart';
import '../providers/resume_form_provider.dart';

class RepeatableSectionWidget extends ConsumerWidget {
  final FormSectionModel section;
  final VoidCallback onAiAction;

  const RepeatableSectionWidget({
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
                        .addRepeatableItem(section.key, {});
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final itemData = entry.value as Map<String, dynamic>;

              return Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: section.fields.map((field) {
                        final value = itemData[field.key] ?? '';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextFormField(
                            initialValue: value is String
                                ? value
                                : value.toString(),
                            onChanged: (val) {
                              ref
                                  .read(resumeFormStateProvider.notifier)
                                  .updateRepeatableItemField(
                                    section.key,
                                    index,
                                    field.key,
                                    val,
                                  );
                            },
                            maxLines: field.type == 'textarea' ? 4 : 1,
                            decoration: InputDecoration(
                              labelText: field.label,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        ref
                            .read(resumeFormStateProvider.notifier)
                            .removeRepeatableItem(section.key, index);
                      },
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
