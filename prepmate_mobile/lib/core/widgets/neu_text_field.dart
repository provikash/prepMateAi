import 'package:flutter/material.dart';

/// Backward-compatible themed field for feature screens awaiting migration.
class NeuTextField extends StatefulWidget {
  const NeuTextField({
    super.key,
    required this.controller,
    this.hint,
    this.isPassword = false,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.capitalization = TextCapitalization.none,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? hint;
  final bool isPassword;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final TextCapitalization capitalization;
  final ValueChanged<String>? onChanged;

  @override
  State<NeuTextField> createState() => _NeuTextFieldState();
}

class _NeuTextFieldState extends State<NeuTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    onChanged: widget.onChanged,
    keyboardType: widget.keyboardType,
    validator: widget.validator,
    textCapitalization: widget.capitalization,
    obscureText: widget.isPassword && _obscure,
    decoration: InputDecoration(
      hintText: widget.hint,
      prefixIcon: widget.prefixIcon == null ? null : Icon(widget.prefixIcon),
      suffixIcon: widget.isPassword
          ? IconButton(
              tooltip: _obscure ? 'Show password' : 'Hide password',
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscure = !_obscure),
            )
          : null,
    ),
  );
}
