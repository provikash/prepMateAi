import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class AuthField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final FormFieldValidator<String?> validator;
  final TextInputType? keyboardType;
  final bool isPassword;
  const AuthField({
    super.key,
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    required this.validator,
    this.keyboardType,
    required this.isPassword,
  });

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _obscurePassword = true;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: colors.border, width: 0.6),
      ),
      child: TextFormField(
        controller: widget.controller,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        obscureText: widget.isPassword ? _obscurePassword : false,
        style: TextStyle(color: colors.textSecondary),

        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(color: colors.textSecondary),
        

        prefixIcon: Icon(widget.prefixIcon, color: colors.primary),
        suffixIcon: widget.isPassword
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: colors.textSecondary,
                ),
              )
            : null,
        filled: true,
        fillColor: colors.mutedBackground,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primary, width: 1.4),
        ),
      ),
     ) );
  }
}
