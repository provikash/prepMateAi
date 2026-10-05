import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prepmate_mobile/config/theme.dart';
import 'package:prepmate_mobile/core/widgets/error_text.dart';
import 'package:prepmate_mobile/features/auth/presentation/viewmodel/auth_viewmodel.dart';
import 'package:prepmate_mobile/features/profile/presentation/providers/profile_provider.dart';
import '../providers/onboarding_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _titleController;
  late final TextEditingController _emailController;
  late final TextEditingController _locationController;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authViewModelProvider).user;
    final onboarding = ref.read(onboardingProvider);
    _nameController = TextEditingController(
      text: onboarding.fullName ?? user?.fullName ?? '',
    );
    _titleController = TextEditingController(
      text: onboarding.professionalTitle ?? user?.professionalTitle ?? '',
    );
    _emailController = TextEditingController(
      text: onboarding.email ?? user?.email ?? '',
    );
    _locationController = TextEditingController(
      text: onboarding.location ?? user?.location ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.image);
    if (picked == null || picked.files.isEmpty) return;
    final path = picked.files.single.path;
    if (path == null || path.isEmpty) return;

    setState(() => _isUploadingPhoto = true);
    final ok = await ref
        .read(profileProvider.notifier)
        .uploadProfileImage(path);
    if (mounted) {
      setState(() => _isUploadingPhoto = false);
      if (ok) {
        final updated = ref.read(profileProvider).user;
        if (updated != null) {
          ref.read(authViewModelProvider.notifier).syncUser(updated);
        }
      }
    }
  }

  Future<void> _continue() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await ref
        .read(onboardingProvider.notifier)
        .saveProfileDetails(
          fullName: _nameController.text,
          professionalTitle: _titleController.text,
          location: _locationController.text,
          email: _emailController.text,
        );

    if (success && mounted) {
      context.push('/onboarding/experience');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final onboarding = ref.watch(onboardingProvider);
    final user = ref.watch(authViewModelProvider).user;
    final phone = user?.phoneNumber ?? '';
    final maskedPhone = phone.length >= 4
        ? '+91 ••••• ${phone.substring(phone.length - 4)}'
        : '+91 ••••• •••••';

    final photoUrl = user?.profilePictureUrl;

    return Scaffold(
      backgroundColor: colors.screenBackground,
      appBar: AppBar(
        backgroundColor: colors.surface.withValues(alpha: 0.85),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: colors.textPrimary,
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Set Up Your Profile',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              color: colors.surface,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step 1 of 4',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                      Text(
                        'Basic Details',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.25,
                      minHeight: 6,
                      backgroundColor: colors.surfaceContainer,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tell us a little about you',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'We’ll use these details to personalize your workspace and prefill your resume. You can edit them later.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Avatar photo picker
                      Center(
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    width: 92,
                                    height: 92,
                                    decoration: BoxDecoration(
                                      color: colors.surfaceContainer,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: colors.border,
                                        width: 2,
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: _isUploadingPhoto
                                        ? const Center(
                                            child: SizedBox(
                                              width: 28,
                                              height: 28,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          )
                                        : (photoUrl != null &&
                                                  photoUrl.isNotEmpty
                                              ? Image.network(
                                                  photoUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      Icon(
                                                        Icons.person,
                                                        size: 48,
                                                        color: colors.primary,
                                                      ),
                                                )
                                              : Icon(
                                                  Icons.person,
                                                  size: 48,
                                                  color: colors.primary,
                                                )),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _pickImage,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: colors.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: colors.surface,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.photo_camera,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Add photo',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(Optional)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Field 1: Full name (Required)
                      _buildFieldLabel(
                        'Full name',
                        isRequired: true,
                        colors: colors,
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        key: const Key('profileFullNameField'),
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _buildInputDecoration(
                          hintText: 'e.g. Alex Morgan',
                          icon: Icons.badge_outlined,
                          colors: colors,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your name as you would like it to appear on your resume.',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Field 2: Professional Title (Optional)
                      _buildFieldLabel(
                        'Professional title',
                        isRequired: false,
                        colors: colors,
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        decoration: _buildInputDecoration(
                          hintText: 'e.g. Flutter Developer',
                          icon: Icons.work_outline,
                          colors: colors,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Student, fresher, and career-changing titles are welcome.',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Field 3: Email Address (Optional)
                      _buildFieldLabel(
                        'Email address',
                        isRequired: false,
                        colors: colors,
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _buildInputDecoration(
                          hintText: 'name@example.com',
                          icon: Icons.mail_outline,
                          colors: colors,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Used on resumes and account communication.',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Field 4: Location (Optional)
                      _buildFieldLabel(
                        'Location',
                        isRequired: false,
                        colors: colors,
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _locationController,
                        decoration: _buildInputDecoration(
                          hintText: 'City, State (e.g. Bengaluru, Karnataka)',
                          icon: Icons.location_on_outlined,
                          colors: colors,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Helps match regional career opportunities.',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Verified Mobile Read-only Status Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainer,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: colors.secondarySoft,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_circle,
                                size: 18,
                                color: colors.secondary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mobile number verified',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    maskedPhone,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.lock_outline,
                              size: 16,
                              color: colors.textSecondary,
                            ),
                          ],
                        ),
                      ),

                      if (onboarding.errorMessage != null &&
                          onboarding.errorMessage!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: ErrorText(message: onboarding.errorMessage),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // Sticky Bottom Continue Action
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  key: const Key('profileSetupContinueButton'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: onboarding.isSaving ? null : _continue,
                  child: onboarding.isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(
    String label, {
    required bool isRequired,
    required AppColors colors,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isRequired ? colors.primarySoft : colors.surfaceContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            isRequired ? 'Required' : 'Optional',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isRequired ? colors.primary : colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData icon,
    required AppColors colors,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, size: 20, color: colors.textSecondary),
      hintStyle: TextStyle(
        fontSize: 14,
        color: colors.textSecondary.withValues(alpha: 0.6),
      ),
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.primary, width: 1.5),
      ),
    );
  }
}
