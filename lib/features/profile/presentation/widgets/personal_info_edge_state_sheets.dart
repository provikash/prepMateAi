import 'package:flutter/material.dart';
import 'profile_colors.dart';
import '../../domain/entities/profile_lifecycle_models.dart';

/// Screen 84: Edge States & Conflict Recovery Components

// ---------------------------------------------------------------------------
// 1. Conflict Resolution Card / Sheet (State 1)
// ---------------------------------------------------------------------------
class ConflictResolutionCard extends StatefulWidget {
  const ConflictResolutionCard({
    super.key,
    required this.serverData,
    required this.localData,
    required this.serverVersion,
    required this.onResolve,
    required this.onCancel,
  });

  final Map<String, dynamic> serverData;
  final Map<String, dynamic> localData;
  final int serverVersion;
  final ValueChanged<Map<String, dynamic>> onResolve;
  final VoidCallback onCancel;

  @override
  State<ConflictResolutionCard> createState() => _ConflictResolutionCardState();
}

class _ConflictResolutionCardState extends State<ConflictResolutionCard> {
  // Field name -> 'local' | 'server'
  final Map<String, String> _choices = {};
  late List<String> _conflictFields;

  @override
  void initState() {
    super.initState();
    _conflictFields = _detectConflicts();
    for (final field in _conflictFields) {
      _choices[field] = 'local'; // default to local
    }
  }

  List<String> _detectConflicts() {
    final fields = <String>{};
    final relevantKeys = [
      'full_name',
      'preferred_name',
      'job_title',
      'city',
      'state_region',
      'country',
      'industry',
      'linkedin',
      'github',
      'portfolio_url',
    ];

    for (final key in relevantKeys) {
      final sVal = widget.serverData[key]?.toString().trim() ?? '';
      final lVal = widget.localData[key]?.toString().trim() ?? '';
      if (sVal.isNotEmpty && lVal.isNotEmpty && sVal != lVal) {
        fields.add(key);
      }
    }

    if (fields.isEmpty) {
      fields.addAll(['job_title', 'location']);
    }
    return fields.toList();
  }

  void _batchResolve(String winner) {
    setState(() {
      for (final f in _conflictFields) {
        _choices[f] = winner;
      }
    });
  }

  void _confirm() {
    final resolved = <String, dynamic>{};
    for (final f in _conflictFields) {
      final pick = _choices[f] ?? 'local';
      if (pick == 'server') {
        resolved[f] = widget.serverData[f];
      } else {
        resolved[f] = widget.localData[f];
      }
    }
    resolved['version'] = widget.serverVersion;
    widget.onResolve(resolved);
  }

  String _formatLabel(String field) {
    switch (field) {
      case 'job_title':
        return 'Professional Title';
      case 'location':
        return 'Location';
      case 'full_name':
        return 'Full Name';
      case 'preferred_name':
        return 'Preferred Name';
      case 'city':
        return 'City';
      case 'state_region':
        return 'State / Region';
      case 'country':
        return 'Country';
      case 'industry':
        return 'Industry';
      case 'linkedin':
        return 'LinkedIn Profile';
      case 'github':
        return 'GitHub Portfolio';
      case 'portfolio_url':
        return 'Personal Website';
      default:
        return field.replaceAll('_', ' ').toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ProfileColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE2BA), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning Alert Hero Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE2BA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sync_problem_rounded,
                    color: Color(0xFFA15C00),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: Text(
                              'Profile changed on another device',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5B3300),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE2BA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Cloud Sync',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5B3300),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Updated from PrepMate Web. Select which version of each field you want to preserve.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7A4500),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Comparison Header
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'Conflicting Fields (${_conflictFields.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Text(
                'Tap to pick winner',
                style: TextStyle(fontSize: 12, color: ProfileColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Fields list
          ..._conflictFields.map((field) {
            final isServer = _choices[field] == 'server';
            final sVal = widget.serverData[field]?.toString() ?? 'Staff Flutter Architect';
            final lVal = widget.localData[field]?.toString() ?? 'Senior Mobile & Flutter Engineer';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ProfileColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatLabel(field),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ProfileColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Text Field',
                              style: TextStyle(fontSize: 10)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Server Option
                    InkWell(
                      onTap: () {
                        setState(() {
                          _choices[field] = 'server';
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isServer
                              ? ProfileColors.primaryContainer.withOpacity(0.16)
                              : ProfileColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isServer
                                ? ProfileColors.primary
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.laptop_mac_rounded,
                                          size: 14,
                                          color: ProfileColors.onSurfaceVariant),
                                      SizedBox(width: 4),
                                      Text(
                                        'SERVER VALUE (WEB)',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: ProfileColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    sVal,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Text(
                                    'Cloud version v1',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: ProfileColors.outline),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 32,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10),
                              decoration: BoxDecoration(
                                color: isServer
                                    ? ProfileColors.primary
                                    : ProfileColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                isServer ? 'Selected' : 'Select',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isServer
                                      ? Colors.white
                                      : ProfileColors.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Local Option
                    InkWell(
                      onTap: () {
                        setState(() {
                          _choices[field] = 'local';
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: !isServer
                              ? ProfileColors.primaryContainer.withOpacity(0.16)
                              : ProfileColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: !isServer
                                ? ProfileColors.primary
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.smartphone_rounded,
                                          size: 14, color: ProfileColors.primary),
                                      SizedBox(width: 4),
                                      Text(
                                        'LOCAL VALUE (THIS PHONE)',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: ProfileColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    lVal,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Text(
                                    'Edited recently · Unsynced edits',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: ProfileColors.outline),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 32,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10),
                              decoration: BoxDecoration(
                                color: !isServer
                                    ? ProfileColors.primary
                                    : ProfileColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                !isServer ? 'Selected' : 'Select',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: !isServer
                                      ? Colors.white
                                      : ProfileColors.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          // Batch Shortcuts
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ProfileColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Batch Resolution Shortcuts:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.phone_android_rounded, size: 16),
                        label: const Text('Keep local',
                            style: TextStyle(fontSize: 12)),
                        onPressed: () => _batchResolve('local'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.cloud_download_rounded, size: 16),
                        label: const Text('Accept cloud',
                            style: TextStyle(fontSize: 12)),
                        onPressed: () => _batchResolve('server'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Confirm Resolution Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.published_with_changes_rounded, size: 18),
              label: const Text('Confirm & Synchronize Changes',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: ProfileColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Offline Draft Queue Card (State 2)
// ---------------------------------------------------------------------------
class OfflineDraftCard extends StatelessWidget {
  const OfflineDraftCard({
    super.key,
    required this.queue,
    required this.onRetry,
    required this.onClear,
  });

  final List<OfflineDraftItem> queue;
  final VoidCallback onRetry;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ProfileColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE2BA), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE2BA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    color: Color(0xFFA15C00),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "You're currently offline",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5B3300),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Changes are securely stored as a local draft. PrepMate will automatically sync to cloud when you re-establish network connection.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7A4500),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Draft Queue Card
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_note_rounded, size: 20, color: ProfileColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Local Draft Queue',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ProfileColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${queue.length} modifications queued',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (queue.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ProfileColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'No pending local edits.',
                style: TextStyle(fontSize: 12, color: ProfileColors.outline),
              ),
            ),
          ] else ...[
            ...queue.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ProfileColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          size: 16, color: ProfileColors.secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.label} updated',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Value: "${item.displayValue}"',
                              style: const TextStyle(
                                  fontSize: 11, color: ProfileColors.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'Ready',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: ProfileColors.secondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Diagnostic check row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 16, color: ProfileColors.outline),
                  SizedBox(width: 4),
                  Text(
                    'Offline local storage',
                    style: TextStyle(fontSize: 11, color: ProfileColors.outline),
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry Connection', style: TextStyle(fontSize: 12)),
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ProfileColors.surfaceContainerHigh,
                  foregroundColor: ProfileColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Post-Save Cascading Update Sheet (State 3)
// ---------------------------------------------------------------------------
class CascadingResumesSheet extends StatefulWidget {
  const CascadingResumesSheet({
    super.key,
    required this.jobTitle,
    required this.location,
    required this.onApply,
    required this.onSkip,
  });

  final String jobTitle;
  final String location;
  final ValueChanged<List<String>> onApply;
  final VoidCallback onSkip;

  static Future<void> show(
    BuildContext context, {
    required String jobTitle,
    required String location,
    required ValueChanged<List<String>> onApply,
    required VoidCallback onSkip,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CascadingResumesSheet(
        jobTitle: jobTitle,
        location: location,
        onApply: (ids) {
          Navigator.of(ctx).pop();
          onApply(ids);
        },
        onSkip: () {
          Navigator.of(ctx).pop();
          onSkip();
        },
      ),
    );
  }

  @override
  State<CascadingResumesSheet> createState() => _CascadingResumesSheetState();
}

class _CascadingResumesSheetState extends State<CascadingResumesSheet> {
  // STRICT OPT-IN: None pre-selected!
  final Set<String> _selectedResumeIds = {};

  final List<Map<String, String>> _sampleResumes = [
    {
      'id': 'res-1',
      'title': 'Senior Flutter Lead 2026',
      'subtitle': 'Last modified 3 days ago · 94% ATS Match',
    },
    {
      'id': 'res-2',
      'title': 'Mobile Architect ATS',
      'subtitle': 'Last modified Yesterday · 89% ATS Match',
    },
    {
      'id': 'res-3',
      'title': 'Staff Engineering - Fintech',
      'subtitle': 'Last modified Oct 12 · 91% ATS Match',
    },
    {
      'id': 'res-4',
      'title': 'Universal General Tech (Base)',
      'subtitle': 'Last modified 1 mo ago · 82% ATS Match',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final count = _selectedResumeIds.length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: ProfileColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ProfileColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Success Headline Toast
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4EA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded,
                    color: Color(0xFF137333), size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profile changes saved!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D652D),
                        ),
                      ),
                      Text(
                        'Master profile updated to "${widget.jobTitle.isNotEmpty ? widget.jobTitle : "Professional Title"}" in ${widget.location.isNotEmpty ? widget.location : "Location"}.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF137333),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Update Selected Resumes?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Would you like to cascade your updated title and location across any of your tailored resumes? (Strict opt-in: only checked resumes will update)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ProfileColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          // Resumes Checklist
          Column(
            children: _sampleResumes.map((resume) {
              final id = resume['id']!;
              final isChecked = _selectedResumeIds.contains(id);

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (isChecked) {
                        _selectedResumeIds.remove(id);
                      } else {
                        _selectedResumeIds.add(id);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: ProfileColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: ProfileColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.description_rounded,
                              color: ProfileColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                resume['title']!,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                resume['subtitle']!,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: ProfileColors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Checkbox(
                          value: isChecked,
                          activeColor: ProfileColors.primary,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedResumeIds.add(id);
                              } else {
                                _selectedResumeIds.remove(id);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Decision buttons
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.sync_rounded, size: 18),
              label: Text('Apply Updates to Selected ($count)',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              onPressed: count > 0
                  ? () => widget.onApply(_selectedResumeIds.toList())
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: ProfileColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton(
              onPressed: widget.onSkip,
              child: const Text('Keep Resumes Unchanged (Skip)'),
            ),
          ),
          const SizedBox(height: 6),
          const Row(
            children: [
              Icon(Icons.shield_rounded, size: 14, color: ProfileColors.secondary),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Tailored resume versions preserve custom work history and bullet formulations.',
                  style: TextStyle(fontSize: 11, color: ProfileColors.outline),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
