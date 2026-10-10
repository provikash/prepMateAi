import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'profile_colors.dart';
import '../providers/profile_provider.dart';
import '../../domain/entities/profile_lifecycle_models.dart';

/// Screen 83: Modal Sheets & Dialogs for Personal Information

// ---------------------------------------------------------------------------
// 1. Country Selection Sheet
// ---------------------------------------------------------------------------
class CountrySelectionSheet extends StatefulWidget {
  const CountrySelectionSheet({
    super.key,
    required this.currentCountry,
    required this.onSelected,
    this.countries = const [],
  });

  final String currentCountry;
  final ValueChanged<CountryOption?> onSelected;
  final List<CountryOption> countries;

  static Future<CountryOption?> show(
    BuildContext context, {
    required String currentCountry,
    List<CountryOption> countries = const [],
  }) {
    return showModalBottomSheet<CountryOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CountrySelectionSheet(
        currentCountry: currentCountry,
        countries: countries,
        onSelected: (option) => Navigator.of(ctx).pop(option),
      ),
    );
  }

  @override
  State<CountrySelectionSheet> createState() => _CountrySelectionSheetState();
}

class _CountrySelectionSheetState extends State<CountrySelectionSheet> {
  final TextEditingController _searchController = TextEditingController();
  late List<CountryOption> _allCountries;
  List<CountryOption> _filteredCountries = [];
  CountryOption? _selectedOption;

  static const List<CountryOption> _defaultCountries = [
    CountryOption(name: 'United States', code: 'US', dialCode: '+1', flag: '🇺🇸'),
    CountryOption(name: 'Canada', code: 'CA', dialCode: '+1', flag: '🇨🇦'),
    CountryOption(name: 'United Kingdom', code: 'GB', dialCode: '+44', flag: '🇬🇧'),
    CountryOption(name: 'India', code: 'IN', dialCode: '+91', flag: '🇮🇳'),
    CountryOption(name: 'Germany', code: 'DE', dialCode: '+49', flag: '🇩🇪'),
    CountryOption(name: 'Australia', code: 'AU', dialCode: '+61', flag: '🇦🇺'),
    CountryOption(name: 'Singapore', code: 'SG', dialCode: '+65', flag: '🇸🇬'),
    CountryOption(name: 'France', code: 'FR', dialCode: '+33', flag: '🇫🇷'),
    CountryOption(name: 'Netherlands', code: 'NL', dialCode: '+31', flag: '🇳🇱'),
    CountryOption(name: 'Ireland', code: 'IE', dialCode: '+353', flag: '🇮🇪'),
    CountryOption(name: 'Japan', code: 'JP', dialCode: '+81', flag: '🇯🇵'),
    CountryOption(name: 'United Arab Emirates', code: 'AE', dialCode: '+971', flag: '🇦🇪'),
    CountryOption(name: 'Switzerland', code: 'CH', dialCode: '+41', flag: '🇨🇭'),
    CountryOption(name: 'Sweden', code: 'SE', dialCode: '+46', flag: '🇸🇪'),
    CountryOption(name: 'Spain', code: 'ES', dialCode: '+34', flag: '🇪🇸'),
  ];

  @override
  void initState() {
    super.initState();
    _allCountries = widget.countries.isNotEmpty ? widget.countries : _defaultCountries;
    _filteredCountries = List.from(_allCountries);

    final currentLower = widget.currentCountry.toLowerCase().trim();
    for (final opt in _allCountries) {
      if (opt.name.toLowerCase() == currentLower ||
          opt.code.toLowerCase() == currentLower) {
        _selectedOption = opt;
        break;
      }
    }

    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = List.from(_allCountries);
      } else {
        _filteredCountries = _allCountries.where((c) {
          return c.name.toLowerCase().contains(query) ||
              c.code.toLowerCase().contains(query) ||
              c.dialCode.contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: ProfileColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ProfileColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PREFERENCES',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: ProfileColors.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Select country or region',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Search box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: ProfileColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search country or region...',
                  prefixIcon: const Icon(Icons.search_rounded, color: ProfileColors.outline),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.cancel_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          // Country list
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: _filteredCountries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                final isSelected = _selectedOption?.code == country.code;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedOption = country;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ProfileColors.primaryContainer.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? ProfileColors.primaryFixed
                                : ProfileColors.surfaceContainerHigh,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            country.flag.isNotEmpty ? country.flag : country.code,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                country.name,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${country.code} · ${country.dialCode}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: ProfileColors.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: ProfileColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Disclaimer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ProfileColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 18, color: ProfileColors.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Country selection indicates your primary job search location and does not infer citizenship or nationality.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ProfileColors.onSurfaceVariant,
                            height: 1.3,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Action Buttons
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onSelected(_selectedOption);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ProfileColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Confirm selection',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          SizedBox(width: 8),
                          Icon(Icons.check_circle_outline_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () {
                      widget.onSelected(null);
                    },
                    child: const Text('Clear selection'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Photo Action Sheet
// ---------------------------------------------------------------------------
enum PhotoActionChoice {
  takePhoto,
  chooseFromGallery,
  viewPhoto,
  removePhoto,
}

class PhotoActionSheet extends StatelessWidget {
  const PhotoActionSheet({
    super.key,
    required this.hasExistingPhoto,
    this.imageUrl,
    required this.onChoice,
  });

  final bool hasExistingPhoto;
  final String? imageUrl;
  final ValueChanged<PhotoActionChoice> onChoice;

  static Future<PhotoActionChoice?> show(
    BuildContext context, {
    required bool hasExistingPhoto,
    String? imageUrl,
  }) {
    return showModalBottomSheet<PhotoActionChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PhotoActionSheet(
        hasExistingPhoto: hasExistingPhoto,
        imageUrl: imageUrl,
        onChoice: (choice) => Navigator.of(ctx).pop(choice),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ProfileColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ProfileColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MEDIA UPLOAD',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: ProfileColors.secondary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Profile Photo',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Avatar Thumbnail
          if (imageUrl != null && imageUrl!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(48),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 80,
                      height: 80,
                      color: ProfileColors.surfaceContainerHigh,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: ProfileColors.primaryContainer,
                      child: const Icon(Icons.person, color: Colors.white, size: 36),
                    ),
                  ),
                ),
              ),
            ),
          ],
          // Action list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                _actionTile(
                  context,
                  icon: Icons.photo_camera_rounded,
                  iconBg: ProfileColors.primaryFixed,
                  iconColor: ProfileColors.primary,
                  title: 'Take photo',
                  subtitle: 'Use camera for an instant shot',
                  onTap: () => onChoice(PhotoActionChoice.takePhoto),
                ),
                const SizedBox(height: 8),
                _actionTile(
                  context,
                  icon: Icons.photo_library_rounded,
                  iconBg: ProfileColors.secondaryContainer,
                  iconColor: ProfileColors.secondary,
                  title: 'Choose from gallery',
                  subtitle: 'Upload PNG, JPG or WebP image',
                  onTap: () => onChoice(PhotoActionChoice.chooseFromGallery),
                ),
                if (hasExistingPhoto) ...[
                  const SizedBox(height: 8),
                  _actionTile(
                    context,
                    icon: Icons.visibility_rounded,
                    iconBg: ProfileColors.surfaceContainerHigh,
                    iconColor: ProfileColors.onSurface,
                    title: 'View photo',
                    subtitle: 'Enlarge current avatar picture',
                    onTap: () => onChoice(PhotoActionChoice.viewPhoto),
                  ),
                  const SizedBox(height: 8),
                  _actionTile(
                    context,
                    icon: Icons.delete_outline_rounded,
                    iconBg: ProfileColors.errorContainer,
                    iconColor: ProfileColors.error,
                    title: 'Remove photo',
                    subtitle: 'Revert back to system initials badge',
                    isDestructive: true,
                    onTap: () => onChoice(PhotoActionChoice.removePhoto),
                  ),
                ],
              ],
            ),
          ),
          // Cancel button
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: ProfileColors.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _actionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isDestructive
              ? ProfileColors.errorContainer.withOpacity(0.3)
              : ProfileColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDestructive ? ProfileColors.error : ProfileColors.onSurface,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDestructive
                              ? ProfileColors.error.withOpacity(0.8)
                              : ProfileColors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Avatar Crop & Preview Dialog
// ---------------------------------------------------------------------------
class AvatarCropDialog extends StatefulWidget {
  const AvatarCropDialog({
    super.key,
    required this.imageFile,
    required this.onConfirm,
  });

  final File imageFile;
  final ValueChanged<File> onConfirm;

  static Future<File?> show(BuildContext context, {required File imageFile}) {
    return showDialog<File>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AvatarCropDialog(
        imageFile: imageFile,
        onConfirm: (file) => Navigator.of(ctx).pop(file),
      ),
    );
  }

  @override
  State<AvatarCropDialog> createState() => _AvatarCropDialogState();
}

class _AvatarCropDialogState extends State<AvatarCropDialog> {
  double _zoom = 1.0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: ProfileColors.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Crop Photo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ProfileColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('1:1 Aspect', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Crop circular preview container
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ProfileColors.primary, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ClipOval(
                child: Transform.scale(
                  scale: _zoom,
                  child: Image.file(
                    widget.imageFile,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Zoom slider
            Row(
              children: [
                const Icon(Icons.zoom_out_rounded, size: 20, color: ProfileColors.outline),
                Expanded(
                  child: Slider(
                    value: _zoom,
                    min: 1.0,
                    max: 2.5,
                    activeColor: ProfileColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _zoom = val;
                      });
                    },
                  ),
                ),
                const Icon(Icons.zoom_in_rounded, size: 20, color: ProfileColors.outline),
              ],
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _zoom = 1.0;
                });
              },
              child: const Text('Reset Zoom'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onConfirm(widget.imageFile);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ProfileColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Use Photo'),
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

// ---------------------------------------------------------------------------
// 4. Leave Confirmation Dialog
// ---------------------------------------------------------------------------
class LeaveConfirmationDialog extends StatelessWidget {
  const LeaveConfirmationDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => const LeaveConfirmationDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: ProfileColors.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: ProfileColors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                size: 32,
                color: ProfileColors.onErrorContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Discard unsaved changes?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You modified your personal info and preferences. Leaving now will reset these unsaved edits.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ProfileColors.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ProfileColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      size: 18, color: ProfileColors.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'PrepMate auto-saves your progress whenever changes validate successfully.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ProfileColors.error,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Discard changes',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      backgroundColor: ProfileColors.surfaceContainerHigh,
                      foregroundColor: ProfileColors.onSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Keep editing',
                        style: TextStyle(fontWeight: FontWeight.w600)),
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

// ---------------------------------------------------------------------------
// 5. Industry Selection Sheet
// ---------------------------------------------------------------------------
class IndustrySelectionSheet extends StatefulWidget {
  const IndustrySelectionSheet({
    super.key,
    required this.currentIndustry,
    required this.onSelected,
    this.industries = const [],
  });

  final String currentIndustry;
  final ValueChanged<IndustryOption> onSelected;
  final List<IndustryOption> industries;

  static Future<IndustryOption?> show(
    BuildContext context, {
    required String currentIndustry,
    List<IndustryOption> industries = const [],
  }) {
    return showModalBottomSheet<IndustryOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => IndustrySelectionSheet(
        currentIndustry: currentIndustry,
        industries: industries,
        onSelected: (option) => Navigator.of(ctx).pop(option),
      ),
    );
  }

  @override
  State<IndustrySelectionSheet> createState() => _IndustrySelectionSheetState();
}

class _IndustrySelectionSheetState extends State<IndustrySelectionSheet> {
  final TextEditingController _searchController = TextEditingController();
  late List<IndustryOption> _allIndustries;
  List<IndustryOption> _filteredIndustries = [];

  static const List<IndustryOption> _defaultIndustries = [
    IndustryOption(name: 'Software Engineering & Mobile Development', category: 'Technology'),
    IndustryOption(name: 'Product Design & UX/UI', category: 'Design'),
    IndustryOption(name: 'Product Management', category: 'Product'),
    IndustryOption(name: 'Data Science & AI / ML', category: 'Data'),
    IndustryOption(name: 'Cloud Architecture & DevOps', category: 'Technology'),
    IndustryOption(name: 'Finance & Fintech', category: 'Finance'),
    IndustryOption(name: 'Healthcare & Biotechnology', category: 'Healthcare'),
    IndustryOption(name: 'Cybersecurity', category: 'Security'),
    IndustryOption(name: 'Sales & Business Development', category: 'Business'),
    IndustryOption(name: 'Marketing & Content Strategy', category: 'Marketing'),
  ];

  @override
  void initState() {
    super.initState();
    _allIndustries = widget.industries.isNotEmpty ? widget.industries : _defaultIndustries;
    _filteredIndustries = List.from(_allIndustries);
    _searchController.addListener(_filter);
  }

  void _filter() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredIndustries = List.from(_allIndustries);
      } else {
        _filteredIndustries = _allIndustries.where((i) {
          return i.name.toLowerCase().contains(query) ||
              i.category.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: ProfileColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ProfileColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CAREER SECTOR',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: ProfileColors.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Select Industry',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: ProfileColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search industry or domain...',
                  prefixIcon: Icon(Icons.search_rounded, color: ProfileColors.outline),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: _filteredIndustries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final item = _filteredIndustries[index];
                final isSelected = widget.currentIndustry == item.name;

                return InkWell(
                  onTap: () => widget.onSelected(item),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ProfileColors.primaryContainer.withOpacity(0.12)
                          : ProfileColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: ProfileColors.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.category,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: ProfileColors.onSurfaceVariant),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded,
                              color: ProfileColors.primary, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. Protected Phone Change Modal Flow
// ---------------------------------------------------------------------------
class ChangePhoneModal extends ConsumerStatefulWidget {
  const ChangePhoneModal({
    super.key,
    required this.currentPhone,
  });

  final String currentPhone;

  static Future<bool?> show(BuildContext context, {required String currentPhone}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: ChangePhoneModal(currentPhone: currentPhone),
      ),
    );
  }

  @override
  ConsumerState<ChangePhoneModal> createState() => _ChangePhoneModalState();
}

class _ChangePhoneModalState extends ConsumerState<ChangePhoneModal> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _otpSent = false;
  String _selectedDialCode = '+91';

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final rawNumber = _phoneController.text.trim();
    if (rawNumber.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number.')),
      );
      return;
    }
    final fullNumber = '$_selectedDialCode$rawNumber';
    final success = await ref
        .read(profileProvider.notifier)
        .requestPhoneChange(fullNumber);

    if (mounted) {
      if (success) {
        setState(() {
          _otpSent = true;
        });
      } else {
        final err = ref.read(profileProvider).phoneChangeError;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err ?? 'Could not request phone change.')),
        );
      }
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP received.')),
      );
      return;
    }
    final fullNumber = '$_selectedDialCode${_phoneController.text.trim()}';
    final success = await ref
        .read(profileProvider.notifier)
        .verifyPhoneChange(fullNumber, otp);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        final err = ref.read(profileProvider).phoneChangeError;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err ?? 'Verification failed.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: ProfileColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.verified_user_rounded,
                        color: ProfileColors.onSecondaryContainer, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Change Mobile Number',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Current number: ${widget.currentPhone}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ProfileColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          if (!_otpSent) ...[
            Text(
              'New Mobile Number',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 52,
              decoration: BoxDecoration(
                color: ProfileColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButton<String>(
                      value: _selectedDialCode,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: '+1', child: Text('🇺🇸 +1')),
                        DropdownMenuItem(value: '+44', child: Text('🇬🇧 +44')),
                        DropdownMenuItem(value: '+91', child: Text('🇮🇳 +91')),
                        DropdownMenuItem(value: '+49', child: Text('🇩🇪 +49')),
                        DropdownMenuItem(value: '+61', child: Text('🇦🇺 +61')),
                        DropdownMenuItem(value: '+65', child: Text('🇸🇬 +65')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedDialCode = val;
                          });
                        }
                      },
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: 'New 10-digit number',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ProfileColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_rounded, size: 18, color: ProfileColors.secondary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'For security, updating your number requires verification and will revoke existing sessions.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: state.isPhoneChangeLoading ? null : _handleSendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ProfileColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: state.isPhoneChangeLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Send Verification Code',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ] else ...[
            Text(
              'Enter 6-digit Code sent to $_selectedDialCode${_phoneController.text.trim()}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              height: 52,
              decoration: BoxDecoration(
                color: ProfileColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: '6-digit OTP code',
                  prefixIcon: Icon(Icons.password_rounded),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _otpSent = false;
                    });
                  },
                  child: const Text('Change Number'),
                ),
                TextButton(
                  onPressed: state.isPhoneChangeLoading ? null : _handleSendOtp,
                  child: const Text('Resend Code'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: state.isPhoneChangeLoading ? null : _handleVerifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ProfileColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: state.isPhoneChangeLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Verify & Update Phone',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
