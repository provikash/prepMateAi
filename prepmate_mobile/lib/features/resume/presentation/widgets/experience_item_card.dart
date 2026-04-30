import 'package:flutter/material.dart';

class ExperienceItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ExperienceItemCard({Key? key, required this.item, this.onEdit, this.onDelete}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title = item['job_title'] ?? 'Untitled';
    final company = item['company'] ?? '';
    final duration = item['duration'] ?? '';
    final bullets = List<String>.from(item['bullets'] ?? <String>[]);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text('$title • $company', style: const TextStyle(fontWeight: FontWeight.bold))),
            if (onEdit != null) IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
            if (onDelete != null) IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
          ]),
          if (duration.isNotEmpty) Text(duration, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          ...bullets.map((b) => Row(children: [const Icon(Icons.circle, size: 6), const SizedBox(width: 6), Expanded(child: Text(b))])).toList(),
        ]),
      ),
    );
  }
}
