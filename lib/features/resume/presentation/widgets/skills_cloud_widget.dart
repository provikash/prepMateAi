import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme.dart';
import '../../../../core/providers/form_provider.dart';
import '../../../ai_credits/presentation/providers/ai_credits_provider.dart';

/// Interactive skills editor matching Stitch screen 21:
/// Resume Builder — Skills & Suggestions.
///
/// Features:
/// - Searchable input to add custom skills
/// - Categorized confirmed skills chips with drag handle and count badges
/// - Remove button per chip
/// - AI-recommended skills cloud with ATS Match badge
/// - Tap-to-add for suggestions (no Add All, requires explicit user confirmation)
/// - Refresh suggestions with credit cost indicator
class SkillsCloudWidget extends ConsumerStatefulWidget {
  const SkillsCloudWidget({
    super.key,
    this.targetRole = 'Flutter & Mobile roles',
    this.onRefreshAiSuggestions,
  });

  final String targetRole;
  final VoidCallback? onRefreshAiSuggestions;

  @override
  ConsumerState<SkillsCloudWidget> createState() => _SkillsCloudWidgetState();
}

class _SkillsCloudWidgetState extends ConsumerState<SkillsCloudWidget> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  // Curated domain suggestions for mobile/tech (can be enriched or fetched from backend)
  final List<String> _suggestedSkills = [
    'Clean Architecture',
    'State Management (Riverpod / BLoC)',
    'CI/CD (GitHub Actions / Fastlane)',
    'Unit & Widget Testing',
    'GraphQL',
    'Offline-First Sync',
    'Performance Profiling',
    'Docker & Microservices',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleAddSkill(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    ref.read(resumeFormProvider.notifier).addSkill(trimmed);
    _searchController.clear();
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final formState = ref.watch(resumeFormProvider);
    final confirmedSkills = formState.skills;
    final creditState = ref.watch(aiCreditsProvider);

    // Group confirmed skills into categories or display them cleanly
    final techSkills = <String>[];
    final langSkills = <String>[];
    final otherSkills = <String>[];

    const knownLanguages = {
      'Dart',
      'Java',
      'Kotlin',
      'Swift',
      'Python',
      'JavaScript',
      'TypeScript',
      'C++',
      'Go',
      'SQL',
    };
    const knownTech = {
      'Flutter',
      'Android SDK',
      'iOS SDK',
      'Firebase',
      'REST APIs',
      'GraphQL',
      'Riverpod',
      'BLoC',
      'React Native',
    };

    for (final skill in confirmedSkills) {
      if (knownLanguages.any((l) => l.toLowerCase() == skill.toLowerCase())) {
        langSkills.add(skill);
      } else if (knownTech.any((t) => t.toLowerCase() == skill.toLowerCase())) {
        techSkills.add(skill);
      } else {
        otherSkills.add(skill);
      }
    }

    // Filter available suggestions (exclude skills already added)
    final unaddedSuggestions = _suggestedSkills.where((s) {
      return !confirmedSkills.any((c) => c.toLowerCase() == s.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Searchable Input Field
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border.withValues(alpha: 0.8)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF121B2E).withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Icon(Icons.search, color: colors.textSecondary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: const InputDecoration(
                    hintText: 'Type a skill (e.g. Flutter, Kotlin, Docker)...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: _handleAddSkill,
                ),
              ),
              FilledButton.icon(
                onPressed: () => _handleAddSkill(_searchController.text),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Press return or tap Add',
                style: TextStyle(fontSize: 11, color: colors.textSecondary),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 13, color: colors.secondary),
                  const SizedBox(width: 4),
                  Text(
                    'AI-assisted sorting',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 2. Confirmed Skills Category Groups
        if (techSkills.isNotEmpty) ...[
          _buildCategoryCard(
            context,
            title: 'Technical & Frameworks',
            skills: techSkills,
            badgeColor: colors.primarySoft,
            textColor: colors.primary,
          ),
          const SizedBox(height: 12),
        ],
        if (langSkills.isNotEmpty) ...[
          _buildCategoryCard(
            context,
            title: 'Programming Languages',
            skills: langSkills,
            badgeColor: colors.secondarySoft,
            textColor: colors.secondary,
          ),
          const SizedBox(height: 12),
        ],
        if (otherSkills.isNotEmpty ||
            (techSkills.isEmpty && langSkills.isEmpty)) ...[
          _buildCategoryCard(
            context,
            title: techSkills.isEmpty && langSkills.isEmpty
                ? 'Your Skills'
                : 'Domain & Tools',
            skills: otherSkills.isNotEmpty ? otherSkills : confirmedSkills,
            badgeColor: colors.screenBackground,
            textColor: colors.textPrimary,
          ),
          const SizedBox(height: 16),
        ],

        // 3. AI-Recommended Skills Section
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.secondarySoft.withValues(alpha: 0.7),
                colors.screenBackground,
                colors.secondarySoft.withValues(alpha: 0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.secondary.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF087E78).withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                              size: 18,
                              color: colors.secondary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Recommended for ${widget.targetRole}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Based on top recruiter keywords for your profile. Tap to add:',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colors.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.trending_up, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'ATS Match',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Chips Cloud
              if (unaddedSuggestions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'All suggested skills have been added!',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: colors.textSecondary,
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: unaddedSuggestions.map((suggestion) {
                    return InkWell(
                      onTap: () {
                        ref
                            .read(resumeFormProvider.notifier)
                            .addSkill(suggestion);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added "$suggestion"'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: colors.secondary.withValues(alpha: 0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF121B2E,
                              ).withValues(alpha: 0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 14, color: colors.secondary),
                            const SizedBox(width: 4),
                            Text(
                              suggestion,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 14),
              // Refresh Suggestions / Credit Cost Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: widget.onRefreshAiSuggestions,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.autorenew,
                          size: 16,
                          color: colors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Refresh suggestions (1 credit)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: colors.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${creditState.account?.availableCredits ?? 0} credits remaining',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required List<String> skills,
    required Color badgeColor,
    required Color textColor,
  }) {
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF121B2E).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.drag_indicator,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${skills.length} ${skills.length == 1 ? 'skill' : 'skills'}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills.map((skill) {
              return Container(
                padding: const EdgeInsets.only(
                  left: 10,
                  right: 4,
                  top: 4,
                  bottom: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.screenBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colors.border.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      skill,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        ref
                            .read(resumeFormProvider.notifier)
                            .removeSkill(skill);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
