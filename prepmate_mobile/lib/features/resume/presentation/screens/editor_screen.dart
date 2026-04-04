import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../providers/resume_providers.dart';

class EditorScreen extends ConsumerStatefulWidget {
  final int resumeId;

  const EditorScreen({super.key, required this.resumeId});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late QuillController controller;
  bool isLoading = true;

  get QuillToolbar => null;

  @override
  void initState() {
    super.initState();
    controller = QuillController.basic();
    loadResume();
  }

  /// 🔥 Load resume content from provider
  Future<void> loadResume() async {
    final resumes = ref.read(resumeProvider);

    final resume =
    resumes.firstWhere((r) => r.id == widget.resumeId);

    if (resume.content != null && resume.content.isNotEmpty) {
      controller = QuillController(
        document: Document.fromJson(resume.content as List<dynamic>),
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    setState(() => isLoading = false);
  }

  /// 💾 Save content
  Future<void> saveResume() async {
    final content = controller.document.toDelta().toJson();

    await ref.read(resumeProvider.notifier).updateResume(
      widget.resumeId,
      {"content": content},
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Saved successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Resume Editor"),

        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: saveResume,
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [

          /// TOOLBAR
          QuillToolbar.basic(controller: controller),

          /// EDITOR
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: QuillEditor.basic(
                  controller: controller,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}