import 'package:flutter/material.dart';

import '../../config/theme.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.description,
    this.actions,
    this.leading,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset = true,
    this.safeArea = true,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.screen,
      vertical: AppSpacing.md,
    ),
  });

  final Widget body;
  final String? title;
  final String? description;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool resizeToAvoidBottomInset;
  final bool safeArea;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (description != null) ...[
            Text(
              description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.of(context).textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Expanded(child: body),
        ],
      ),
    );
    if (safeArea) content = SafeArea(top: title == null, child: content);

    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: title == null
          ? null
          : AppTopBar(title: title!, leading: leading, actions: actions),
      body: content,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.centerTitle = false,
  });

  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading,
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: actions,
      centerTitle: centerTitle,
    );
  }
}
