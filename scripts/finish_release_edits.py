from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
lib = root / 'prepmate_mobile/lib'

# All URLs emitted for stored user files are signed, including dashboard cards.
for relative in ['backend/resume/serializers.py', 'backend/templates/serializers.py', 'backend/users/serializers.py', 'backend/users/views.py', 'backend/resume_analyzer/views.py']:
    file = root / relative
    text = file.read_text(encoding='utf-8')
    text = 'from core.media import media_url\n' + text
    text = text.replace('return request.build_absolute_uri(url) if request else url', 'return media_url(request, file_field)')
    text = text.replace('return request.build_absolute_uri(obj.preview_image.url) if request else obj.preview_image.url', 'return media_url(request, obj.preview_image)')
    text = text.replace('return request.build_absolute_uri(obj.profile_image.url) if request else obj.profile_image.url', 'return media_url(request, obj.profile_image)')
    text = text.replace('return request.build_absolute_uri(file_field.url)', 'return media_url(request, file_field)')
    text = text.replace('request.build_absolute_uri(resume.pdf_file.url)', 'media_url(request, resume.pdf_file)')
    text = text.replace('ResumeAnalysis.objects.filter(user=request.user).order_by', 'ResumeAnalysis.objects.select_related("resume").filter(user=request.user).order_by')
    file.write_text(text, encoding='utf-8')

# Fix the courses search controller lifetime and route actual playback in-app.
file = lib / 'features/courses/presentation/screens/courses_screen.dart'
text = file.read_text(encoding='utf-8')
text = text.replace("import 'package:url_launcher/url_launcher.dart';", "import 'course_video_player_screen.dart';")
text = text.replace('class CoursesScreen extends ConsumerWidget {\n  const CoursesScreen({super.key});', '''class CoursesScreen extends ConsumerStatefulWidget {
  const CoursesScreen({super.key});
  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen> {
  final _skillsController = TextEditingController();
  bool _skillsInitialized = false;
  @override
  void dispose() { _skillsController.dispose(); super.dispose(); }''')
text = text.replace('Widget build(BuildContext context, WidgetRef ref)', 'Widget build(BuildContext context)')
text = text.replace("final controller = TextEditingController(text: skills.join(', '));", "if (!_skillsInitialized && skills.isNotEmpty) {\n      _skillsController.text = skills.join(', ');\n      _skillsInitialized = true;\n    }\n    final controller = _skillsController;")
text = text.replace('Could not load AI recommendations. Make sure backend is running.', 'Courses are temporarily unavailable. Please try again.')
start = text.index('        onTap: () async {', text.index('Widget _buildRecommendationCard'))
end = text.index('        borderRadius:', start)
text = text[:start] + '''        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CourseVideoPlayerScreen(course: rec))),
''' + text[end:]
file.write_text(text, encoding='utf-8')

file = lib / 'features/courses/presentation/screens/all_playlists_screen.dart'
text = file.read_text(encoding='utf-8').replace("import 'package:url_launcher/url_launcher.dart';", "import 'course_video_player_screen.dart';")
start = text.index('      onTap: () async {')
end = text.index('      child: Container(', start)
text = text[:start] + '''      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CourseVideoPlayerScreen(course: playlist))),
''' + text[end:]
file.write_text(text, encoding='utf-8')

# Short-lived PDF state avoids retaining large PDF byte buffers indefinitely.
file = lib / 'features/resume/presentation/providers/resume_providers.dart'
text = file.read_text(encoding='utf-8').replace('final pdfViewerProvider = FutureProvider.family<', 'final pdfViewerProvider = FutureProvider.autoDispose.family<')
file.write_text(text, encoding='utf-8')

file = lib / 'config/dio_client.dart'
text = file.read_text(encoding='utf-8')
text = text.replace('receiveTimeout: const Duration(seconds: 30)', 'receiveTimeout: const Duration(seconds: 180)')
start = text.index('  if (options.data != null) {', text.index('void _logRequest'))
end = text.index('\n}', start)
text = text[:start] + text[end:]
start = text.index('/// Removes known sensitive keys')
text = text[:start]
text = text.replace('  return dio;', '  ref.onDispose(dio.close);\n  return dio;')
file.write_text(text, encoding='utf-8')
