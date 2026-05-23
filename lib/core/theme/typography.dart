import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// Typographie EBI : Inter pour le texte, JetBrains Mono pour les chiffres/refs.
class EbiTypography {
  EbiTypography._();

  static TextTheme buildTextTheme() {
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      // Display / titres écrans pleins
      displayLarge: base.displayLarge?.copyWith(
        fontWeight: FontWeight.w600, color: EbiColors.ink, height: 1.1,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontWeight: FontWeight.w600, color: EbiColors.ink, height: 1.15,
      ),
      // Headlines (titre pages)
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 28, fontWeight: FontWeight.w600, color: EbiColors.ink, height: 1.2,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 22, fontWeight: FontWeight.w600, color: EbiColors.ink, height: 1.25,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 18, fontWeight: FontWeight.w600, color: EbiColors.ink, height: 1.3,
      ),
      // Titles (cards, sections)
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 16, fontWeight: FontWeight.w600, color: EbiColors.ink,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 14, fontWeight: FontWeight.w600, color: EbiColors.ink,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 12, fontWeight: FontWeight.w600, color: EbiColors.ink2,
      ),
      // Body
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 15, color: EbiColors.ink, height: 1.5,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14, color: EbiColors.ink2, height: 1.5,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12, color: EbiColors.ink3, height: 1.4,
      ),
      // Labels (boutons, badges)
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14, fontWeight: FontWeight.w500, color: EbiColors.ink,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12, fontWeight: FontWeight.w500, color: EbiColors.ink2,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11, fontWeight: FontWeight.w500, color: EbiColors.ink3,
        letterSpacing: 0.4,
      ),
    );
  }

  /// Style monospace pour les références, numéros, montants.
  static TextStyle mono({double fontSize = 13, FontWeight? fontWeight, Color? color}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w500,
      color: color ?? EbiColors.ink2,
    );
  }
}
