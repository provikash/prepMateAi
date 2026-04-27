import 'package:flutter/material.dart';

import '../../data/models/template_detail_model.dart';

class DynamicListObjectField extends StatefulWidget {
  final String label;
  final List<FormObjectFieldModel> itemFields;
  final List<Map<String, String>> initialItems;
  final ValueChanged<List<Map<String, String>>> onChanged;

  const DynamicListObjectField({
    super.key,
    required this.label,
    required this.itemFields,
    required this.initialItems,
    required this.onChanged,
  });

  @override
  State<DynamicListObjectField> createState() => _DynamicListObjectFieldState();
}

class _DynamicListObjectFieldState extends State<DynamicListObjectField> {
  late List<Map<String, String>> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.initialItems.map((item) => Map<String, String>.from(item)).toList();
  }

  void _notifyChange() {
    widget.onChanged(_items.map((item) => Map<String, String>.from(item)).toList());
  }

  void _addEntry() {
    final next = <String, String>{};
    for (final field in widget.itemFields) {
      next[field.key] = '';
    }
    setState(() {
      _items.add(next);
    });
    _notifyChange();
  }

  void _removeAt(int index) {
    setState(() {
      _items.removeAt(index);
    });
    _notifyChange();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              onPressed: _addEntry,
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Add item',
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (_items.isEmpty)
          const Text('No items added yet.')
        else
          for (var i = 0; i < _items.length; i++)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    for (final field in widget.itemFields) ...[
                      TextFormField(
                        initialValue: _items[i][field.key] ?? '',
                        decoration: InputDecoration(labelText: field.label),
                        onChanged: (value) {
                          _items[i][field.key] = value;
                          _notifyChange();
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _removeAt(i),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remove'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
