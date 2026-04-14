import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/canvas_element.dart';
import '../../providers/canvas_provider.dart';

class DraggableTextBox extends ConsumerWidget {
  final CanvasElement element;

  // We pass this callback from the EditorScreen so the parent can handle
  // the complex AnimationController logic for the Auto-Zoom feature.
  final VoidCallback? onDoubleTap;

  const DraggableTextBox({super.key, required this.element, this.onDoubleTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Positioned strictly locks the element to the exact X/Y coordinates on the A4 Stack
    return Positioned(
      left: element.x,
      top: element.y,
      child: GestureDetector(
        // Handle dragging/panning across the canvas
        onPanUpdate: (details) {
          // Dispatch the new coordinates to Riverpod.
          // Because Riverpod state is immutable, this instantly triggers a UI rebuild
          // at the new location without needing a local setState.
          ref
              .read(canvasProvider.notifier)
              .updatePosition(
                element.id,
                element.x + details.delta.dx,
                element.y + details.delta.dy,
              );
        },

        // Handle the trigger for Phase 4 (Auto-Zoom & Edit)
        onDoubleTap:
            onDoubleTap ??
            () {
              debugPrint("Double tapped element: ${element.id}");
            },

        // The visual container
        child: Container(
          // Padding gives the user a slightly larger "hit box" for their finger to grab
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            // CRITICAL: Must be transparent, not null, so the gesture detector catches the whole box
            color: Colors.transparent,
            // In the future, you can change this to a dashed blue border when the item is "selected"
            border: Border.all(color: Colors.transparent, width: 1.5),
          ),
          child: Text(
            element.text,
            style: TextStyle(
              fontSize: element.fontSize,
              color: Colors.black87,
              fontWeight: FontWeight.normal,
              // Explicitly remove decorations to ensure it looks clean on the raw canvas
              decoration: TextDecoration.none,
              height: 1.2, // Standardize line height for PDF translation later
            ),
          ),
        ),
      ),
    );
  }
}
