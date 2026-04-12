import 'package:flutter/material.dart';

/// Full Material 3 color tokens — mapped 1:1 from the HTML/Tailwind design.
class AppColors {
  // ─── Surfaces ──────────────────────────────────────────
  static const Color background         = Color(0xFF101419);
  static const Color surface            = Color(0xFF101419);
  static const Color surfaceDim         = Color(0xFF101419);
  static const Color surfaceBright      = Color(0xFF36393F);
  static const Color surfaceContainerLowest  = Color(0xFF0A0E13);
  static const Color surfaceContainerLow     = Color(0xFF181C21);
  static const Color surfaceContainer        = Color(0xFF1C2025);
  static const Color surfaceContainerHigh    = Color(0xFF262A30);
  static const Color surfaceContainerHighest = Color(0xFF31353B);
  static const Color surfaceVariant     = Color(0xFF31353B);

  // ─── On Surface ────────────────────────────────────────
  static const Color onSurface          = Color(0xFFE0E2EA);
  static const Color onSurfaceVariant   = Color(0xFFC5C9AC);
  static const Color onBackground       = Color(0xFFE0E2EA);

  // ─── Primary / Neon Accent ─────────────────────────────
  static const Color primaryContainer   = Color(0xFFCDF200);
  static const Color neonAccent         = Color(0xFFD9FF00);
  static const Color primaryFixed       = Color(0xFFCDF200);
  static const Color primaryFixedDim    = Color(0xFFB4D400);
  static const Color onPrimary          = Color(0xFF2B3400);
  static const Color onPrimaryFixed     = Color(0xFF181E00);
  static const Color onPrimaryContainer = Color(0xFF5A6B00);
  static const Color inversePrimary     = Color(0xFF556500);
  static const Color surfaceTint        = Color(0xFFB4D400);

  // ─── Secondary ─────────────────────────────────────────
  static const Color secondary          = Color(0xFFC2C6D6);
  static const Color secondaryContainer = Color(0xFF444956);
  static const Color onSecondary        = Color(0xFF2B303D);
  static const Color secondaryFixed     = Color(0xFFDEE2F3);
  static const Color secondaryFixedDim  = Color(0xFFC2C6D6);
  static const Color onSecondaryContainer     = Color(0xFFB4B8C8);
  static const Color onSecondaryFixed         = Color(0xFF161B27);
  static const Color onSecondaryFixedVariant  = Color(0xFF424754);

  // ─── Tertiary ──────────────────────────────────────────
  static const Color tertiaryContainer  = Color(0xFFCEE6F2);
  static const Color onTertiary         = Color(0xFF1C333D);
  static const Color onTertiaryContainer = Color(0xFF516872);

  // ─── Error ─────────────────────────────────────────────
  static const Color error              = Color(0xFFFFB4AB);
  static const Color errorContainer     = Color(0xFF93000A);
  static const Color onError            = Color(0xFF690005);
  static const Color onErrorContainer   = Color(0xFFFFDAD6);

  // ─── Outlines ──────────────────────────────────────────
  static const Color outline            = Color(0xFF8F9378);
  static const Color outlineVariant     = Color(0xFF454932);

  // ─── Inverse ───────────────────────────────────────────
  static const Color inverseSurface     = Color(0xFFE0E2EA);
  static const Color inverseOnSurface   = Color(0xFF2D3136);

  // ─── Convenience aliases ───────────────────────────────
  /// Subtle white used for faint borders in the HTML:  border-white/5
  static Color get whiteBorder5  => Colors.white.withValues(alpha: 0.05);
  static Color get whiteBorder3  => Colors.white.withValues(alpha: 0.03);
}
