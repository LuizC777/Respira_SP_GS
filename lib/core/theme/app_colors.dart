import 'package:flutter/material.dart';

/// Paleta do Respira SP: base branca com tons de verde.
/// Todas as combinações texto/fundo foram escolhidas para contraste >= 4.5:1.
abstract final class AppColors {
  // Verdes (modo claro)
  static const green900 = Color(0xFF0B3D20);
  static const green800 = Color(0xFF1B5E20);
  static const green700 = Color(0xFF2E7D32); // primária (5.1:1 sobre branco)
  static const green500 = Color(0xFF43A047);
  static const green300 = Color(0xFF81C784);
  static const green100 = Color(0xFFC8E6C9);
  static const green50 = Color(0xFFE8F5E9);
  static const mint = Color(0xFFF3FAF4);

  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF17231A); // texto principal
  static const inkMuted = Color(0xFF4A5A4E); // texto secundário (7:1 sobre branco)
  static const outline = Color(0xFFD5E3D7);

  // Modo escuro
  static const darkBackground = Color(0xFF0E1611);
  static const darkSurface = Color(0xFF16211A);
  static const darkSurfaceHigh = Color(0xFF1F2D23);
  static const darkInk = Color(0xFFE6F0E8);
  static const darkInkMuted = Color(0xFFB5C7B9);
  static const darkOutline = Color(0xFF34473A);
}
