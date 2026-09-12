import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:prepmate_mobile/config/theme.dart';
import 'package:prepmate_mobile/features/auth/data/models/user_model.dart';
import '../providers/profile_provider.dart';

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
  late List<String> _skills;

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
    _skills = [];

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
    _skills = List.from(user.skills ?? []);
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

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(profileProvider.notifier).updateProfile({
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'linkedin': _linkedinController.text.trim(),
        'github': _githubController.text.trim(),
        'job_title': _jobTitleController.text.trim(),
        'bio': _bioController.text.trim(),
        'skills': _skills,
      });

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          final state = ref.read(profileProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error ?? 'Update failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.image);
    if (picked == null || picked.files.isEmpty) {
      return;
    }

    final path = picked.files.single.path;
    if (path == null || path.isEmpty) {
      return;
    }

    final success = await ref.read(profileProvider.notifier).uploadProfileImage(path);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Profile image updated' : 'Failed to upload image'),
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
      backgroundColor: colors.screenBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colors.cardBackground,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkShadow
                          : AppTheme.lightShadow,
                    ),
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
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
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
                    hint: 'Enter your full name',
                    colors: colors,
                  ),

                  _buildLabel('Email Address', colors),
                  _buildTextField(
                    controller: _emailController,
                    enabled: false,
                    hint: 'email@example.com',
                    colors: colors,
                  ),

                  _buildLabel('Phone Number', colors),
                  _buildTextField(
                    controller: _phoneController,
                    hint: '+1 123 456 7890',
                    colors: colors,
                  ),

                  _buildLabel('Location', colors),
                  _buildTextField(
                    controller: _locationController,
                    hint: ' Enter your Adderss',
                    colors: colors,
                  ),

                  _buildLabel('Linkedin / Portfolio', colors),
                  _buildTextField(
                    controller: _linkedinController,
                    hint: 'linkedin.com/in/username',
                    colors: colors,
                  ),

                  _buildLabel('GitHub', colors),
                  _buildTextField(
                    controller: _githubController,
                    hint: 'github.com/username',
                    colors: colors,
                  ),



                  const SizedBox(height: 12),
                  // Skills & Bio Container


                  // Skills Add Row
                  const SizedBox(height: 32),

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: colors.border),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
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
    bool enabled = true,
    String? hint,
    required AppColors colors,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        style: TextStyle(color: colors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: colors.textSecondary.withOpacity(0.5)),
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
            borderSide: BorderSide(color: colors.border.withOpacity(0.5)),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _locationController.text.isEmpty
                ? null
                : _locationController.text,
            isExpanded: true,
            hint: Text('Select Location', style: TextStyle(color: colors.textSecondary)),
            icon: Icon(Icons.keyboard_arrow_down, color: colors.textSecondary),
            dropdownColor: colors.cardBackground,
            style: TextStyle(color: colors.textPrimary),
            items: [
              'San Francisco, CA',
              'New York, NY',
              'London, UK',
              'Remote',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) {
              setState(() {
                _locationController.text = val ?? '';
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSkillChip(String skill, AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            skill,
            style: TextStyle(
              color: colors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              setState(() {
                _skills.remove(skill);
              });
            },
            child: Icon(Icons.close, size: 14, color: colors.primary),
          ),
        ],
      ),
    );
  }

  void _showAddSkillDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Skill'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Flutter, Dart'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  if (!_skills.contains(controller.text.trim())) {
                    _skills.add(controller.text.trim());
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
