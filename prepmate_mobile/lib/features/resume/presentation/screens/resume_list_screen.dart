import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/resume_providers.dart';

class ResumeListScreen extends ConsumerStatefulWidget {
  const ResumeListScreen({super.key});

  @override
  ConsumerState<ResumeListScreen> createState() => _ResumeListScreenState();
}

class _ResumeListScreenState extends ConsumerState<ResumeListScreen> {
  @override
  Widget build(BuildContext context) {
    final resumesAsync = ref.watch(resumeListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("My Resumes"), centerTitle: true),

      /// BODY
      body: resumesAsync.when(
        data: (resumes) => resumes.isEmpty
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
                      subtitle: Text("ID: ${resume.id}"),

                      /// OPEN RESUME
                      onTap: () {
                        context.push("/editor/${resume.id}");
                      },

                      /// DELETE BUTTON
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await ref
                              .read(resumeListProvider.notifier)
                              .deleteResume(resume.id);
                        },
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),

      /// FAB → CREATE RESUME
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push("/template");
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
