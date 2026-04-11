import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/resume_template.dart';
import '../../providers/template_provider.dart';
import '../../providers/canvas_provider.dart';

class TemplateSelectionScreen extends ConsumerWidget {
  const TemplateSelectionScreen({super.key});

  // The logic to handle the template selection and navigation
  Future<void> _onTemplateSelected(
    BuildContext context,
    WidgetRef ref,
    String templateId,
  ) async {
    // 1. Show a loading spinner to prevent multiple taps
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 2. Tell Riverpod to download and clone the template JSON
      await ref
          .read(canvasProvider.notifier)
          .loadTemplateFromBackend(templateId);

      // 3. Remove the loading spinner
      if (context.mounted) {
        Navigator.pop(context);

        // 4. Navigate to the Editor
        // Note: resumeId is expected to be int by EditorScreen.
        // We parse it or use a default if it's not a valid integer.
        final int id = int.tryParse(templateId) ?? 0;
        context.push("/editor/$id");
      }
    } catch (e) {
      // Handle network errors gracefully
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load template. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the FutureProvider
    final templateAsyncValue = ref.watch(templateListProvider);

    return Scaffold(
      backgroundColor: const Color(
        0xFFF0F0F3,
      ), // Soft background for claymorphism
      appBar: AppBar(
        title: const Text(
          'Choose a Template',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: templateAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error loading templates: $error')),
        data: (templates) {
          if (templates.isEmpty) {
            return const Center(child: Text('No templates available yet.'));
          }

          // Display templates in a 2-column grid
          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7, // Taller than wide, like an A4 paper
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return _buildTemplateCard(context, ref, template);
            },
          );
        },
      ),
    );
  }

  // Extracted widget method for clean UI code
  Widget _buildTemplateCard(
    BuildContext context,
    WidgetRef ref,
    ResumeTemplate template,
  ) {
    return GestureDetector(
      onTap: () => _onTemplateSelected(context, ref, template.id),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F3),
          borderRadius: BorderRadius.circular(16),
          // Claymorphism soft shadows
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade400,
              offset: const Offset(5, 5),
              blurRadius: 10,
              spreadRadius: 1,
            ),
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-5, -5),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  template.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
            // Template Name
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                template.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
