import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dio_client.dart';
import '../../data/datasources/ai_credits_remote_datasource.dart';
import '../../data/repositories/ai_credits_repository_impl.dart';
import '../../data/repositories/mock_ai_credits_repository.dart';
import '../../domain/repositories/ai_credits_repository.dart';
import '../viewmodels/ai_credit_state.dart';
import '../viewmodels/ai_credits_viewmodel.dart';

const aiCreditsUseMock = bool.fromEnvironment(
  'AI_CREDITS_USE_MOCK',
  defaultValue: true,
);

final aiCreditsRemoteDataSourceProvider = Provider<AiCreditsRemoteDataSource>(
  (ref) => AiCreditsRemoteDataSource(ref.watch(dioProvider)),
);

final aiCreditsRepositoryProvider = Provider<AiCreditsRepository>((ref) {
  if (aiCreditsUseMock) return const MockAiCreditsRepository();
  return AiCreditsRepositoryImpl(ref.watch(aiCreditsRemoteDataSourceProvider));
});

final aiCreditsProvider =
    StateNotifierProvider<AiCreditsViewModel, AiCreditState>(
      (ref) => AiCreditsViewModel(ref.watch(aiCreditsRepositoryProvider)),
    );
