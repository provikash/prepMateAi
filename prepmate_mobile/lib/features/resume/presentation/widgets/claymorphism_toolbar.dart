import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/canvas_provider.dart';

class ClaymorphismToolbar extends ConsumerWidget {
  const ClaymorphismToolbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The base color for the Neumorphic/Claymorphic effect
    const backgroundColor = Color(0xFFF0F0F3);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(30),
        // The magic of Claymorphism happens in these shadows
        boxShadow: [
          // Dark shadow (Bottom Right)
          BoxShadow(
            color: Colors.grey.shade400,
            offset: const Offset(6, 6),
            blurRadius: 12,
            spreadRadius: 1,
          ),
          // Light/White shadow (Top Left)
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-6, -6),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildToolAction(
            context: context,
            icon: Icons.text_fields_rounded,
            label: 'Text',
            onTap: () {
              // Add a new text box near the top-center of the canvas
              ref
                  .read(canvasProvider.notifier)
                  .addTextElement(
                    "Double tap to edit",
                    300.0, // X Coordinate
                    150.0, // Y Coordinate
                  );

              _showFeedback(context, "Text added");
            },
          ),

          _buildDivider(),

          _buildToolAction(
            context: context,
            icon: Icons.horizontal_rule_rounded,
            label: 'Line',
            onTap: () {
              // In the future, you can update your CanvasElement model
              // to support shapes and trigger adding a line here.
              _showFeedback(context, "Line tool coming soon");
            },
          ),

          _buildDivider(),

          _buildToolAction(
            context: context,
            icon: Icons.image_rounded,
            label: 'Image',
            onTap: () {
              // Logic for picking an image from the gallery
              _showFeedback(context, "Image tool coming soon");
            },
          ),

          _buildDivider(),

          _buildToolAction(
            context: context,
            icon: Icons.delete_outline_rounded,
            label: 'Clear All',
            color: Colors.redAccent.shade200,
            onTap: () {
              _showClearConfirmation(context, ref);
            },
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 2,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(1),
        // Add a slight inner shadow effect to the divider line
        boxShadow: const [BoxShadow(color: Colors.white, offset: Offset(1, 0))],
      ),
    );
  }

  Widget _buildToolAction({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final iconColor = color ?? Colors.blueGrey.shade700;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      splashColor: Colors.grey.shade300,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: iconColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Feedback Methods ---

  void _showFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFF0F0F3),
        title: const Text("Clear Canvas?"),
        content: const Text(
          "This will remove all elements from your resume. This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.blueGrey),
            ),
          ),
          TextButton(
            onPressed: () {
              // Call a method on your provider to clear the state
              // e.g., ref.read(canvasProvider.notifier).clearCanvas();
              Navigator.pop(context);
            },
            child: const Text(
              "Clear All",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
