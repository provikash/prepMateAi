import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_state.dart';
import '../../../auth/presentation/viewmodel/auth_viewmodel.dart';
import '../../../auth/data/models/user_model.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final cached = ref.read(authViewModelProvider).user;
      if (cached is UserModel) {
        ref.read(profileProvider.notifier).seed(cached);
      } else {
        ref.read(profileProvider.notifier).loadProfile();
      }
    });
  }

  Future<void> _logout() async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Sign out?',
      message:
          'You’ll need to sign in again to access your resumes and learning progress.',
      confirmLabel: 'Sign out',
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final user = state.user;

    return AppScaffold(
      title: 'Profile & settings',
      padding: EdgeInsets.zero,
      body: state.isLoading && user == null
          ? const AppLoadingState(label: 'Loading your profile')
          : state.error != null && user == null
          ? AppErrorState(
              message: 'We couldn’t load your profile.',
              onAction: () => ref.read(profileProvider.notifier).loadProfile(),
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(profileProvider.notifier).refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.sm,
                  AppSpacing.screen,
                  AppSpacing.xxl,
                ),
                children: [
                  _ProfileHeader(
                    name: user?.fullName ?? 'PrepMate member',
                    email: user?.email ?? '',
                    imageUrl: user?.profileImage,
                    onEdit: () => context.push('/profile/edit'),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _SettingsSection(
                    title: 'Account',
                    children: [
                      _SettingsTile(
                        icon: Icons.person_outline_rounded,
                        title: 'Personal information',
                        subtitle: 'Name, contact details and career profile',
                        onTap: () => context.push('/profile/edit'),
                      ),
                      _SettingsTile(
                        icon: Icons.lock_outline_rounded,
                        title: 'Change password',
                        subtitle: 'Reset your account password securely',
                        onTap: () => context.push('/forgot-password'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _SettingsSection(
                    title: 'Career activity',
                    children: [
                      _SettingsTile(
                        icon: Icons.description_outlined,
                        title: 'My resumes',
                        onTap: () => context.go('/home'),
                      ),
                      _SettingsTile(
                        icon: Icons.analytics_outlined,
                        title: 'Analysis history',
                        onTap: () => context.push('/ats-history'),
                      ),
                      _SettingsTile(
                        icon: Icons.school_outlined,
                        title: 'Learning progress',
                        onTap: () => context.push('/courses'),
                      ),
                      _SettingsTile(
                        icon: Icons.auto_awesome_outlined,
                        title: 'AI credits & plan',
                        subtitle: 'Balance, usage, plans and activity',
                        onTap: () => context.push('/ai-credits'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _SettingsSection(
                    title: 'Preferences',
                    children: [
                      _SettingsTile(
                        icon: Icons.dark_mode_outlined,
                        title: 'Dark mode',
                        subtitle: 'Use a darker palette in low light',
                        trailing: Switch(
                          value: ref.watch(themeModeProvider) == ThemeMode.dark,
                          onChanged: (_) =>
                              ref.read(themeModeProvider.notifier).toggle(),
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & support',
                        onTap: () => context.push('/help'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: 'Sign out',
                    icon: Icons.logout_rounded,
                    variant: AppButtonVariant.destructive,
                    onPressed: _logout,
                  ),
                ],
              ),
            ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.imageUrl,
    required this.onEdit,
  });

  final String name;
  final String email;
  final String? imageUrl;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final initial = name.trim().isEmpty ? 'P' : name.trim()[0].toUpperCase();
    Widget fallback() => ColoredBox(
      color: colors.primarySoft,
      child: Center(
        child: Text(
          initial,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(color: colors.primary),
        ),
      ),
    );

    return AppCard(
      child: Row(
        children: [
          ClipOval(
            child: SizedBox.square(
              dimension: 72,
              child: imageUrl?.isNotEmpty ?? false
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => fallback(),
                    )
                  : fallback(),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleLarge),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    email,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit profile',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.xxs,
          bottom: AppSpacing.xs,
        ),
        child: Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.of(context).textSecondary,
            letterSpacing: 0.8,
          ),
        ),
      ),
      AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1)
                const Divider(height: 1, indent: 64),
            ],
          ],
        ),
      ),
    ],
  );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, color: colors.primary, size: AppSizes.iconSmall),
      ),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing:
          trailing ?? (onTap == null ? null : const Icon(Icons.chevron_right)),
      onTap: onTap,
    );
  }
}
