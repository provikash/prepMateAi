import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../../auth/presentation/viewmodel/auth_viewmodel.dart';
import '../../../home/data/models/resume_model.dart';
import '../../../home/providers/home_providers.dart';
import '../providers/resume_providers.dart';

class MyResumesScreen extends ConsumerStatefulWidget {
  const MyResumesScreen({super.key});

  @override
  ConsumerState<MyResumesScreen> createState() => _MyResumesScreenState();
}

class _MyResumesScreenState extends ConsumerState<MyResumesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ResumeModel> _filterResumes(List<ResumeModel> all) {
    var filtered = all;
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where((r) => r.title.toLowerCase().contains(query))
          .toList();
    }

    if (_selectedFilter == 'Drafts') {
      filtered = filtered.where((r) => !r.isCompleted).toList();
    } else if (_selectedFilter == 'Completed') {
      filtered = filtered.where((r) => r.isCompleted).toList();
    }
    return filtered;
  }

  Future<void> _handleRename(ResumeModel resume) async {
    final controller = TextEditingController(text: resume.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Resume'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Resume Title',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty && newTitle != resume.title) {
      try {
        final userId = ref.read(authViewModelProvider).user?.id;
        if (userId == null) {
          await ref
              .read(resumeRepositoryProvider)
              .renameResume(resume.id, newTitle);
        } else {
          final remote = ref.read(homeRemoteDataSourceProvider);
          await remote.updateResume(
            resumeId: resume.id,
            title: newTitle,
            data: resume.data,
          );
        }
        ref.invalidate(resumeListProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to rename resume')),
          );
        }
      }
    }
  }

  Future<void> _handleDuplicate(ResumeModel resume) async {
    final userId = ref.read(authViewModelProvider).user?.id;
    try {
      if (userId == null) {
        await ref.read(resumeRepositoryProvider).duplicateResume(resume.id);
      } else {
        await ref
            .read(homeRepositoryProvider)
            .duplicateResume(userId, resume.id);
      }
      ref.invalidate(resumeListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resume duplicated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to duplicate resume')),
        );
      }
    }
  }

  Future<void> _handleDelete(ResumeModel resume) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Resume'),
        content: Text(
          'Are you sure you want to delete "${resume.title}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(resumeRepositoryProvider).deleteResume(resume.id);
        ref.invalidate(resumeListProvider);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Resume deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete resume')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final resumesAsync = ref.watch(resumeListProvider);

    return Scaffold(
      backgroundColor: colors.screenBackground,
      appBar: AppBar(
        backgroundColor: colors.surface.withValues(alpha: 0.85),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Text(
              'My resumes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            resumesAsync.maybeWhen(
              data: (list) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${list.length} resumes',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            color: colors.textSecondary,
            onPressed: () {},
          ),
        ],
      ),
      body: resumesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load resumes'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () =>
                    ref.read(resumeListProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (allResumes) {
          final filtered = _filterResumes(allResumes);

          return Column(
            children: [
              // Search field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by resume title or role',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary.withValues(alpha: 0.6),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 20,
                        color: colors.textSecondary,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),

              // Horizontal filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    _buildChip('All', 'All (${allResumes.length})', colors),
                    const SizedBox(width: 8),
                    _buildChip(
                      'Drafts',
                      'Drafts (${allResumes.where((r) => !r.isCompleted).length})',
                      colors,
                    ),
                    const SizedBox(width: 8),
                    _buildChip(
                      'Completed',
                      'Completed (${allResumes.where((r) => r.isCompleted).length})',
                      colors,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Resume Grid or Empty State
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 48,
                              color: colors.border,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'No resumes yet'
                                  : 'No matching resumes found',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create a new resume to get started.',
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => context.push('/template'),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Create Resume'),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.72,
                            ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final resume = filtered[index];
                          return _buildResumeCard(resume, colors);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/template'),
        icon: const Icon(Icons.add),
        label: const Text('New Resume'),
      ),
    );
  }

  Widget _buildChip(String filterKey, String label, AppColors colors) {
    final isSelected = _selectedFilter == filterKey;
    return AppFilterChip(
      label: label,
      isSelected: isSelected,
      onSelected: (_) {
        setState(() => _selectedFilter = filterKey);
      },
    );
  }

  Widget _buildResumeCard(ResumeModel resume, AppColors colors) {
    return GestureDetector(
      onTap: () => context.push('/resume/pdf/${resume.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF172033).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview thumbnail
            Expanded(
              child: Container(
                color: colors.surfaceContainer,
                padding: const EdgeInsets.all(8),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: resume.thumbnailUrl.isEmpty
                            ? _thumbnailFallback(colors)
                            : CachedNetworkImage(
                                imageUrl: resume.thumbnailUrl,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                                placeholder: (_, _) =>
                                    _thumbnailFallback(colors),
                                errorWidget: (_, _, _) =>
                                    _thumbnailFallback(colors),
                              ),
                      ),
                    ),

                    // 3 dots menu
                    Positioned(
                      top: 4,
                      right: 4,
                      child: PopupMenuButton<String>(
                        icon: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: colors.surface.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.more_vert,
                            size: 16,
                            color: colors.textSecondary,
                          ),
                        ),
                        padding: EdgeInsets.zero,
                        onSelected: (val) {
                          if (val == 'edit') {
                            context.push(
                              '/resume/form',
                              extra: resume.templateId,
                            );
                          } else if (val == 'pdf') {
                            context.push('/resume/pdf/${resume.id}');
                          } else if (val == 'optimize') {
                            context.push('/resume/optimize');
                          } else if (val == 'rename') {
                            _handleRename(resume);
                          } else if (val == 'duplicate') {
                            _handleDuplicate(resume);
                          } else if (val == 'delete') {
                            _handleDelete(resume);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 16),
                                SizedBox(width: 8),
                                Text('Edit in Builder'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'pdf',
                            child: Row(
                              children: [
                                Icon(Icons.picture_as_pdf, size: 16),
                                SizedBox(width: 8),
                                Text('PDF Preview'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'optimize',
                            child: Row(
                              children: [
                                Icon(Icons.auto_awesome, size: 16),
                                SizedBox(width: 8),
                                Text('Optimize'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'rename',
                            child: Row(
                              children: [
                                Icon(Icons.drive_file_rename_outline, size: 16),
                                SizedBox(width: 8),
                                Text('Rename'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'duplicate',
                            child: Row(
                              children: [
                                Icon(Icons.copy, size: 16),
                                SizedBox(width: 8),
                                Text('Duplicate'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status pill
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: resume.isCompleted
                              ? colors.secondarySoft
                              : colors.surface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          resume.isCompleted ? 'Completed' : 'Draft',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: resume.isCompleted
                                ? colors.secondary
                                : colors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Card Body
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resume.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Tap to preview',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.visibility_outlined,
                        size: 15,
                        color: colors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnailFallback(AppColors colors) => Container(
    color: colors.surface,
    alignment: Alignment.center,
    child: Icon(
      Icons.description_outlined,
      size: 44,
      color: colors.textSecondary,
    ),
  );
}
