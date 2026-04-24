import 'package:flutter/material.dart';

/// DomFix Design System — Clean, minimal, professional.
///
/// Inspired by Uber, Airbnb, Fiverr: high contrast, intentional accent usage,
/// consistent spacing, zero visual noise.
class AppColors {
  AppColors._();

  // ─── Core Surfaces ─────────────────────────────────────
  static const Color background        = Color(0xFF0F1115);
  static const Color surface           = Color(0xFF181A20);
  static const Color surfaceDim        = Color(0xFF0F1115);
  static const Color surfaceBright     = Color(0xFF2A2C34);

  static const Color surfaceContainerLowest  = Color(0xFF0C0D11);
  static const Color surfaceContainerLow     = Color(0xFF161820);
  static const Color surfaceContainer        = Color(0xFF1C1E26);
  static const Color surfaceContainerHigh    = Color(0xFF22242C);
  static const Color surfaceContainerHighest = Color(0xFF2A2C34);
  static const Color surfaceVariant          = Color(0xFF2A2C34);

  // ─── On Surface (Text) ─────────────────────────────────
  static const Color onSurface          = Color(0xFFF5F5F7);
  static const Color onSurfaceVariant   = Color(0xFF8E8E93);
  static const Color onBackground       = Color(0xFFF5F5F7);

  // ─── Primary / Neon Accent ─────────────────────────────
  static const Color primaryContainer   = Color(0xFFD9FF00);
  static const Color neonAccent         = Color(0xFFD9FF00);
  static const Color primaryFixed       = Color(0xFFD9FF00);
  static const Color primaryFixedDim    = Color(0xFFC4E800);
  static const Color onPrimary          = Color(0xFF1A1D00);
  static const Color onPrimaryFixed     = Color(0xFF1A1D00);
  static const Color onPrimaryContainer = Color(0xFF3D4700);
  static const Color inversePrimary     = Color(0xFF556500);
  static const Color surfaceTint        = Color(0xFFC4E800);

  // ─── Secondary ─────────────────────────────────────────
  static const Color secondary           = Color(0xFF8E8E93);
  static const Color secondaryContainer  = Color(0xFF2A2C34);
  static const Color onSecondary         = Color(0xFFF5F5F7);
  static const Color secondaryFixed      = Color(0xFFE5E5EA);
  static const Color secondaryFixedDim   = Color(0xFF8E8E93);
  static const Color onSecondaryContainer     = Color(0xFF8E8E93);
  static const Color onSecondaryFixed         = Color(0xFF1C1C1E);
  static const Color onSecondaryFixedVariant  = Color(0xFF48484A);

  // ─── Tertiary ──────────────────────────────────────────
  static const Color tertiaryContainer  = Color(0xFF007AFF);
  static const Color onTertiary         = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFFFFFFF);

  // ─── Error ─────────────────────────────────────────────
  static const Color error              = Color(0xFFFF3B30);
  static const Color errorContainer     = Color(0xFF3A1214);
  static const Color onError            = Color(0xFFFFFFFF);
  static const Color onErrorContainer   = Color(0xFFFFD6D3);

  // ─── Success ───────────────────────────────────────────
  static const Color success            = Color(0xFF34C759);
  static const Color successDim         = Color(0xFF1A3320);

  // ─── Outlines ──────────────────────────────────────────
  static const Color outline            = Color(0xFF3A3A3C);
  static const Color outlineVariant     = Color(0xFF2C2C2E);

  // ─── Inverse ───────────────────────────────────────────
  static const Color inverseSurface     = Color(0xFFF5F5F7);
  static const Color inverseOnSurface   = Color(0xFF1C1C1E);

  // ─── Convenience aliases ───────────────────────────────
  static Color get divider      => Colors.white.withValues(alpha: 0.06);
  static Color get whiteBorder5 => Colors.white.withValues(alpha: 0.06);
  static Color get whiteBorder3 => Colors.white.withValues(alpha: 0.04);

  // ─── Spacing System (8px grid) ─────────────────────────
  static const double space4  = 4;
  static const double space8  = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space40 = 40;
  static const double space48 = 48;

  // ─── Border Radius ─────────────────────────────────────
  static const double radiusSmall  = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge  = 16;
  static const double radiusXL     = 24;
  static const double radiusFull   = 999;
}
