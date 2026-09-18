import 'package:flutter/material.dart';

class RoundedInputField extends StatefulWidget {
  const RoundedInputField({
    super.key,
    required this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.controller,
    this.onChanged,
    this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final String hintText;
  final Widget prefixIcon;
  final bool isPassword;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  State<RoundedInputField> createState() => _RoundedInputFieldState();
}

class _RoundedInputFieldState extends State<RoundedInputField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    obscureText: widget.isPassword && _obscureText,
    onChanged: widget.onChanged,
    validator: widget.validator,
    keyboardType: widget.keyboardType,
    textCapitalization: widget.textCapitalization,
    decoration: InputDecoration(
      hintText: widget.hintText,
      prefixIcon: widget.prefixIcon,
      suffixIcon: widget.isPassword
          ? IconButton(
              tooltip: _obscureText ? 'Show password' : 'Hide password',
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () => setState(() => _obscureText = !_obscureText),
            )
          : null,
    ),
  );
}
