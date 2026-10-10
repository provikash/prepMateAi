import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/profile_colors.dart';
import 'package:prepmate_mobile/features/auth/data/models/user_model.dart';
import 'package:prepmate_mobile/features/auth/presentation/viewmodel/auth_viewmodel.dart';
import 'package:prepmate_mobile/features/home/providers/home_providers.dart';
import '../providers/profile_provider.dart';
import '../viewmodels/profile_state.dart';
import '../widgets/personal_info_modal_sheets.dart';
import '../widgets/personal_info_edge_state_sheets.dart';
import '../../domain/entities/profile_lifecycle_models.dart';

/// Screen 81 & 82: Personal Information Editor with Validation,
/// Incomplete States, Autosave, Conflict Recovery, and Cascading Updates.
class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  // Keys to jump to fields on error
  final GlobalKey _nameKey = GlobalKey();
  final GlobalKey _linkedinKey = GlobalKey();
  final GlobalKey _titleKey = GlobalKey();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _preferredNameController;
  late TextEditingController _titleController;
  late TextEditingController _cityController;
  late TextEditingController _stateRegionController;
  late TextEditingController _countryController;
  late TextEditingController _countryCodeController;
  late TextEditingController _timeZoneController;
  late TextEditingController _industryController;
  late TextEditingController _linkedinController;
  late TextEditingController _githubController;
  late TextEditingController _portfolioController;

  // Defaults for new resumes
  bool _useNameForNewResumes = true;
  bool _useTitleForNewResumes = true;
  bool _useLocationForNewResumes = true;
  bool _suggestLinksForNewResumes = true;

  // Custom links
  final List<Map<String, String>> _customLinks = [];

  // Local avatar file if recently picked
  File? _localAvatarFile;

  // Form state tracking
  Map<String, dynamic> _initialValues = const {};
  bool _hydrated = false;
  Timer? _autosaveDebounce;
  bool _isDirty = false;

  // Active view mode for Screen 82 & 84 demo / state inspection
  // 'editor', 'errors', 'incomplete', 'conflict', 'offline', 'cascading'
  String _activeStateMode = 'editor';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _preferredNameController = TextEditingController();
    _titleController = TextEditingController();
    _cityController = TextEditingController();
    _stateRegionController = TextEditingController();
    _countryController = TextEditingController();
    _countryCodeController = TextEditingController();
    _timeZoneController = TextEditingController();
    _industryController = TextEditingController();
    _linkedinController = TextEditingController();
    _githubController = TextEditingController();
    _portfolioController = TextEditingController();

    // Listen to changes for dirty tracking and debounced autosave
    for (final c in [
      _nameController,
      _preferredNameController,
      _titleController,
      _cityController,
      _stateRegionController,
      _linkedinController,
      _githubController,
      _portfolioController,
    ]) {
      c.addListener(_onFieldChanged);
    }

    Future.microtask(() async {
      final vm = ref.read(profileProvider.notifier);
      await vm.loadProfile();
      await vm.loadMetadata();
    });
  }

  void _onFieldChanged() {
    if (!_hydrated) return;
    final current = _collectFormValues();
    final dirty = _computeIsDirty(current);
    if (dirty != _isDirty) {
      setState(() {
        _isDirty = dirty;
      });
      if (dirty) {
        ref
            .read(profileProvider.notifier)
            .setSaveStatus(ProfileSaveStatus.unsaved);
      }
    }

    if (dirty) {
      _autosaveDebounce?.cancel();
      _autosaveDebounce = Timer(const Duration(milliseconds: 1200), () {
        _triggerAutosave();
      });
    }
  }

  bool _computeIsDirty(Map<String, dynamic> current) {
    for (final entry in current.entries) {
      if (_initialValues[entry.key] != entry.value) {
        return true;
      }
    }
    return false;
  }

  void _hydrateFromUser(UserModel? user) {
    if (user == null || _hydrated) return;

    _nameController.text = user.fullName ?? '';
    _preferredNameController.text = user.preferredName ?? '';
    _titleController.text = user.title ?? '';
    _cityController.text = user.city ?? '';
    _stateRegionController.text = user.stateRegion ?? '';
    _countryController.text = user.country ?? 'United States';
    _countryCodeController.text = user.countryCode ?? 'US';
    _timeZoneController.text = user.timeZone ?? 'Central Time · UTC-05:00';
    _industryController.text = user.industry ?? 'Technology';
    _linkedinController.text = user.linkedin ?? '';
    _githubController.text = user.github ?? '';
    _portfolioController.text = user.portfolioUrl ?? '';

    _useNameForNewResumes = user.useNameForNewResumes;
    _useTitleForNewResumes = user.useTitleForNewResumes;
    _useLocationForNewResumes = user.useLocationForNewResumes;
    _suggestLinksForNewResumes = user.suggestLinksForNewResumes;

    _customLinks.clear();
    for (final l in user.customLinks ?? const []) {
      _customLinks.add(Map<String, String>.from(l));
    }

    _initialValues = _collectFormValues();
    _hydrated = true;
  }

  Map<String, dynamic> _collectFormValues() {
    return {
      'full_name': _nameController.text.trim(),
      'preferred_name': _preferredNameController.text.trim(),
      'job_title': _titleController.text.trim(),
      'city': _cityController.text.trim(),
      'state_region': _stateRegionController.text.trim(),
      'country': _countryController.text.trim(),
      'country_code': _countryCodeController.text.trim(),
      'time_zone': _timeZoneController.text.trim(),
      'industry': _industryController.text.trim(),
      'linkedin_url': _linkedinController.text.trim(),
      'github_url': _githubController.text.trim(),
      'portfolio_url': _portfolioController.text.trim(),
      'use_name_for_new_resumes': _useNameForNewResumes,
      'use_title_for_new_resumes': _useTitleForNewResumes,
      'use_location_for_new_resumes': _useLocationForNewResumes,
      'suggest_links_for_new_resumes': _suggestLinksForNewResumes,
      'custom_links': List<Map<String, String>>.from(_customLinks),
    };
  }

  Map<String, dynamic> _collectDiff() {
    final current = _collectFormValues();
    final diff = <String, dynamic>{};
    for (final entry in current.entries) {
      if (_initialValues[entry.key] != entry.value) {
        diff[entry.key] = entry.value;
      }
    }
    return diff;
  }

  Future<void> _triggerAutosave() async {
    final diff = _collectDiff();
    if (diff.isEmpty) return;

    if (diff.containsKey('full_name') &&
        (diff['full_name'] as String).isEmpty) {
      return;
    }

    if (diff.containsKey('linkedin_url')) {
      final li = diff['linkedin_url'] as String;
      if (li.isNotEmpty && !li.startsWith('https://')) {
        return;
      }
    }

    final success = await ref
        .read(profileProvider.notifier)
        .updateProfile(diff, isAutosave: true);

    if (mounted && success) {
      _initialValues = _collectFormValues();
      setState(() {
        _isDirty = false;
      });
    }
  }

  Future<void> _handleExplicitSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() {
        _activeStateMode = 'errors';
      });
      _scrollToField(_nameKey);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please resolve the highlighted validation errors.'),
          backgroundColor: ProfileColors.error,
        ),
      );
      return;
    }

    final diff = _collectDiff();
    if (diff.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes to save.')),
      );
      return;
    }

    final success = await ref
        .read(profileProvider.notifier)
        .updateProfile(diff, isAutosave: false);

    if (mounted) {
      if (success) {
        _initialValues = _collectFormValues();
        setState(() {
          _isDirty = false;
        });

        final userId = ref.read(authViewModelProvider).user?.id;
        if (userId != null && userId.isNotEmpty) {
          await ref.read(homeRepositoryProvider).invalidateDashboard(userId);
          ref.invalidate(dashboardProvider);
        }

        final changedTitle = diff.containsKey('job_title');
        final changedLoc =
            diff.containsKey('city') || diff.containsKey('state_region');
        if (changedTitle || changedLoc) {
          CascadingResumesSheet.show(
            context,
            jobTitle: _titleController.text.trim(),
            location:
                '${_cityController.text.trim()}, ${_stateRegionController.text.trim()}',
            onApply: (selectedIds) async {
              final result = await ref
                  .read(profileProvider.notifier)
                  .cascadeResumes(selectedIds);
              if (mounted && result != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Updated ${result.updatedCount} selected resume(s)!'),
                    backgroundColor: ProfileColors.secondary,
                  ),
                );
              }
            },
            onSkip: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Resumes preserved. Master profile saved.')),
              );
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile saved successfully!'),
              backgroundColor: ProfileColors.secondary,
            ),
          );
        }
      } else {
        final state = ref.read(profileProvider);
        if (state.isConflict) {
          setState(() {
            _activeStateMode = 'conflict';
          });
        }
      }
    }
  }

  Future<bool> _handleLeaveProtection() async {
    if (!_isDirty) return true;
    final discard = await LeaveConfirmationDialog.show(context);
    return discard;
  }

  void _scrollToField(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
    }
  }

  void _quickFixLinkedin() {
    final cur = _linkedinController.text.trim();
    if (cur.isEmpty) return;
    final fixed = 'https://${cur.replaceFirst(RegExp(r'^https?:\/\/'), '')}';
    _linkedinController.text = fixed;
  }

  Future<void> _pickPhoto() async {
    final user = ref.read(profileProvider).user;
    final choice = await PhotoActionSheet.show(
      context,
      hasExistingPhoto: user?.profileImage != null && user!.profileImage!.isNotEmpty,
      imageUrl: user?.profileImage,
    );

    if (choice == null || !mounted) return;

    if (choice == PhotoActionChoice.takePhoto ||
        choice == PhotoActionChoice.chooseFromGallery) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result != null && result.files.single.path != null) {
        final pickedFile = File(result.files.single.path!);
        if (!mounted) return;
        final cropped =
            await AvatarCropDialog.show(context, imageFile: pickedFile);
        if (cropped != null && mounted) {
          setState(() {
            _localAvatarFile = cropped;
          });
          final ok = await ref
              .read(profileProvider.notifier)
              .uploadProfileImage(cropped.path);
          if (mounted && ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile photo updated successfully.'),
                backgroundColor: ProfileColors.secondary,
              ),
            );
          }
        }
      }
    } else if (choice == PhotoActionChoice.removePhoto) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remove Photo?'),
          content: const Text(
              'Your profile will revert back to your initials badge.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: ProfileColors.error,
                  foregroundColor: Colors.white),
              child: const Text('Remove'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        setState(() {
          _localAvatarFile = null;
        });
        await ref.read(profileProvider.notifier).deleteProfileImage();
      }
    }
  }

  void _addCustomLink() {
    showDialog(
      context: context,
      builder: (ctx) {
        final labelCtrl = TextEditingController();
        final urlCtrl = TextEditingController(text: 'https://');
        return AlertDialog(
          title: const Text('Add Professional Link'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelCtrl,
                decoration: const InputDecoration(labelText: 'Link Title (e.g. Behance)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(labelText: 'URL (https://...)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final lbl = labelCtrl.text.trim();
                final url = urlCtrl.text.trim();
                if (lbl.isNotEmpty && url.startsWith('https://')) {
                  setState(() {
                    _customLinks.add({'label': lbl, 'url': url});
                    _isDirty = true;
                  });
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _autosaveDebounce?.cancel();
    _scrollController.dispose();
    _nameController.dispose();
    _preferredNameController.dispose();
    _titleController.dispose();
    _cityController.dispose();
    _stateRegionController.dispose();
    _countryController.dispose();
    _countryCodeController.dispose();
    _timeZoneController.dispose();
    _industryController.dispose();
    _linkedinController.dispose();
    _githubController.dispose();
    _portfolioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final user = state.user;

    if (user != null && !_hydrated) {
      _hydrateFromUser(user);
    }

    final hasErrors = _nameController.text.trim().isEmpty ||
        (_linkedinController.text.trim().isNotEmpty &&
            !_linkedinController.text.trim().startsWith('https://'));

    return PopScope(
      canPop: !_isDirty,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldLeave = await _handleLeaveProtection();
        if (shouldLeave && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: ProfileColors.surface,
        appBar: AppBar(
          backgroundColor: ProfileColors.surface.withOpacity(0.92),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () async {
              final shouldLeave = await _handleLeaveProtection();
              if (shouldLeave && mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: const Text(
            'Personal Information',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: ProfileColors.onSurface,
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (val) {
                if (val == 'refresh') {
                  ref.read(profileProvider.notifier).refresh();
                } else if (val == 'export') {
                  ref.read(profileProvider.notifier).requestExport();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Personal data export requested.')),
                  );
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                    value: 'refresh', child: Text('Sync cloud profile')),
                const PopupMenuItem(
                    value: 'export', child: Text('Download personal data archive')),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: ProfileColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildStateSwitcherPills(),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    children: [
                      _buildSyncStatusStrip(state),
                      const SizedBox(height: 12),
                      _buildScopeNoticeCard(),
                      const SizedBox(height: 16),
                      if (_activeStateMode == 'errors' || hasErrors) ...[
                        _buildErrorSummaryBanner(),
                        const SizedBox(height: 12),
                      ],
                      if (_activeStateMode == 'incomplete') ...[
                        _buildIncompleteProfileCard(user),
                        const SizedBox(height: 12),
                      ],
                      if (_activeStateMode == 'conflict' || state.isConflict) ...[
                        ConflictResolutionCard(
                          serverData: state.conflictServerData ?? {
                            'job_title': 'Staff Flutter Architect',
                            'location': 'San Francisco, CA',
                          },
                          localData: _collectFormValues(),
                          serverVersion: state.serverVersion ?? (user?.version ?? 1),
                          onResolve: (resolved) async {
                            final ok = await ref
                                .read(profileProvider.notifier)
                                .resolveConflict(
                                  resolvedFields: resolved,
                                  serverVersion: state.serverVersion ?? 1,
                                );
                            if (mounted && ok) {
                              setState(() {
                                _activeStateMode = 'editor';
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Conflict resolved & synced!'),
                                  backgroundColor: ProfileColors.secondary,
                                ),
                              );
                            }
                          },
                          onCancel: () {
                            setState(() {
                              _activeStateMode = 'editor';
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_activeStateMode == 'offline' || state.isOffline) ...[
                        OfflineDraftCard(
                          queue: state.offlineDraftQueue.isNotEmpty
                              ? state.offlineDraftQueue
                              : [
                                  OfflineDraftItem(
                                    field: 'job_title',
                                    label: 'Target Role Title',
                                    displayValue: _titleController.text,
                                    timestamp: DateTime.now(),
                                  ),
                                  OfflineDraftItem(
                                    field: 'city',
                                    label: 'City Location',
                                    displayValue: _cityController.text,
                                    timestamp: DateTime.now(),
                                  ),
                                ],
                          onRetry: () async {
                            final ok = await ref
                                .read(profileProvider.notifier)
                                .syncOfflineDraft();
                            if (mounted && ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Offline drafts synchronized!'),
                                  backgroundColor: ProfileColors.secondary,
                                ),
                              );
                            }
                          },
                          onClear: () {
                            ref
                                .read(profileProvider.notifier)
                                .clearOfflineDraft();
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildReassuranceBanner(),
                      const SizedBox(height: 16),
                      _buildPhotoCard(user, state),
                      const SizedBox(height: 16),
                      _buildBasicDetailsCard(state),
                      const SizedBox(height: 16),
                      _buildVerifiedContactCard(user),
                      const SizedBox(height: 16),
                      _buildProfessionalLinksCard(),
                      const SizedBox(height: 16),
                      _buildResumeDefaultsCard(),
                      const SizedBox(height: 16),
                      _buildPrivateVaultCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomSheet: _buildStickyBottomActionBar(state, hasErrors),
      ),
    );
  }

  Widget _buildStateSwitcherPills() {
    final modes = [
      {'key': 'editor', 'label': '1. Editor'},
      {'key': 'errors', 'label': '2. Errors'},
      {'key': 'incomplete', 'label': '3. Incomplete'},
      {'key': 'conflict', 'label': '4. Conflict'},
      {'key': 'offline', 'label': '5. Offline'},
      {'key': 'cascading', 'label': '6. Cascading'},
    ];

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: modes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final m = modes[index];
          final isSelected = _activeStateMode == m['key'];

          return InkWell(
            onTap: () {
              if (m['key'] == 'cascading') {
                CascadingResumesSheet.show(
                  context,
                  jobTitle: _titleController.text.trim(),
                  location:
                      '${_cityController.text.trim()}, ${_stateRegionController.text.trim()}',
                  onApply: (_) {},
                  onSkip: () {},
                );
              } else {
                setState(() {
                  _activeStateMode = m['key']!;
                });
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? ProfileColors.primary
                    : ProfileColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                m['label']!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : ProfileColors.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSyncStatusStrip(ProfileState state) {
    String statusText;
    IconData statusIcon;
    Color statusColor;

    switch (state.saveStatus) {
      case ProfileSaveStatus.saving:
        statusText = 'Saving Changes...';
        statusIcon = Icons.sync_rounded;
        statusColor = ProfileColors.primary;
        break;
      case ProfileSaveStatus.saved:
        statusText = 'All Changes Saved';
        statusIcon = Icons.check_circle_rounded;
        statusColor = ProfileColors.secondary;
        break;
      case ProfileSaveStatus.unsaved:
        statusText = 'Unsaved Changes';
        statusIcon = Icons.info_outline_rounded;
        statusColor = ProfileColors.primary;
        break;
      case ProfileSaveStatus.saveFailed:
        statusText = 'Save Failed';
        statusIcon = Icons.error_outline_rounded;
        statusColor = ProfileColors.error;
        break;
      case ProfileSaveStatus.offlinePending:
        statusText = 'Offline Pending';
        statusIcon = Icons.cloud_off_rounded;
        statusColor = const Color(0xFFA15C00);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: ProfileColors.secondary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Profile Auto-Sync Active',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: ProfileColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeNoticeCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ProfileColors.surfaceContainerHigh.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ProfileColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_box_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your PrepMate profile',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ProfileColors.onSurface,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: ProfileColors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Scope',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'These details personalize your coaching feedback and set smart defaults for new resumes. Existing tailored resumes will not change automatically.',
                  style: TextStyle(
                    fontSize: 13,
                    color: ProfileColors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Profile Data Scope'),
                        content: const Text(
                          'Personal Information represents account-level defaults. Your tailored resumes are independent documents created with specific snapshots, ensuring past job submissions are never altered when your master profile updates.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Got it'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Learn how profile data is used',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ProfileColors.primary,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          size: 16, color: ProfileColors.primary),
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

  Widget _buildErrorSummaryBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ProfileColors.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: ProfileColors.error.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_rounded,
                color: ProfileColors.error, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Please fix issues before saving',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: ProfileColors.onErrorContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: ProfileColors.error.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Action required',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: ProfileColors.onErrorContainer),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'We preserved all valid changes. Resolve the highlighted fields below to continue.',
                  style: TextStyle(fontSize: 12, height: 1.3),
                ),
                const SizedBox(height: 8),
                if (_nameController.text.trim().isEmpty)
                  InkWell(
                    onTap: () => _scrollToField(_nameKey),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 6, color: ProfileColors.error),
                          SizedBox(width: 6),
                          Text('Full name cannot be empty',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: ProfileColors.error)),
                        ],
                      ),
                    ),
                  ),
                if (_linkedinController.text.trim().isNotEmpty &&
                    !_linkedinController.text.trim().startsWith('https://'))
                  InkWell(
                    onTap: () => _scrollToField(_linkedinKey),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 6, color: ProfileColors.error),
                          SizedBox(width: 6),
                          Text('LinkedIn link must start with https://',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: ProfileColors.error)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncompleteProfileCard(UserModel? user) {
    final pct = user?.completenessPercentage ?? 68;
    final missingReq = user?.missingRequiredFields ?? ['full_name'];
    final missingRec = user?.missingRecommendedFields ?? ['linkedin_url'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ProfileColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ProfileColors.secondary.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ProfileColors.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$pct%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ProfileColors.onSecondaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile is $pct% complete',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: ProfileColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Missing recommended: ${[...missingReq, ...missingRec].join(", ")}.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: ProfileColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100.0,
                    minHeight: 6,
                    backgroundColor: ProfileColors.surfaceContainerHigh,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(ProfileColors.secondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReassuranceBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ProfileColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_user_rounded,
              size: 22, color: ProfileColors.secondary),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Existing resumes remain protected',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ProfileColors.onSurface,
                  ),
                ),
                Text(
                  "Your live mock profiles & generated PDFs won't be modified until all fields validate cleanly.",
                  style: TextStyle(fontSize: 11, color: ProfileColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(UserModel? user, ProfileState state) {
    final initials = (user?.fullName?.isNotEmpty == true
            ? user!.fullName!
                .split(' ')
                .take(2)
                .map((e) => e.isNotEmpty ? e[0] : '')
                .join()
            : 'VC')
        .toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ProfileColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: ProfileColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: _localAvatarFile != null
                      ? Image.file(_localAvatarFile!, fit: BoxFit.cover)
                      : (user?.profileImage != null &&
                              user!.profileImage!.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: user.profileImage!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              errorWidget: (_, __, ___) => Center(
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: _pickPhoto,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: ProfileColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.photo_camera_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Profile photo',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'This account photo is purely for your dashboard & interview avatars. It won’t be added to resume PDFs unless enabled in templates.',
            style: TextStyle(fontSize: 12, color: ProfileColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add_a_photo_rounded, size: 16),
                label: const Text('Change photo'),
                onPressed: state.isAvatarUploading ? null : _pickPhoto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ProfileColors.surfaceContainerHigh,
                  foregroundColor: ProfileColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: (user?.profileImage != null &&
                        user!.profileImage!.isNotEmpty)
                    ? () => ref
                        .read(profileProvider.notifier)
                        .deleteProfileImage()
                    : null,
                style: TextButton.styleFrom(
                  foregroundColor: ProfileColors.outline,
                ),
                child: const Text('Remove'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicDetailsCard(ProfileState state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ProfileColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic details',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Core identity data synced across PrepMate AI modules',
                      style: TextStyle(fontSize: 12, color: ProfileColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.badge_outlined, color: ProfileColors.outline),
            ],
          ),
          const SizedBox(height: 16),

          // Full Name Input (required *)
          Container(
            key: _nameKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: const TextSpan(
                        text: 'Full name ',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ProfileColors.onSurface),
                        children: [
                          TextSpan(
                              text: '*',
                              style: TextStyle(color: ProfileColors.error)),
                        ],
                      ),
                    ),
                    const Text('Appears on resume headers',
                        style: TextStyle(
                            fontSize: 11, color: ProfileColors.outline)),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Full name cannot be empty. Please provide legal or preferred name.';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    suffixIcon: _nameController.text.trim().isNotEmpty
                        ? const Icon(Icons.check_circle_rounded,
                            color: ProfileColors.secondary)
                        : null,
                    hintText: 'Legal full name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: ProfileColors.outlineVariant),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Preferred Name Input
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Preferred first name',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('Used by AI coach',
                      style: TextStyle(fontSize: 11, color: ProfileColors.outline)),
                ],
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _preferredNameController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.waving_hand_outlined),
                  hintText: 'Nickname or preferred name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ProfileColors.outlineVariant),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Professional Title Input
          Container(
            key: _titleKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Professional title',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    Text('Default headline',
                        style: TextStyle(fontSize: 11, color: ProfileColors.outline)),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.work_outline_rounded),
                    hintText: 'e.g. Senior Mobile & Flutter Engineer',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: ProfileColors.outlineVariant),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Location Sub-Grid: City & State
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('City',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.location_city_rounded),
                        hintText: 'Austin',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: ProfileColors.outlineVariant),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('State / Region',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _stateRegionController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.map_outlined),
                        hintText: 'Texas',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: ProfileColors.outlineVariant),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Country / Jurisdiction Selector
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Country / Jurisdiction',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  final chosen = await CountrySelectionSheet.show(
                    context,
                    currentCountry: _countryController.text,
                    countries: state.profileMetadata.countries,
                  );
                  if (chosen != null && mounted) {
                    setState(() {
                      _countryController.text = chosen.name;
                      _countryCodeController.text = chosen.code;
                      _isDirty = true;
                    });
                    _onFieldChanged();
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: ProfileColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ProfileColors.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.public_rounded,
                          color: ProfileColors.outline),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _countryController.text.isNotEmpty
                              ? _countryController.text
                              : 'Select country...',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const Icon(Icons.unfold_more_rounded,
                          color: ProfileColors.outline),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Industry Picker
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Industry',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  final chosen = await IndustrySelectionSheet.show(
                    context,
                    currentIndustry: _industryController.text,
                    industries: state.profileMetadata.industries,
                  );
                  if (chosen != null && mounted) {
                    setState(() {
                      _industryController.text = chosen.name;
                      _isDirty = true;
                    });
                    _onFieldChanged();
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: ProfileColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ProfileColors.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.domain_rounded,
                          color: ProfileColors.outline),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _industryController.text.isNotEmpty
                              ? _industryController.text
                              : 'Select industry...',
                          style: const TextStyle(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.unfold_more_rounded,
                          color: ProfileColors.outline),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Time Zone (Read-only / lock)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Time zone',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('Mock Interview Sync',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: ProfileColors.secondary)),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: ProfileColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        color: ProfileColors.outline),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _timeZoneController.text.isNotEmpty
                            ? _timeZoneController.text
                            : 'Central Time · UTC-05:00',
                        style: const TextStyle(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.lock_outline_rounded,
                        size: 16, color: ProfileColors.outline),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedContactCard(UserModel? user) {
    final phone = user?.maskedPhone ??
        (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty
            ? '+91 ••••• ${user.phoneNumber!.substring(user.phoneNumber!.length - 4)}'
            : '+91 ••••• 99999');
    final email = user?.email ?? 'vikash.c@devmail.io';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ProfileColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: ProfileColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.verified_user_rounded,
                    color: ProfileColors.onSecondaryContainer, size: 18),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verified contact',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Linked to your security login credentials',
                    style: TextStyle(
                        fontSize: 12, color: ProfileColors.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Primary Phone row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ProfileColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('PRIMARY PHONE',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: ProfileColors.onSurfaceVariant)),
                    Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 14, color: ProfileColors.secondary),
                        SizedBox(width: 4),
                        Text('Verified',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: ProfileColors.secondary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.smartphone_rounded,
                            size: 18, color: ProfileColors.outline),
                        const SizedBox(width: 8),
                        Text(
                          phone,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        ChangePhoneModal.show(context, currentPhone: phone);
                      },
                      child: const Row(
                        children: [
                          Text('Change',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: ProfileColors.primary)),
                          Icon(Icons.chevron_right_rounded,
                              size: 16, color: ProfileColors.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Primary Email row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ProfileColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('PRIMARY EMAIL',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: ProfileColors.onSurfaceVariant)),
                    Row(
                      children: [
                        Icon(Icons.verified_rounded,
                            size: 14, color: ProfileColors.secondary),
                        SizedBox(width: 4),
                        Text('Confirmed',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: ProfileColors.secondary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.mail_outline_rounded,
                            size: 18, color: ProfileColors.outline),
                        const SizedBox(width: 8),
                        Text(
                          email,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: ProfileColors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('Primary',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 15, color: ProfileColors.outline),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'To prevent identity theft, phone and email updates require multi-step verification confirmation.',
                  style: TextStyle(fontSize: 11, color: ProfileColors.outline),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalLinksCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ProfileColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Social & professional links',
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Imported automatically into resume contact blocks',
                        style: TextStyle(
                            fontSize: 12, color: ProfileColors.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Custom Link'),
                onPressed: _addCustomLink,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // LinkedIn Field with validation & prefix fixer
          Container(
            key: _linkedinKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        CircleAvatar(radius: 4, backgroundColor: ProfileColors.primary),
                        SizedBox(width: 6),
                        Text('LinkedIn Profile',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    if (_linkedinController.text.trim().isNotEmpty &&
                        !_linkedinController.text.trim().startsWith('https://'))
                      InkWell(
                        onTap: _quickFixLinkedin,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: ProfileColors.primaryContainer.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Fix prefix',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: ProfileColors.primary)),
                        ),
                      )
                    else
                      const Row(
                        children: [
                          Icon(Icons.link_rounded,
                              size: 14, color: ProfileColors.secondary),
                          SizedBox(width: 2),
                          Text('Reachable',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: ProfileColors.secondary)),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _linkedinController,
                  keyboardType: TextInputType.url,
                  validator: (val) {
                    if (val != null &&
                        val.trim().isNotEmpty &&
                        !val.trim().startsWith('https://')) {
                      return 'LinkedIn link must start with https://';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.public_rounded),
                    suffixIcon: _linkedinController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18),
                            onPressed: () {
                              _linkedinController.clear();
                              _onFieldChanged();
                            },
                          )
                        : null,
                    hintText: 'https://linkedin.com/in/username',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: ProfileColors.outlineVariant),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // GitHub Field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                          radius: 4, backgroundColor: ProfileColors.onSurface),
                      SizedBox(width: 6),
                      Text('GitHub Portfolio',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.code_rounded,
                          size: 14, color: ProfileColors.secondary),
                      SizedBox(width: 2),
                      Text('Indexed',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: ProfileColors.secondary)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _githubController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.terminal_rounded),
                  suffixIcon: _githubController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18),
                          onPressed: () {
                            _githubController.clear();
                            _onFieldChanged();
                          },
                        )
                      : null,
                  hintText: 'https://github.com/username',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ProfileColors.outlineVariant),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Personal Portfolio Website
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                          radius: 4, backgroundColor: ProfileColors.secondary),
                      SizedBox(width: 6),
                      Text('Personal Website',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.language_rounded,
                          size: 14, color: ProfileColors.secondary),
                      SizedBox(width: 2),
                      Text('Active SSL',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: ProfileColors.secondary)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _portfolioController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.language_rounded),
                  suffixIcon: _portfolioController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18),
                          onPressed: () {
                            _portfolioController.clear();
                            _onFieldChanged();
                          },
                        )
                      : null,
                  hintText: 'https://yourwebsite.dev',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ProfileColors.outlineVariant),
                  ),
                ),
              ),
            ],
          ),

          // Custom links dynamically added
          if (_customLinks.isNotEmpty) ...[
            const SizedBox(height: 14),
            ..._customLinks.map((link) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: ProfileColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link_rounded,
                          size: 18, color: ProfileColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(link['label'] ?? 'Custom Link',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                            Text(link['url'] ?? '',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: ProfileColors.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        onPressed: () {
                          setState(() {
                            _customLinks.remove(link);
                            _isDirty = true;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildResumeDefaultsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ProfileColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, color: ProfileColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Defaults for new resumes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Control what pre-fills when you generate a new job-specific resume draft. These settings affect newly created resumes only. Existing resumes will not change.',
            style: TextStyle(
                fontSize: 12, color: ProfileColors.onSurfaceVariant, height: 1.35),
          ),
          const SizedBox(height: 14),

          // Switch 1: Name
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Use my name for new resumes',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      Text('Placed on top banner',
                          style: TextStyle(fontSize: 11, color: ProfileColors.outline)),
                    ],
                  ),
                ),
                Switch(
                  value: _useNameForNewResumes,
                  activeColor: ProfileColors.primary,
                  onChanged: (val) {
                    setState(() {
                      _useNameForNewResumes = val;
                      _isDirty = true;
                    });
                    _onFieldChanged();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Switch 2: Title
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Use my professional title',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      Text('Apply headline subtitle',
                          style: TextStyle(fontSize: 11, color: ProfileColors.outline)),
                    ],
                  ),
                ),
                Switch(
                  value: _useTitleForNewResumes,
                  activeColor: ProfileColors.primary,
                  onChanged: (val) {
                    setState(() {
                      _useTitleForNewResumes = val;
                      _isDirty = true;
                    });
                    _onFieldChanged();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Switch 3: Location
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Use my location for new resumes',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      Text('Include city & state in summary meta',
                          style: TextStyle(fontSize: 11, color: ProfileColors.outline)),
                    ],
                  ),
                ),
                Switch(
                  value: _useLocationForNewResumes,
                  activeColor: ProfileColors.primary,
                  onChanged: (val) {
                    setState(() {
                      _useLocationForNewResumes = val;
                      _isDirty = true;
                    });
                    _onFieldChanged();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Switch 4: Professional links
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Suggest professional links',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(
                          'Include active LinkedIn, GitHub, and Portfolio URLs',
                          style: TextStyle(fontSize: 11, color: ProfileColors.outline)),
                    ],
                  ),
                ),
                Switch(
                  value: _suggestLinksForNewResumes,
                  activeColor: ProfileColors.primary,
                  onChanged: (val) {
                    setState(() {
                      _suggestLinksForNewResumes = val;
                      _isDirty = true;
                    });
                    _onFieldChanged();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivateVaultCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ProfileColors.surfaceContainerHigh.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_rounded,
                  size: 20, color: ProfileColors.primary),
              SizedBox(width: 8),
              Text('Private Profile Vault',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Your PrepMate master profile is private and never visible as a public candidate URL. AI recommendations process strictly in isolated sandboxes.',
            style: TextStyle(
                fontSize: 12, color: ProfileColors.onSurfaceVariant, height: 1.35),
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              InkWell(
                onTap: () => context.push('/help'),
                child: const Text('Privacy controls',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: ProfileColors.primary)),
              ),
              const Text('•', style: TextStyle(color: ProfileColors.outline)),
              InkWell(
                onTap: () {
                  ref.read(profileProvider.notifier).requestExport();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Data export requested. Check your email.')),
                  );
                },
                child: const Text('Download personal data archive',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: ProfileColors.primary)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomActionBar(ProfileState state, bool hasErrors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: BoxDecoration(
        color: ProfileColors.surfaceContainerLowest.withOpacity(0.96),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasErrors) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.priority_high_rounded,
                            size: 16, color: ProfileColors.error),
                        SizedBox(width: 4),
                        Text('Items need attention',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: ProfileColors.error)),
                      ],
                    ),
                    InkWell(
                      onTap: () => _scrollToField(_nameKey),
                      child: const Row(
                        children: [
                          Text('Jump to error',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: ProfileColors.primary)),
                          Icon(Icons.arrow_downward_rounded,
                              size: 14, color: ProfileColors.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              children: [
                OutlinedButton(
                  onPressed: () async {
                    final leave = await _handleLeaveProtection();
                    if (leave && mounted) {
                      _hydrateFromUser(ref.read(profileProvider).user);
                      setState(() {
                        _isDirty = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Changes discarded.')),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Discard'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: state.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded, size: 20),
                      label: Text(
                        state.isLoading ? 'Saving...' : 'Save Changes',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onPressed:
                          (state.isLoading || (!_isDirty && !hasErrors))
                              ? null
                              : _handleExplicitSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ProfileColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            ProfileColors.primary.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
