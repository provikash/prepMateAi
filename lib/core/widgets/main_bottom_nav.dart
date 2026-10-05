import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

enum MainNavTab { home, resumes, aiTools, profile }

/// Main bottom navigation component matching Stitch screen 10 and 11.
///
/// Features pill indicator around active tab icon, standard 48x48 tap targets,
/// semantic navigation labels, and safe area handling.
class MainBottomNavigation extends StatelessWidget {
  const MainBottomNavigation({super.key, required this.currentTab});

  final MainNavTab currentTab;

  void _onTabSelected(BuildContext context, MainNavTab tab) {
    if (tab == currentTab) return;
    switch (tab) {
      case MainNavTab.home:
        context.go('/home');
      case MainNavTab.resumes:
        context.go('/resumes');
      case MainNavTab.aiTools:
        context.go('/resume/ai-assistant');
      case MainNavTab.profile:
        context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        border: Border(
          top: BorderSide(
            color: colors.border.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                tab: MainNavTab.home,
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                colors: colors,
              ),
              _buildNavItem(
                context: context,
                tab: MainNavTab.resumes,
                icon: Icons.description_outlined,
                activeIcon: Icons.description_rounded,
                label: 'Resumes',
                colors: colors,
              ),
              _buildNavItem(
                context: context,
                tab: MainNavTab.aiTools,
                icon: Icons.auto_awesome_outlined,
                activeIcon: Icons.auto_awesome,
                label: 'AI Tools',
                colors: colors,
              ),
              _buildNavItem(
                context: context,
                tab: MainNavTab.profile,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                colors: colors,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required MainNavTab tab,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required AppColors colors,
  }) {
    final isActive = tab == currentTab;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isActive,
        label: '$label tab',
        child: InkWell(
          onTap: () => _onTabSelected(context, tab),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Active pill indicator
              AnimatedContainer(
                duration: AppMotion.fast,
                width: isActive ? 60 : 40,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive ? colors.primarySoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Center(
                  child: Icon(
                    isActive ? activeIcon : icon,
                    size: 22,
                    color: isActive ? colors.primary : colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? colors.primary : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
