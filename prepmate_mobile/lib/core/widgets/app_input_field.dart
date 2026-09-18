import 'package:flutter/material.dart';

class AppInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool isPassword;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final TextCapitalization capitalization;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final int maxLines;
  final bool enabled;

  const AppInputField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.isPassword = false,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.capitalization = TextCapitalization.none,
    this.onChanged,
    this.textInputAction,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  State<AppInputField> createState() => _AppInputFieldState();
}

class _AppInputFieldState extends State<AppInputField> {
  bool obscure = true;

  @override
  Widget build(BuildContext context) {
    final isPassword = widget.isPassword;

    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      onChanged: widget.onChanged,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.capitalization,
      obscureText: isPassword ? obscure : false,
      maxLines: isPassword ? 1 : widget.maxLines,
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
        suffixIcon: isPassword
            ? IconButton(
                tooltip: obscure ? 'Show password' : 'Hide password',
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => obscure = !obscure),
              )
            : null,
      ),
    );
  }
}
