import 'optimization_models.dart';

abstract interface class OptimizationRepository {
  Future<OptimizationAnalysis> analyze(String jobDescription);
  Future<String> regenerate(String text, String instruction);
  Future<void> createVersion(String name);
}
