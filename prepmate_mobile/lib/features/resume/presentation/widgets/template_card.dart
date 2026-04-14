import 'package:flutter/material.dart';
import 'package:prepmate_mobile/config/theme.dart';
import 'package:prepmate_mobile/config/theme.dart';
import 'package:prepmate_mobile/features/resume/data/models/resume_template.dart';

class TemplateCard extends StatelessWidget {
  final ResumeTemplate template;
  final VoidCallback onSelect;

  const TemplateCard({required this.template, required this.onSelect});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: AppTheme.buttonGradient,
        color: theme.primaryColor,
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.grey.shade300,
            offset: const Offset(0, 10),
          ),
        ],
      ),

      child: Column(
        children: [
          ///Image preview
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            child: Image.asset(
              '${template.thumbnailUrl}',
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          ///Text
          ///
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(template.name, style: theme.textTheme.labelMedium),

                // Text(template.subtitles
                // , style: theme.textTheme.bodySmall,),
                SizedBox(height: 10),

                ///Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onSelect,
                    child: Text("Select Template"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
