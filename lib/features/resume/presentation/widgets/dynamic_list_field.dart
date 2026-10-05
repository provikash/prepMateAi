import 'package:flutter/material.dart';

class DynamicListField extends StatefulWidget {
  final String label;
  final List<String> initialItems;
  final ValueChanged<List<String>> onChanged;

  const DynamicListField({
    super.key,
    required this.label,
    required this.initialItems,
    required this.onChanged,
  });

  @override
  State<DynamicListField> createState() => _DynamicListFieldState();
}

class _DynamicListFieldState extends State<DynamicListField> {
  late final TextEditingController _itemController;
  late List<String> _items;

  @override
  void initState() {
    super.initState();
    _itemController = TextEditingController();
    _items = List<String>.from(widget.initialItems);
  }

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }

  void _addItem() {
    final value = _itemController.text.trim();
    if (value.isEmpty) {
      return;
    }
    setState(() {
      _items.add(value);
      _itemController.clear();
    });
    widget.onChanged(_items);
  }

  void _removeAt(int index) {
    setState(() {
      _items.removeAt(index);
    });
    widget.onChanged(_items);
  }

  Future<void> _editAt(int index) async {
    final editor = TextEditingController(text: _items[index]);
    final updated = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${widget.label}'),
        content: TextField(
          controller: editor,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter value'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(editor.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (updated == null || updated.isEmpty) {
      return;
    }

    setState(() {
      _items[index] = updated;
    });
    widget.onChanged(_items);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _itemController,
                decoration: InputDecoration(
                  hintText: 'Add ${widget.label.toLowerCase()} item',
                ),
                onSubmitted: (_) => _addItem(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addItem,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _items.length; i++)
              InputChip(
                label: Text(_items[i]),
                onPressed: () => _editAt(i),
                onDeleted: () => _removeAt(i),
              ),
          ],
        ),
      ],
    );
  }
}
