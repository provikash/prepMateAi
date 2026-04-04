import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/resume_providers.dart';
import 'template_screen.dart';
import 'editor_screen.dart';

class ResumeListScreen extends ConsumerStatefulWidget {
  const ResumeListScreen({super.key});

  @override
  ConsumerState<ResumeListScreen> createState() =>
      _ResumeListScreenState();
}

class _ResumeListScreenState
    extends ConsumerState<ResumeListScreen> {

  @override
  void initState() {
    super.initState();

    /// Fetch resumes when screen opens
    Future.microtask(() {
      ref.read(resumeProvider.notifier).fetchResumes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final resumes = ref.watch(resumeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Resumes"),
        centerTitle: true,
      ),

      /// BODY
      body: resumes.isEmpty
          ? const Center(child: Text("No resumes found"))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: resumes.length,
        itemBuilder: (context, index) {
          final resume = resumes[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(resume.title),
              subtitle: Text(
                "Template: ${resume.template}",
              ),

              /// OPEN RESUME
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditorScreen(
                      resumeId: resume.id,
                    ),
                  ),
                );
              },

              /// DELETE BUTTON
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  await ref
                      .read(resumeProvider.notifier)
                      .deleteResume(resume.id);
                },
              ),
            ),
          );
        },
      ),

      /// FAB → CREATE RESUME
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final notifier = ref.read(resumeProvider.notifier);

          final resume = await notifier.createResume();

          /// Navigate to template selection
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TemplateScreen(resume.id),
            ),
          );
        },
      ),
    );
  }
}