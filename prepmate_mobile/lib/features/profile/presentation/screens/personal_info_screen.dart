import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:prepmate_mobile/config/theme.dart';
import 'package:prepmate_mobile/features/auth/data/models/user_model.dart';
import 'package:prepmate_mobile/features/auth/presentation/viewmodel/auth_viewmodel.dart';
import 'package:prepmate_mobile/features/home/providers/home_providers.dart';
import '../providers/profile_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _hydratedFromProfile = false;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _linkedinController;
  late TextEditingController _githubController;
  late TextEditingController _jobTitleController;
  late TextEditingController _bioController;
  Map<String, String> _initialValues = const {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _locationController = TextEditingController();
    _linkedinController = TextEditingController();
    _githubController = TextEditingController();
    _jobTitleController = TextEditingController();
    _bioController = TextEditingController();

    Future.microtask(() => ref.read(profileProvider.notifier).loadProfile());
  }

  void _hydrateControllers(UserModel? user) {
    if (user == null || _hydratedFromProfile) {
      return;
    }

    _nameController.text = user.fullName ?? '';
    _emailController.text = user.email;
    _phoneController.text = user.phoneNumber ?? '';
    _locationController.text = user.location ?? '';
    _linkedinController.text = user.linkedin ?? '';
    _githubController.text = user.github ?? '';
    _jobTitleController.text = user.title ?? '';
    _bioController.text = user.bio ?? '';
    _initialValues = _currentValues();
    _hydratedFromProfile = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _linkedinController.dispose();
    _githubController.dispose();
    _jobTitleController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (ref.read(profileProvider).isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check the highlighted fields.')),
      );
      return;
    }
    final current = _currentValues();
    final patch = <String, dynamic>{
      for (final entry in current.entries)
        if (_initialValues[entry.key] != entry.value) entry.key: entry.value,
    };
    if (patch.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No profile changes to save.')),
      );
      return;
    }
    final success = await ref
        .read(profileProvider.notifier)
        .updateProfile(patch);

    if (mounted) {
      if (success) {
        _initialValues = _currentValues();
        final userId = ref.read(authViewModelProvider).user?.id;
        if (userId != null && userId.isNotEmpty) {
          await ref.read(homeRepositoryProvider).invalidateDashboard(userId);
        }
        ref.invalidate(dashboardProvider);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
      } else {
        final state = ref.read(profileProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error ?? 'Your changes were not saved.'),
          ),
        );
      }
    }
  }

  Map<String, String> _currentValues() => {
    'full_name': _nameController.text.trim(),
    'phone': _phoneController.text.trim(),
    'location': _locationController.text.trim(),
    'linkedin': _linkedinController.text.trim(),
    'github': _githubController.text.trim(),
    'job_title': _jobTitleController.text.trim(),
    'bio': _bioController.text.trim(),
  };

  Future<void> _pickAndUploadImage() async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.image);
    if (picked == null || picked.files.isEmpty) {
      return;
    }

    final path = picked.files.single.path;
    if (path == null || path.isEmpty) {
      return;
    }

    final success = await ref
        .read(profileProvider.notifier)
        .uploadProfileImage(path);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Profile image updated' : 'Failed to upload image',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final user = profileState.user;
    final isLoading = profileState.isLoading;
    final colors = AppColors.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hydrateControllers(user);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Personal information')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header Card
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: colors.mutedBackground,
                              backgroundImage: user?.profileImage != null
                                  ? NetworkImage(user!.profileImage!)
                                  : const AssetImage(
                                          'assets/images/profile_placeholder.png',
                                        )
                                        as ImageProvider,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: _pickAndUploadImage,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: colors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colors.cardBackground,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.edit,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user?.fullName ?? 'Loading profile...',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          user?.title ?? 'Profile details',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_on,
                              color: colors.textSecondary,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              user?.location ?? 'San Francisco, CA',
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildLabel('Full Name', colors),
                  _buildTextField(
                    controller: _nameController,
                    fieldKey: 'full_name',
                    backendError: profileState.fieldErrors['full_name'],
                    hint: 'Enter your full name',
                    colors: colors,
                    validator: (value) => (value?.trim().isEmpty ?? true)
                        ? 'Enter your full name'
                        : null,
                  ),

                  _buildLabel('Email Address', colors),
                  _buildTextField(
                    controller: _emailController,
                    fieldKey: 'email',
                    enabled: false,
                    hint: 'email@example.com',
                    colors: colors,
                  ),

                  _buildLabel('Phone Number', colors),
                  _buildTextField(
                    controller: _phoneController,
                    fieldKey: 'phone',
                    backendError: profileState.fieldErrors['phone'],
                    hint: '+1 123 456 7890',
                    colors: colors,
                  ),

                  _buildLabel('Location', colors),
                  _buildTextField(
                    controller: _locationController,
                    fieldKey: 'location',
                    backendError: profileState.fieldErrors['location'],
                    hint: 'Enter your address',
                    colors: colors,
                  ),

                  _buildLabel('Linkedin / Portfolio', colors),
                  _buildTextField(
                    controller: _linkedinController,
                    fieldKey: 'linkedin',
                    backendError: profileState.fieldErrors['linkedin'],
                    hint: 'linkedin.com/in/username',
                    colors: colors,
                  ),

                  _buildLabel('GitHub', colors),
                  _buildTextField(
                    controller: _githubController,
                    fieldKey: 'github',
                    backendError: profileState.fieldErrors['github'],
                    hint: 'github.com/username',
                    colors: colors,
                  ),

                  _buildLabel('Professional title', colors),
                  _buildTextField(
                    controller: _jobTitleController,
                    fieldKey: 'job_title',
                    backendError: profileState.fieldErrors['job_title'],
                    hint: 'e.g. Flutter Developer',
                    colors: colors,
                  ),

                  _buildLabel('Bio', colors),
                  _buildTextField(
                    controller: _bioController,
                    fieldKey: 'bio',
                    backendError: profileState.fieldErrors['bio'],
                    hint: 'Tell employers a little about yourself',
                    colors: colors,
                    maxLines: 4,
                  ),

                  const SizedBox(height: 12),
                  // Skills & Bio Container

                  // Skills Add Row
                  const SizedBox(height: 32),

                  // Action Buttons
                  AppPrimaryButton(
                    label: 'Save changes',
                    loading: isLoading,
                    onPressed: _saveProfile,
                  ),
                  const SizedBox(height: 12),
                  AppSecondaryButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: colors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String fieldKey,
    bool enabled = true,
    String? hint,
    String? backendError,
    String? Function(String?)? validator,
    int maxLines = 1,
    required AppColors colors,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        validator: validator,
        onChanged: (_) =>
            ref.read(profileProvider.notifier).clearFieldError(fieldKey),
        style: TextStyle(color: colors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          errorText: backendError,
          hintStyle: TextStyle(
            color: colors.textSecondary.withValues(alpha: 0.5),
          ),
          filled: true,
          fillColor: enabled ? colors.cardBackground : colors.mutedBackground,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.border),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.border.withValues(alpha: 0.5)),
          ),
        ),
      ),
    );
  }
}
