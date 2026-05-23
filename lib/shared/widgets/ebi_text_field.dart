import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

/// Champ de saisie EBI : label au-dessus, message d'erreur en dessous.
/// Cohérent avec le composant Input.vue côté web.
class EbiTextField extends StatelessWidget {
  const EbiTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.error,
    this.helper,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.suffix,
    this.prefix,
    this.autocorrect = true,
    this.autofocus = false,
    this.enabled = true,
    this.required = false,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? error;
  final String? helper;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;
  final Widget? prefix;
  final bool autocorrect;
  final bool autofocus;
  final bool enabled;
  final bool required;
  final List<dynamic>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500, color: EbiColors.ink2,
              ),
            ),
            if (required) const Text(' *', style: TextStyle(color: EbiColors.danger)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          autocorrect: autocorrect,
          autofocus: autofocus,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefix,
            suffixIcon: suffix,
            errorText: error,
          ),
        ),
        if (helper != null && error == null) ...[
          const SizedBox(height: 4),
          Text(helper!, style: const TextStyle(fontSize: 11, color: EbiColors.ink3)),
        ],
      ],
    );
  }
}
