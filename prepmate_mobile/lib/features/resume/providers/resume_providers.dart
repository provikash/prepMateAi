import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prepmate_mobile/features/resume/data/resume_api.dart';
import 'package:prepmate_mobile/features/resume/data/models/resume_model.dart';

final resumeProvider = StateNotifierProvider<ResumeNotifier, List<Resume>>((
  ref,
) {
  final api = ref.watch(resumeApiProvider);
  return ResumeNotifier(api);
});

class ResumeNotifier extends StateNotifier<List<Resume>> {
  final ResumeApi api;

  ResumeNotifier(this.api) : super([]);

  //Fetch all resumes
  Future<void> fetchResumes() async {
    final data = await api.getResume();
    state = data;
  }

  /// Create new resume
  Future<Resume> createResume(String template ,String title, Map<String,dynamic> content) async {
    final resume = await api.createResumeWithTemplate(template , title, content);
    state = [...state, resume];
    return resume;
  }

  /// Update resume
  Future<void> updateResume(int id, Map<String, dynamic> data) async {
    await api.updateResume(id, data);
    await fetchResumes();
  }

  /// Delete Resume
  Future<void> deleteResume(int id) async {
    await api.deleteResume(id);
    state = state.where((r) => r.id != id).toList();
  }
}
