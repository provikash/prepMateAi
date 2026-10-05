import 'package:flutter/material.dart';

import '../../config/theme.dart';
import 'app_button.dart';

Future<bool> showAppConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actionsPadding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          actions: [
            AppButton(
              label: cancelLabel,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              variant: AppButtonVariant.text,
              expand: false,
            ),
            AppButton(
              label: confirmLabel,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              variant: destructive
                  ? AppButtonVariant.destructive
                  : AppButtonVariant.primary,
              expand: false,
            ),
          ],
        ),
      ) ??
      false;
}

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screen,
        right: AppSpacing.screen,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: child,
    ),
  );
}
