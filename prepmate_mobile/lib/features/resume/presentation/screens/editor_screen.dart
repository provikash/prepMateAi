import 'dart:async';
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
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    controller = QuillController.basic();
    loadResume();

    // Listen to changes for auto-save
    controller.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    controller.removeListener(_onContentChanged);
    controller.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 2000), () {
      saveResume(silent: true);
    });
  }

  /// 🔥 Load resume content from provider
  Future<void> loadResume() async {
    final resumes = ref.read(resumeProvider);

    try {
      final resume = resumes.firstWhere((r) => r.id == widget.resumeId);

      if (resume.content != null && resume.content.isNotEmpty) {
        setState(() {
          controller = QuillController(
            document: Document.fromJson(resume.content as List<dynamic>),
            selection: const TextSelection.collapsed(offset: 0),
          );
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      // If not found in state, maybe fetch from API or handle error
      setState(() => isLoading = false);
    }
  }

  /// 💾 Save content
  Future<void> saveResume({bool silent = false}) async {
    final content = controller.document.toDelta().toJson();

    await ref.read(resumeProvider.notifier).updateResume(
      widget.resumeId,
      {"content": content},
    );

    if (!silent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saved successfully"), duration: Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Resume Editor"),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // TODO: Implement Export / Download
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Export feature coming soon!")),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => saveResume(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                /// TOOLBAR
                QuillSimpleToolbar(
                  controller: controller,
                  // configurations: const QuillSimpleToolbarConfigurations(),
                ),

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
                        // configurations: const QuillEditorConfigurations(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
