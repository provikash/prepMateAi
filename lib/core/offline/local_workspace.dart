import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/state/auth_state.dart';
import '../../features/auth/presentation/viewmodel/auth_viewmodel.dart';
import '../database/app_database.dart';

/// The active on-device workspace. Guests and signed-in accounts both use a
/// workspace so local features never depend on an API session.
final localWorkspaceProvider = FutureProvider<LocalWorkspace>((ref) async {
  final auth = ref.watch(authViewModelProvider);
  final accountId = auth.status == AuthStatus.authenticated
      ? auth.user?.id
      : null;
  return ref.watch(appDatabaseProvider).activateWorkspace(accountId: accountId);
});
