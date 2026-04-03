import 'package:flutter/material.dart';
import '../../config/theme.dart';

class NeuTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool isPassword;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final TextCapitalization capitalization;

  const NeuTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.isPassword = false,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.capitalization = TextCapitalization.none,
  });

  @override
  State<NeuTextField> createState() => _NeuTextFieldState();
}

class _NeuTextFieldState extends State<NeuTextField> {
  bool obscure = true;

  BoxDecoration _decoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BoxDecoration(
      color: isDark
          ? AppTheme.darkSurface
          : Theme.of(context).scaffoldBackgroundColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: isDark ? AppTheme.darkShadow : AppTheme.lightShadow,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: _decoration(context),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextFormField(
        controller: widget.controller,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        textCapitalization: widget.capitalization,
        obscureText: widget.isPassword ? obscure : false,
        style: theme.textTheme.labelMedium,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          hintStyle: theme.textTheme.bodyMedium,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: true,
          fillColor: Colors.transparent,

          prefixIcon: widget.prefixIcon != null
              ? Icon(
            widget.prefixIcon,
            color: theme.textTheme.bodyMedium?.color,
          )
              : null,

          suffixIcon: widget.isPassword
              ? IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: theme.textTheme.bodyMedium?.color,
            ),
            onPressed: () {
              setState(() {
                obscure = !obscure;
              });
            },
          )
              : null,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}