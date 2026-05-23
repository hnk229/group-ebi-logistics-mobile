import 'package:flutter/material.dart';

/// Palette officielle Group EBI Logistics — alignée sur le design Claude Design
/// utilisé côté web (resources/css/app.css).
/// Aucune nuance personnelle : on ne sort pas de cette liste.
class EbiColors {
  EbiColors._();

  // Couleur primaire (brand EBI)
  static const Color blue = Color(0xFF0E91C5);
  static const Color blueDark = Color(0xFF0A7BA8);
  static const Color bluePale = Color(0xFFE6F4FA);

  // Encres (texte)
  static const Color ink = Color(0xFF0F172A);      // slate-900
  static const Color ink2 = Color(0xFF334155);     // slate-700
  static const Color ink3 = Color(0xFF64748B);     // slate-500

  // Surfaces neutres
  static const Color surface = Color(0xFFF8FAFC);  // slate-50
  static const Color surface2 = Color(0xFFF1F5F9); // slate-100
  static const Color border = Color(0xFFE2E8F0);   // slate-200
  static const Color white = Color(0xFFFFFFFF);

  // Statuts
  static const Color success = Color(0xFF10B981);  // emerald-500
  static const Color successPale = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);  // amber-500
  static const Color warningPale = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFEF4444);   // red-500
  static const Color dangerPale = Color(0xFFFEE2E2);
}
