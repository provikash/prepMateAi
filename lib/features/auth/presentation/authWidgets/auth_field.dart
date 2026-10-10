import 'package:flutter/material.dart';

class AuthField extends StatefulWidget {
  const AuthField({
    super.key,
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    required this.validator,
    this.keyboardType,
    required this.isPassword,
  });

  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final FormFieldValidator<String?> validator;
  final TextInputType? keyboardType;
  final bool isPassword;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    keyboardType: widget.keyboardType,
    validator: widget.validator,
    obscureText: widget.isPassword && _obscurePassword,
    autofillHints: widget.isPassword
        ? const [AutofillHints.password]
        : widget.keyboardType == TextInputType.emailAddress
        ? const [AutofillHints.email]
        : null,
    decoration: InputDecoration(
      hintText: widget.hint,
      prefixIcon: Icon(widget.prefixIcon),
      suffixIcon: widget.isPassword
          ? IconButton(
              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            )
          : null,
    ),
  );
}
