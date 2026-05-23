import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

enum EbiButtonVariant { primary, secondary, ghost, danger }
enum EbiButtonSize { sm, md, lg }

/// Bouton EBI : variants + tailles + état loading. Cohérent avec Btn.vue web.
class EbiButton extends StatelessWidget {
  const EbiButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = EbiButtonVariant.primary,
    this.size = EbiButtonSize.md,
    this.loading = false,
    this.block = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final EbiButtonVariant variant;
  final EbiButtonSize size;
  final bool loading;
  final bool block;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    final colors = _colorsFor(variant, disabled);
    final padding = _paddingFor(size);
    final fontSize = _fontSizeFor(size);
    final height = _heightFor(size);

    Widget child = loading
        ? SizedBox(
            width: fontSize + 4, height: fontSize + 4,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(colors.foreground),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: fontSize + 2, color: colors.foreground),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: colors.foreground,
                ),
              ),
            ],
          );

    final button = Material(
      color: colors.background,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: disabled ? null : onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: colors.border != null ? Border.all(color: colors.border!) : null,
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );

    return block ? SizedBox(width: double.infinity, child: button) : button;
  }

  _ColorSet _colorsFor(EbiButtonVariant v, bool disabled) {
    if (disabled) {
      return _ColorSet(
        background: EbiColors.surface2,
        foreground: EbiColors.ink3,
        border: EbiColors.border,
      );
    }
    return switch (v) {
      EbiButtonVariant.primary => _ColorSet(
          background: EbiColors.blue, foreground: EbiColors.white),
      EbiButtonVariant.secondary => _ColorSet(
          background: EbiColors.white, foreground: EbiColors.ink, border: EbiColors.border),
      EbiButtonVariant.ghost => _ColorSet(
          background: Colors.transparent, foreground: EbiColors.ink2),
      EbiButtonVariant.danger => _ColorSet(
          background: EbiColors.danger, foreground: EbiColors.white),
    };
  }

  EdgeInsets _paddingFor(EbiButtonSize s) => switch (s) {
    EbiButtonSize.sm => const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    EbiButtonSize.md => const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    EbiButtonSize.lg => const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
  };

  double _fontSizeFor(EbiButtonSize s) => switch (s) {
    EbiButtonSize.sm => 12,
    EbiButtonSize.md => 14,
    EbiButtonSize.lg => 15,
  };

  double _heightFor(EbiButtonSize s) => switch (s) {
    EbiButtonSize.sm => 34,
    EbiButtonSize.md => 44,
    EbiButtonSize.lg => 52,
  };
}

class _ColorSet {
  _ColorSet({required this.background, required this.foreground, this.border});
  final Color background;
  final Color foreground;
  final Color? border;
}
