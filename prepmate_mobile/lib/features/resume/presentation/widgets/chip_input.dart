import 'package:flutter/material.dart';

class ChipInput extends StatefulWidget {
  final List<String> initial;
  final ValueChanged<List<String>> onChanged;

  const ChipInput({super.key, required this.initial, required this.onChanged});

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

  @override
  void didUpdateWidget(covariant ChipInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameItems(widget.initial, oldWidget.initial)) {
      _items = List<String>.from(widget.initial);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
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
          children: _items
              .map(
                (s) => Chip(
                  label: Text(s),
                  onDeleted: () => setState(() {
                    _items.remove(s);
                    widget.onChanged(_items);
                  }),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: const InputDecoration(hintText: 'Add skill'),
              ),
            ),
            IconButton(
              tooltip: 'Add skill',
              icon: const Icon(Icons.add),
              onPressed: _add,
            ),
          ],
        ),
      ],
    );
  }

  bool _sameItems(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}
