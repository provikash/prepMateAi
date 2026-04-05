import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prepmate_mobile/features/resume/data/models/resume_model.dart';
import 'package:prepmate_mobile/features/resume/providers/resume_providers.dart';
import '../widgets/template_card.dart';

class TemplateScreen extends ConsumerWidget {
  const TemplateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Template")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: templatesList.length,
        itemBuilder: (context, index) {
          final template = templatesList[index];
          return TemplateCard(
            template: template,
            onSelect: () async {
              // Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );

              try {
                final notifier = ref.read(resumeProvider.notifier);
                
                // Fix: Backend requires template, title, and content.
                // Sending template.value (the slug), a default title, and an empty content Map.
                final resume = await notifier.createResume(
                  template.value, 
                  "Untitled Resume", 
                  {},
                );
                
                if (context.mounted) {
                  Navigator.pop(context); // Close loading dialog
                  // Navigate to editor
                  context.pushReplacement("/editor/${resume.id}");
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error creating resume: $e")),
                  );
                }
              }
            },
          );
        },
      ),
    );
  }
}
