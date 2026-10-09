/// "Lapidary Archaeological Interface" design system (DESIGN.md).
///
/// Ancient carved stone: weathered sandstone, cast bronze with verdigris
/// patina, carved bone, parchment with letterpressed sepia type — under a
/// warm museum spotlight from high-left (~315°). No neon, no glow effects,
/// no generic Material look.
library;

import 'package:flutter/material.dart';

class Lapidary {
  Lapidary._();

  // --- palette ---------------------------------------------------------------
  static const sandstone = Color(0xFFC2A87D); // Roman Sandstone (primary)
  static const sandstoneLight = Color(0xFFDCC79C);
  static const sandstoneDeep = Color(0xFF9A7F57);
  static const bronze = Color(0xFF8C6239); // Cast Speculum Bronze (secondary)
  static const bronzeLight = Color(0xFFB98D4F);
  static const bronzeDark = Color(0xFF5E3F22);
  static const verdigris = Color(0xFF4A7C6D); // Verdigris Patina (tertiary)
  static const basalt = Color(0xFF3C2F21); // Shadowed Basalt (neutral canvas)
  static const basaltDeep = Color(0xFF241B12);
  static const umber = Color(0xFF1C1106); // Deep Umber
  static const parchment = Color(0xFFF4EBD0); // Parchment Substrate
  static const parchmentDeep = Color(0xFFDFD0AB);
  static const parchmentCream = Color(0xFFF5DFCA);
  static const chiselShadow = Color(0xFF1A140E);
  static const bone = Color(0xFFD0C5B7); // Carved Bone (P2 tokens)
  static const boneLight = Color(0xFFE8DCCB);
  static const boneDark = Color(0xFF8A7F6F);
  static const sepiaInk = Color(0xFF3A2514); // letterpressed body text

  /// Spotlight direction: from high-left. Unit vector for light placement.
  static const lightDir = Offset(-0.55, -0.83);

  // --- typography ---------------------------------------------------------------
  /// Bundled serif (DejaVu Serif, "StoneSerif") standing in for the
  /// inscriptional serif of the design system; offline-safe.
  static const String serif = 'StoneSerif';

  static TextStyle inscription(double size,
      {Color color = sandstoneLight, double spacing = 3.0}) {
    return TextStyle(
      fontFamily: serif,
      fontWeight: FontWeight.bold,
      fontSize: size,
      letterSpacing: spacing,
      color: color,
      shadows: const [
        Shadow(offset: Offset(0, 2), color: Colors.black87, blurRadius: 3),
        Shadow(offset: Offset(0, -1), color: Color(0x66FFFFFF), blurRadius: 1),
      ],
    );
  }

  /// Chiseled (carved-in) text on stone: dark cut with a lit lower lip.
  static TextStyle chiseled(double size,
      {Color color = sandstoneDeep, double spacing = 2.0}) {
    return TextStyle(
      fontFamily: serif,
      fontWeight: FontWeight.bold,
      fontSize: size,
      letterSpacing: spacing,
      color: color,
      shadows: const [
        Shadow(offset: Offset(0, -1.5), color: Color(0x99000000), blurRadius: 1),
        Shadow(offset: Offset(0, 1.5), color: Color(0xAAEAD9B4), blurRadius: 1),
      ],
    );
  }

  /// Embossed bronze lettering: raised, lit from above.
  static TextStyle embossed(double size,
      {Color color = parchmentCream, double spacing = 2.0}) {
    return TextStyle(
      fontFamily: serif,
      fontWeight: FontWeight.bold,
      fontSize: size,
      letterSpacing: spacing,
      color: color,
      shadows: const [
        Shadow(offset: Offset(0, -1.5), color: Color(0xAAFFF2D8), blurRadius: 1),
        Shadow(offset: Offset(0, 2), color: Color(0xFF2A1C0E), blurRadius: 2),
      ],
    );
  }

  /// Letterpressed sepia type on parchment.
  static TextStyle letterpress(double size,
      {Color color = sepiaInk, FontWeight weight = FontWeight.w600}) {
    return TextStyle(
      fontFamily: serif,
      fontWeight: weight,
      fontSize: size,
      color: color,
      shadows: const [
        Shadow(offset: Offset(0, 1), color: Color(0x66FFFFFF), blurRadius: 0),
      ],
    );
  }

  static TextStyle body(double size, {Color color = sepiaInk}) => TextStyle(
        fontFamily: serif,
        fontSize: size,
        color: color,
        height: 1.45,
      );

  // --- shared paint helpers --------------------------------------------------------
  /// Soft drop shadow paint for carved pieces.
  static Paint shadowPaint(double alpha) =>
      Paint()..color = Colors.black.withValues(alpha: alpha);

  /// Draws a rounded slab with beveled edges lit from [lightDir].
  static void paintSlab(Canvas canvas, RRect rect,
      {Color base = sandstone,
      double bevel = 6,
      double cornerLight = 0.35,
      double cornerDark = 0.45}) {
    // Base.
    canvas.drawRRect(rect, Paint()..color = base);
    final r = rect.outerRect;
    // Top-left bevel highlight.
    canvas.drawRRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = bevel
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: cornerLight),
              Colors.white.withValues(alpha: 0.0),
              Colors.black.withValues(alpha: cornerDark),
            ],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(r));
    // Inner ambient occlusion along the rim.
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            r.deflate(bevel * 0.9), const Radius.circular(10)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = bevel * 0.8
          ..color = Colors.black.withValues(alpha: 0.18));
  }

  /// Parchment panel with soft cast shadow and a darker deckled edge.
  static void paintParchment(Canvas canvas, RRect rect) {
    // Cast shadow onto the stone beneath.
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            rect.outerRect.shift(const Offset(0, 6)),
            rect.tlRadius),
        Paint()..color = Colors.black.withValues(alpha: 0.35));
    canvas.drawRRect(rect, Paint()..color = parchment);
    // Aged edge: darker rim + inner highlight.
    canvas.drawRRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = parchmentDeep);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            rect.outerRect.deflate(5), const Radius.circular(6)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = parchmentCream.withValues(alpha: 0.9));
  }
}
