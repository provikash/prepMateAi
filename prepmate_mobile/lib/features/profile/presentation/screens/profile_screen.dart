import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/viewmodel/auth_viewmodel.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Profile Settings',
          style: TextStyle(
            color: Color(0xFF1D2939),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile Image with Edit Icon
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200, width: 4),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/profile_placeholder.png'), // Replace with actual user image
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF246BFD),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.fullName ?? 'Johnathan Smith',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D2939),
              ),
            ),
            const Text(
              'Senior Software Engineer',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF246BFD),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 30),

            // Profile Sections
            _buildSection(
              title: 'ACCOUNT',
              items: [
                _ProfileItem(
                  icon: Icons.person_outline,
                  title: 'Personal Info',
                  onTap: () {},
                ),
                _ProfileItem(
                  icon: Icons.security_outlined,
                  title: 'Security',
                  onTap: () {},
                ),
              ],
            ),

            _buildSection(
              title: 'RESUME SETTINGS',
              items: [
                _ProfileItem(
                  icon: Icons.description_outlined,
                  title: 'Default Template',
                  onTap: () {},
                ),
                _ProfileItem(
                  icon: Icons.bar_chart_outlined,
                  title: 'ATS Preferences',
                  onTap: () {},
                ),
              ],
            ),

            _buildSection(
              title: 'LEARNING',
              items: [
                _ProfileItem(
                  icon: Icons.school_outlined,
                  title: 'My Courses',
                  onTap: () {},
                ),
                _ProfileItem(
                  icon: Icons.verified_outlined,
                  title: 'Certificates',
                  onTap: () {},
                ),
              ],
            ),

            _buildSection(
              title: 'APP SETTINGS',
              items: [
                _ProfileItem(
                  icon: Icons.notifications_none_outlined,
                  title: 'Notifications',
                  onTap: () {},
                ),
                _ProfileItem(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark Mode',
                  trailing: Switch(
                    value: false,
                    onChanged: (val) {},
                    activeColor: const Color(0xFF246BFD),
                  ),
                ),
                _ProfileItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {},
                ),
              ],
            ),

            // Log Out Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    ref.read(authViewModelProvider.notifier).logout();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF5F5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text(
                        'Log Out',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
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

  Widget _buildSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ProfileItem({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFE0E7FF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF246BFD), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1D2939),
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
