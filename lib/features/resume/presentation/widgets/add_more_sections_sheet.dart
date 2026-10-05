import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme.dart';
import '../../../../core/providers/form_provider.dart';

/// Modal bottom sheet matching Stitch screen 18: Resume Builder — Add More Sections.
///
/// Displays supported optional resume sections with icons, descriptions, and
/// clear 'Add' / 'Added' toggle states.
class AddMoreSectionsSheet extends ConsumerStatefulWidget {
  const AddMoreSectionsSheet({super.key, this.onSectionSelected});

  final void Function(String sectionKey)? onSectionSelected;

  static Future<String?> show(
    BuildContext context, {
    void Function(String sectionKey)? onSectionSelected,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          AddMoreSectionsSheet(onSectionSelected: onSectionSelected),
    );
  }

  @override
  ConsumerState<AddMoreSectionsSheet> createState() =>
      _AddMoreSectionsSheetState();
}

class _AddMoreSectionsSheetState extends ConsumerState<AddMoreSectionsSheet> {
  static const List<_OptionalSectionMeta> _supportedSections = [
    _OptionalSectionMeta(
      key: 'languages',
      title: 'Languages',
      description: 'Display languages you speak and proficiency levels.',
      icon: Icons.language,
      containerColor: Color(0xFFE9EFFF),
      iconColor: Color(0xFF2457D6),
    ),
    _OptionalSectionMeta(
      key: 'certificates',
      title: 'Certifications & Licenses',
      description: 'Official credentials from AWS, Google, Coursera, etc.',
      icon: Icons.verified,
      containerColor: Color(0xFFE1F4F1),
      iconColor: Color(0xFF087E78),
    ),
    _OptionalSectionMeta(
      key: 'awards',
      title: 'Awards & Honors',
      description:
          'Hackathons, academic dean’s list, or corporate recognition.',
      icon: Icons.military_tech,
      containerColor: Color(0xFFDCE1FF),
      iconColor: Color(0xFF003CAD),
    ),
    _OptionalSectionMeta(
      key: 'volunteer',
      title: 'Volunteer & Leadership',
      description:
          'Community initiatives, student clubs, and leadership roles.',
      icon: Icons.volunteer_activism,
      containerColor: Color(0xFFD9E2FC),
      iconColor: Color(0xFF2457D6),
    ),
    _OptionalSectionMeta(
      key: 'publications',
      title: 'Publications & Research',
      description: 'Research papers, journals, conference talks, or patents.',
      icon: Icons.menu_book,
      containerColor: Color(0xFFDCE2F2),
      iconColor: Color(0xFF404753),
    ),
    _OptionalSectionMeta(
      key: 'references',
      title: 'References',
      description: 'Available upon request or direct supervisor endorsements.',
      icon: Icons.group,
      containerColor: Color(0xFFB5C4FF),
      iconColor: Color(0xFF00164D),
    ),
    _OptionalSectionMeta(
      key: 'custom',
      title: 'Custom Section',
      description: 'Create your own section with custom title and format.',
      icon: Icons.add_box,
      containerColor: Color(0xFF96F3EB),
      iconColor: Color(0xFF00504C),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final formState = ref.watch(resumeFormProvider);
    final data = formState.data;

    // Count how many optional sections currently have data
    final activeCount = _supportedSections.where((s) {
      final value = data[s.key];
      if (value is List) return value.isNotEmpty;
      if (value is Map) return value.isNotEmpty;
      if (value is String) return value.trim().isNotEmpty;
      return value != null;
    }).length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Add more sections',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
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
                              '$activeCount Active',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select additional sections to showcase your unique background and achievements.',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: colors.screenBackground,
                    foregroundColor: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Section list
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: _supportedSections.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final section = _supportedSections[index];
                final value = data[section.key];
                final bool isAdded = switch (value) {
                  List l => l.isNotEmpty,
                  Map m => m.isNotEmpty,
                  String s => s.trim().isNotEmpty,
                  _ => value != null,
                };

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isAdded
                        ? colors.secondarySoft.withValues(alpha: 0.6)
                        : colors.screenBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isAdded
                          ? colors.secondary.withValues(alpha: 0.3)
                          : colors.border.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: section.containerColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          section.icon,
                          color: section.iconColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              section.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Add / Added Button
                      ElevatedButton.icon(
                        onPressed: () {
                          if (isAdded) {
                            // If already added, prompt remove or navigate to edit
                            _showRemoveOrEditDialog(context, section);
                          } else {
                            // Initialize section with empty entry or default
                            ref
                                .read(resumeFormProvider.notifier)
                                .ensureSectionInitialized(section.key);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Added ${section.title} to your resume',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                            setState(() {});
                            widget.onSectionSelected?.call(section.key);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: isAdded
                              ? colors.secondary
                              : colors.surface,
                          foregroundColor: isAdded
                              ? Colors.white
                              : colors.primary,
                          side: BorderSide(
                            color: isAdded ? colors.secondary : colors.border,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: Icon(isAdded ? Icons.check : Icons.add, size: 16),
                        label: Text(
                          isAdded ? 'Added' : 'Add',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Done footer
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF121B2E).withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.check, size: 18),
                label: const Text(
                  'Done',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveOrEditDialog(
    BuildContext context,
    _OptionalSectionMeta section,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text('Edit ${section.title}'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                  widget.onSectionSelected?.call(section.key);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(
                  'Remove ${section.title}',
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ref
                      .read(resumeFormProvider.notifier)
                      .clearSection(section.key);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Removed ${section.title}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionalSectionMeta {
  const _OptionalSectionMeta({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.containerColor,
    required this.iconColor,
  });

  final String key;
  final String title;
  final String description;
  final IconData icon;
  final Color containerColor;
  final Color iconColor;
}
