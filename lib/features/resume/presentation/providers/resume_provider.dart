import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/resume_model.dart';

final resumeProvider = StateNotifierProvider<ResumeNotifier, ResumeData>((ref) {
  return ResumeNotifier();
});

class ResumeNotifier extends StateNotifier<ResumeData> {
  ResumeNotifier()
    : super(
        ResumeData(
          summary:
              'Passionate software engineer with 5+ years of experience in building scalable web applications and solving complex problems. I love turning ideas into impactful digital solutions.',
          experience: [
            ExperienceItem(
              id: '1',
              jobTitle: 'Senior Software Engineer',
              company: 'Tech Solutions Inc.',
              duration: 'Jan 2022 - Present',
              location: 'New York, NY',
              bulletPoints: [
                'Developed and maintained scalable web applications using React, Node.js, and MongoDB.',
                'Improved application performance by 40% through code optimization.',
                'Led a team of 4 engineers and delivered projects on time.',
              ],
            ),
          ],
          skills: [
            'JavaScript',
            'React',
            'Node.js',
            'Python',
            'Django',
            'SQL',
            'MongoDB',
          ],
        ),
      );

  void updateSummary(String summary) {
    state = state.copyWith(summary: summary);
  }

  void addExperience(ExperienceItem item) {
    state = state.copyWith(experience: [...state.experience, item]);
  }

  void updateExperience(ExperienceItem updatedItem) {
    state = state.copyWith(
      experience: state.experience
          .map((e) => e.id == updatedItem.id ? updatedItem : e)
          .toList(),
    );
  }

  void removeExperience(String id) {
    state = state.copyWith(
      experience: state.experience.where((e) => e.id != id).toList(),
    );
  }

  void addSkill(String skill) {
    if (!state.skills.contains(skill)) {
      state = state.copyWith(skills: [...state.skills, skill]);
    }
  }

  void removeSkill(String skill) {
    state = state.copyWith(
      skills: state.skills.where((s) => s != skill).toList(),
    );
  }
}
