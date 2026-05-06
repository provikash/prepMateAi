import 'package:flutter/material.dart';

class ChipInput extends StatefulWidget {
  final List<String> initial;
  final ValueChanged<List<String>> onChanged;

  const ChipInput({Key? key, required this.initial, required this.onChanged}) : super(key: key);

  @override
  State<ChipInput> createState() => _ChipInputState();
}

class _ChipInputState extends State<ChipInput> {
  final TextEditingController _ctrl = TextEditingController();
  late List<String> _items;

  @override
  void initState() {
    super.initState();
    _items = List<String>.from(widget.initial);
  }

  void _add() {
    final val = _ctrl.text.trim();
    if (val.isEmpty) return;
    if (!_items.contains(val)) {
      setState(() => _items.add(val));
      widget.onChanged(_items);
    }
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _items.map((s) => Chip(label: Text(s), onDeleted: () => setState(() { _items.remove(s); widget.onChanged(_items); }))).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: TextField(controller: _ctrl, decoration: const InputDecoration(hintText: 'Add skill'))),
            IconButton(icon: const Icon(Icons.add), onPressed: _add),
          ],
        )
      ],
    );
  }
}
