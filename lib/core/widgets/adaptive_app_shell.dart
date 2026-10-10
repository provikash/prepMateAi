import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../responsive/responsive.dart';
import 'app_logo.dart';
import 'main_bottom_nav.dart';

class AdaptiveAppShell extends StatefulWidget {
  const AdaptiveAppShell({
    super.key,
    required this.location,
    required this.child,
    this.rightPanel,
  });

  final String location;
  final Widget child;
  final Widget? rightPanel;

  @override
  State<AdaptiveAppShell> createState() => _AdaptiveAppShellState();
}

class _AdaptiveAppShellState extends State<AdaptiveAppShell> {
  bool _collapsed = false;
  DateTime? _lastBackPressedAt;

  static const _destinations = <_AppDestination>[
    _AppDestination('Dashboard', Icons.dashboard_outlined, '/dashboard'),
    _AppDestination('My Resumes', Icons.description_outlined, '/resumes'),
    _AppDestination('Resume Builder', Icons.edit_document, '/resumes/new'),
    _AppDestination('Optimization', Icons.auto_graph_outlined, '/optimize'),
    _AppDestination('History', Icons.history, '/optimizations'),
    _AppDestination(
      'AI Assistant',
      Icons.auto_awesome_outlined,
      '/ai-assistant',
    ),
    _AppDestination('AI Credits', Icons.toll_outlined, '/credits'),
    _AppDestination('Settings', Icons.settings_outlined, '/settings'),
  ];

  int get _selectedIndex {
    if (widget.location.startsWith('/resume/optimize')) return 3;
    if (widget.location.startsWith('/resume/ai-')) return 5;
    if (widget.location.startsWith('/resume/form') ||
        widget.location == '/resumes/new') {
      return 2;
    }
    if (widget.location.startsWith('/resume/pdf') ||
        widget.location.startsWith('/resumes/')) {
      return 1;
    }
    final index = _destinations.indexWhere((destination) {
      if (destination.path == '/dashboard') {
        return widget.location == '/dashboard' || widget.location == '/home';
      }
      return widget.location == destination.path ||
          widget.location.startsWith('${destination.path}/');
    });
    return index < 0 ? 0 : index;
  }

  bool get _isHome =>
      widget.location == '/dashboard' || widget.location == '/home';

  MainNavTab get _compactTab {
    final location = widget.location;
    if (location == '/resumes' ||
        location.startsWith('/resumes/') ||
        location.startsWith('/resume/form') ||
        location.startsWith('/resume/pdf')) {
      return MainNavTab.resumes;
    }
    if (location.startsWith('/profile') || location == '/settings') {
      return MainNavTab.profile;
    }
    if (location.startsWith('/ai-') ||
        location.startsWith('/credits') ||
        location.startsWith('/optimize') ||
        location.startsWith('/optimizations') ||
        location.startsWith('/resume/ai-') ||
        location.startsWith('/resume/optimize')) {
      return MainNavTab.aiTools;
    }
    return MainNavTab.home;
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_isHome && context.canPop(),
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) return;
      if (_isHome) {
        _handleHomeBack();
      } else {
        context.go('/home');
      }
    },
    child: ResponsiveBuilder(
      builder: (context, size, constraints) {
        if (size == AppLayoutSize.compact) {
          final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
          return Scaffold(
            body: widget.child,
            bottomNavigationBar: keyboardOpen
                ? null
                : MainBottomNavigation(currentTab: _compactTab),
          );
        }
        final colors = AppColors.of(context);
        final rail = size == AppLayoutSize.medium || _collapsed;

        return Scaffold(
          backgroundColor: colors.screenBackground,
          body: Row(
            children: [
              if (rail)
                _NavigationRail(
                  selectedIndex: _selectedIndex,
                  destinations: _destinations,
                  onSelected: _select,
                  canExpand: size != AppLayoutSize.medium,
                  onExpand: () => setState(() => _collapsed = false),
                )
              else
                _NavigationSidebar(
                  selectedIndex: _selectedIndex,
                  destinations: _destinations,
                  onSelected: _select,
                  onCollapse: () => setState(() => _collapsed = true),
                ),
              VerticalDivider(width: 1, color: colors.border),
              Expanded(child: widget.child),
              if (size == AppLayoutSize.large && widget.rightPanel != null) ...[
                VerticalDivider(width: 1, color: colors.border),
                SizedBox(width: 320, child: widget.rightPanel),
              ],
            ],
          ),
        );
      },
    ),
  );

  void _handleHomeBack() {
    final now = DateTime.now();
    final shouldExit =
        _lastBackPressedAt != null &&
        now.difference(_lastBackPressedAt!) < const Duration(seconds: 2);
    if (shouldExit) {
      SystemNavigator.pop();
      return;
    }
    _lastBackPressedAt = now;
    Fluttertoast.cancel();
    Fluttertoast.showToast(
      msg: 'Press back again to exit',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _select(int index) {
    final destination = _destinations[index];
    if (widget.location != destination.path) context.go(destination.path);
  }
}

class _NavigationRail extends StatelessWidget {
  const _NavigationRail({
    required this.selectedIndex,
    required this.destinations,
    required this.onSelected,
    required this.canExpand,
    required this.onExpand,
  });

  final int selectedIndex;
  final List<_AppDestination> destinations;
  final ValueChanged<int> onSelected;
  final bool canExpand;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      labelType: NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          children: [
            const AppLogo(size: 38),
            if (canExpand) ...[
              const SizedBox(height: AppSpacing.sm),
              IconButton(
                tooltip: 'Expand navigation',
                onPressed: onExpand,
                icon: const Icon(Icons.keyboard_double_arrow_right),
              ),
            ],
          ],
        ),
      ),
      destinations: [
        for (final destination in destinations)
          NavigationRailDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.icon, fill: 1),
            label: Text(destination.label),
          ),
      ],
    ),
  );
}

class _NavigationSidebar extends StatelessWidget {
  const _NavigationSidebar({
    required this.selectedIndex,
    required this.destinations,
    required this.onSelected,
    required this.onCollapse,
  });

  final int selectedIndex;
  final List<_AppDestination> destinations;
  final ValueChanged<int> onSelected;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SafeArea(
      child: SizedBox(
        width: 264,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Row(
                children: [
                  const AppLogo(size: 42),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'PrepMate AI',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Collapse navigation',
                    onPressed: onCollapse,
                    icon: const Icon(Icons.keyboard_double_arrow_left),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: ListView.separated(
                  itemCount: destinations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final destination = destinations[index];
                    final selected = index == selectedIndex;
                    return Semantics(
                      selected: selected,
                      button: true,
                      child: ListTile(
                        selected: selected,
                        minTileHeight: 48,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        selectedTileColor: colors.primarySoft,
                        leading: Icon(destination.icon),
                        title: Text(destination.label),
                        onTap: () => onSelected(index),
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              ListTile(
                minTileHeight: 48,
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: const Text('Account'),
                subtitle: const Text('Profile & settings'),
                onTap: () => context.go('/settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppDestination {
  const _AppDestination(this.label, this.icon, this.path);

  final String label;
  final IconData icon;
  final String path;
}
