import 'package:flutter/material.dart';

import '../../../../config/theme.dart';

class MultiLineField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxCharacters;
  final int maxLines;

  const MultiLineField({
    super.key,
    required this.controller,
    required this.hint,
    this.maxCharacters = 300,
    this.maxLines = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            filled: true,
            fillColor: AppColors.of(context).cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade100),
            ),
          ),
        ),
        const SizedBox(height: 4),
        ValueListenableBuilder(
          valueListenable: controller,
          builder: (context, value, child) {
            return Text(
              '${value.text.length}/$maxCharacters',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            );
          },
        ),
      ],
    );
  }
}

class ChipInput extends StatelessWidget {
  final List<String> items;
  final Function(String) onAdd;
  final Function(String) onRemove;

  const ChipInput({
    super.key,
    required this.items,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...items.map(
          (item) => Chip(
            label: Text(item, style: const TextStyle(fontSize: 12)),
            backgroundColor: AppColors.of(context).iconSoftBackground,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            deleteIcon: const Icon(Icons.close, size: 14),
            onDeleted: () => onRemove(item),
          ),
        ),
      ],
    );
  }
}

class AIActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color iconColor;
  final VoidCallback onTap;

  const AIActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          description,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: Icon(Icons.power_settings_new, color: Colors.teal.shade700),
        onTap: onTap,
      ),
    );
  }
}
