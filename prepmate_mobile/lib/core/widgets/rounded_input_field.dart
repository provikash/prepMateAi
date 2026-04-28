import 'package:flutter/material.dart';
import '../../config/theme.dart';

class RoundedInputField extends StatelessWidget {
  final String hintText;
  final Widget prefixIcon;
  final bool obscureText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  const RoundedInputField({
    super.key,
    required this.hintText,
    
    required this.prefixIcon,
    this.obscureText = false,
    this.controller,
    this.onChanged,
    this.suffix,
    this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

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
          )
        ],
        border: Border.all(color: colors.border, width: 0.6),
      ),

            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              onChanged: onChanged,
              validator: validator,
              keyboardType: keyboardType,
              textCapitalization: textCapitalization,
              decoration: InputDecoration(
                
                hintText: hintText,
          
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                suffix: suffix,
                prefixIcon: prefixIcon,

                filled: true,
                fillColor: colors.mutedBackground,
                enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colors.border),
          ),
          
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colors.primary, width: 1.4),
          )

         ),
             
            ),

          
          

        
      


      
    );
  }
}
