import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prepmate_mobile/features/resume/models/canvas_element.dart';
import '../../providers/canvas_provider.dart';
import '../widgets/draggable_text_box.dart';
import '../widgets/claymorphism_toolbar.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({Key? key, required int resumeId}) : super(key: key);

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  // We initialize the controller here to prepare for Phase 4 (Auto-Zoom)
  final TransformationController _transformationController =
      TransformationController();

  // Define standard A4 proportions (Width: 794px, Height: 1123px at 96 DPI)
  final double canvasWidth = 794.0;
  final double canvasHeight = 1123.0;

  @override
  Widget build(BuildContext context) {
    // Watch the reactive list of canvas elements
    final canvasElements = ref.watch(canvasProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F3), // Soft UI background
      appBar: AppBar(
        title: const Text(
          'Design Resume',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // Trigger Phase 5 Save Logic here
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // LAYER 1: The Interactive Workspace
          InteractiveViewer(
            transformationController: _transformationController,
            constrained:
                false, // Allows the canvas to be larger than the screen
            minScale: 0.1,
            maxScale: 4.0,
            boundaryMargin: const EdgeInsets.all(
              500,
            ), // Gives room to pan around
            child: Center(
              child: Container(
                width: canvasWidth,
                height: canvasHeight,
                decoration: BoxDecoration(
                  color: Colors.white, // The exact A4 paper color
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                // The strictly locked Stack layout
                child: Stack(
                  clipBehavior: Clip.none,
                  children: canvasElements.map((element) {
                    return DraggableTextBox(element: element);
                  }).toList(),
                ),
              ),
            ),
          ),

          // LAYER 2: The Claymorphism Toolbar (Fixed to bottom)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ClaymorphismToolbar(),
          ),
        ],
      ),
    );
  }
}
