from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
lib = root / 'prepmate_mobile/lib'
renames = {
    'socialButton.dart': 'social_button.dart',
    'forgetPassword_screen.dart': 'forgot_password_screen.dart',
    'otpVerification_screen.dart': 'otp_verification_screen.dart',
    'passwordChanged_screen.dart': 'password_changed_screen.dart',
    'resetPassword_screen.dart': 'reset_password_screen.dart',
}
for file in list(lib.rglob('*.dart')):
    text = file.read_text(encoding='utf-8')
    for before, after in renames.items():
        text = text.replace(before, after)
    text = text.replace('topCircleButton', 'TopCircleButton')
    file.write_text(text, encoding='utf-8')
    if file.name in renames:
        destination = file.with_name(renames[file.name])
        assert lib.resolve() in destination.resolve().parents
        file.rename(destination)

file = lib / 'features/auth/presentation/screens/signup_screen.dart'
text = file.read_text(encoding='utf-8')
text = re.sub(r'  final bool _obscure(?:Confirm)?Password = true;\n', '', text)
file.write_text(text, encoding='utf-8')

file = lib / 'features/profile/presentation/screens/personal_info_screen.dart'
text = file.read_text(encoding='utf-8')
text = text[:text.index('  Widget _buildDropdownField')] + '}\n'
file.write_text(text, encoding='utf-8')

file = lib / 'features/home/presentation/screens/template_editor_screen.dart'
text = file.read_text(encoding='utf-8').replace('final created = await', 'await')
file.write_text(text, encoding='utf-8')

file = lib / 'features/courses/presentation/screens/courses_screen.dart'
text = file.read_text(encoding='utf-8')
start = text.index('            onPressed: () async {', text.index('Widget _buildContinueLearningItem'))
end = text.index('            icon:', start)
text = text[:start] + '''            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => CourseVideoPlayerScreen(course: course))),
''' + text[end:]
start = text.index('    return Container(', text.index('Widget _buildContinueLearningItem'))
text = text[:start] + '''    final progress = ref.watch(courseProgressProvider(course.videoId)).asData?.value.watchPercentage ?? 0;
''' + text[start:]
text = text.replace('value: 0.53, // Mock for now', 'value: (progress / 100).clamp(0, 1),')
text = text.replace("'53%'", "'${progress.toStringAsFixed(0)}%'")
file.write_text(text, encoding='utf-8')

file = lib / 'features/courses/presentation/screens/ai_course_finder_screen.dart'
text = file.read_text(encoding='utf-8').replace("import 'package:url_launcher/url_launcher.dart';", "import 'course_video_player_screen.dart';")
start = text.index('    // Open YouTube URL instead of playing inline')
text = text[:start] + '''    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CourseVideoPlayerScreen(course: course)));
  }
}
'''
file.write_text(text, encoding='utf-8')

# This model uses explicit tolerant parsing because playlist results omit fields.
file = lib / 'features/courses/data/models/ai_course_model.dart'
text = file.read_text(encoding='utf-8')
text = re.sub(r"import 'package:json_annotation/json_annotation.dart';\n|part 'ai_course_model.g.dart';\n|@JsonSerializable\(\)\n|  @JsonKey\(name: '[^']+'\)\n", '', text)
text = text.replace('      _$CourseProgressFromJson(json);', '''      CourseProgress(
        id: json['id']?.toString(),
        videoId: json['video_id']?.toString() ?? '',
        watchedSeconds: (json['watched_seconds'] as num?)?.toInt() ?? 0,
        totalSeconds: (json['total_seconds'] as num?)?.toInt() ?? 0,
        watchPercentage: (json['watch_percentage'] as num?)?.toDouble() ?? 0,
        lastUpdated: json['last_updated']?.toString(),
      );''')
text = text.replace('Map<String, dynamic> toJson() => _$CourseProgressToJson(this);', '''Map<String, dynamic> toJson() => {
    'id': id, 'video_id': videoId, 'watched_seconds': watchedSeconds,
    'total_seconds': totalSeconds, 'watch_percentage': watchPercentage,
    'last_updated': lastUpdated,
  };''')
file.write_text(text, encoding='utf-8')

file = root / 'prepmate_mobile/pubspec.yaml'
text = file.read_text(encoding='utf-8')
for package in ['sms_autofill', 'signin_with_linkedin', 'pdfx', 'json_annotation', 'json_serializable', 'build_runner']:
    text = re.sub(r'^  ' + package + r':[^\n]*\n', '', text, flags=re.M)
text = text.replace('description: "A new Flutter project."', 'description: "PrepMate: resume building, career insights, and guided learning."')
file.write_text(text, encoding='utf-8')
