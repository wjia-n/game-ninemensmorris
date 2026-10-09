/// The carved sandstone board: weathered slab, chisel-cut grooves, recessed
/// point sockets, and bronze/bone tokens with realistic lighting.
///
/// Light comes from the upper-left (~315°). Every element is layered to read
/// as a physical object: cast shadows, bevels, inner groove shadows, ambient
/// occlusion where tokens meet stone. Animations (placement pop, mill pulse,
/// capture flash) use weighted easing so moves feel heavy.
library;

import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/morris.dart';
import 'lapidary.dart';

class BoardPainter extends CustomPainter {
  final List<int> board;
  final int turn;
  final int selected;
  final List<int> captureTargets;
  final List<int> moveTargets;
  final Set<int> millFlash;
  final int popIdx;
  final double popT; // 0..1 placement pop progress
  final double pulse; // 0..1 repeating shimmer
  final int? hintFrom;
  final int? hintTo;
  final bool interactive;

  BoardPainter({
    super.repaint,
    required this.board,
    required this.turn,
    required this.selected,
    required this.captureTargets,
    required this.moveTargets,
    required this.millFlash,
    required this.popIdx,
    required this.popT,
    required this.pulse,
    required this.hintFrom,
    required this.hintTo,
    this.interactive = true,
  });

  /// Demo arrangement for the menu vignette (non-interactive).
  factory BoardPainter.decorative({Listenable? repaint, double pulse = 0}) {
    final demo = List<int>.filled(24, -1);
    for (final i in [0, 2, 9, 11, 16, 21]) {
      demo[i] = 0;
    }
    for (final i in [4, 6, 10, 14, 18, 22]) {
      demo[i] = 1;
    }
    return BoardPainter(
      repaint: repaint,
      board: demo,
      turn: 0,
      selected: -1,
      captureTargets: const [],
      moveTargets: const [],
      millFlash: const {0, 1, 2},
      popIdx: -1,
      popT: 0,
      pulse: pulse,
      hintFrom: null,
      hintTo: null,
      interactive: false,
    );
  }

  static Offset pointAt(int i, Size size) {
    const pad = 46.0;
    final s = (size.shortestSide - pad * 2) / 6;
    final ox = (size.width - s * 6) / 2;
    final oy = (size.height - s * 6) / 2;
    final xy = MorrisBoard.xy[i];
    return Offset(ox + xy[0] * s, oy + xy[1] * s);
  }

  static double tokenRadius(Size size) {
    const pad = 46.0;
    final s = (size.shortestSide - pad * 2) / 6;
    return s * 0.44;
  }

  static int? cellAt(Offset p, Size size) {
    final s = (size.shortestSide - 92) / 6;
    var bestD = 1e9;
    int? best;
    for (var i = 0; i < 24; i++) {
      final d = (p - pointAt(i, size)).distance;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return bestD <= s * 0.5 ? best : null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintSlab(canvas, size);
    _paintGrooves(canvas, size);
    _paintSockets(canvas, size);
    _paintMoveTargets(canvas, size);
    _paintHint(canvas, size);
    _paintTokens(canvas, size);
    _paintMillFlash(canvas, size);
  }

  // --- slab ----------------------------------------------------------------------
  void _paintSlab(Canvas canvas, Size size) {
    final slabRect = RRect.fromRectAndRadius(
        Offset.zero & size, const Radius.circular(18));
    // Cast shadow of the whole slab onto the vault.
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            (Offset.zero & size).shift(const Offset(0, 14)),
            const Radius.circular(18)),
        Paint()..color = Colors.black.withValues(alpha: 0.5));
    Lapidary.paintSlab(canvas, slabRect,
        base: Lapidary.sandstone, bevel: 8);

    // Weathering: soft tonal blotches baked into the stone.
    final rng = Random(42);
    for (var k = 0; k < 26; k++) {
      final cx = rng.nextDouble() * size.width;
      final cy = rng.nextDouble() * size.height;
      final cr = 24 + rng.nextDouble() * 60;
      final dark = rng.nextBool();
      canvas.drawCircle(
          Offset(cx, cy),
          cr,
          Paint()
            ..color = (dark ? Lapidary.bronzeDark : Lapidary.sandstoneLight)
                .withValues(alpha: 0.05)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));
    }
    // Grain speckle.
    for (var k = 0; k < 140; k++) {
      final cx = rng.nextDouble() * size.width;
      final cy = rng.nextDouble() * size.height;
      canvas.drawCircle(
          Offset(cx, cy),
          0.8 + rng.nextDouble() * 1.4,
          Paint()
            ..color = (rng.nextBool()
                    ? Lapidary.bronzeDark
                    : Lapidary.sandstoneLight)
                .withValues(alpha: 0.10));
    }
    // Pitting: tiny dark chips.
    for (var k = 0; k < 36; k++) {
      final cx = rng.nextDouble() * size.width;
      final cy = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(cx, cy), 1.2 + rng.nextDouble() * 2.2,
          Paint()..color = Lapidary.umber.withValues(alpha: 0.16));
    }
    // Corner vignette / ambient occlusion on the slab.
    canvas.drawRRect(
        slabRect,
        Paint()
          ..shader = RadialGradient(
            center: Alignment.center,
            radius: 0.75,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.22),
            ],
            stops: const [0.55, 1.0],
          ).createShader(Offset.zero & size));
  }

  // --- grooves ----------------------------------------------------------------------
  void _paintGrooves(Canvas canvas, Size size) {
    for (var i = 0; i < 24; i++) {
      for (final j in MorrisBoard.adj[i]) {
        if (j <= i) continue;
        final a = pointAt(i, size);
        final b = pointAt(j, size);
        // Chiseled trench: lit lip on the upper-left wall, dark core.
        canvas.drawLine(
            a + const Offset(-2.2, -2.2),
            b + const Offset(-2.2, -2.2),
            Paint()
              ..color = Lapidary.sandstoneLight.withValues(alpha: 0.55)
              ..strokeWidth = 9
              ..strokeCap = StrokeCap.round);
        canvas.drawLine(
            a,
            b,
            Paint()
              ..color = const Color(0xFF3A2C1C)
              ..strokeWidth = 8
              ..strokeCap = StrokeCap.round);
        canvas.drawLine(
            a,
            b,
            Paint()
              ..color = Lapidary.chiselShadow.withValues(alpha: 0.88)
              ..strokeWidth = 5
              ..strokeCap = StrokeCap.round);
      }
    }
  }

  // --- sockets ----------------------------------------------------------------------
  void _paintSockets(Canvas canvas, Size size) {
    final r = tokenRadius(size);
    for (var i = 0; i < 24; i++) {
      if (board[i] != -1) continue;
      final c = pointAt(i, size);
      // Recessed stone cup.
      canvas.drawCircle(
          c + Offset(r * 0.12, r * 0.18),
          r * 0.62,
          Paint()..color = Colors.black.withValues(alpha: 0.28));
      canvas.drawCircle(
          c, r * 0.58, Paint()..color = const Color(0xFF2E2115));
      canvas.drawCircle(
          c + const Offset(-1.5, -1.5),
          r * 0.58,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Lapidary.sandstoneLight.withValues(alpha: 0.5));
      canvas.drawCircle(
          c, r * 0.40, Paint()..color = Lapidary.umber.withValues(alpha: 0.55));
    }
  }

  // --- move targets / hint ----------------------------------------------------------------------
  void _paintMoveTargets(Canvas canvas, Size size) {
    for (final i in moveTargets) {
      final c = pointAt(i, size);
      final r = tokenRadius(size) * 0.30;
      final glow = 0.55 + 0.35 * sin(pulse * 2 * pi);
      canvas.drawCircle(
          c,
          r + 4,
          Paint()
            ..color = Lapidary.verdigris.withValues(alpha: 0.25 * glow)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawCircle(
          c, r, Paint()..color = Lapidary.verdigris.withValues(alpha: glow));
      canvas.drawCircle(
          c + const Offset(-1, -1),
          r * 0.45,
          Paint()..color = Colors.white.withValues(alpha: 0.5));
    }
  }

  void _paintHint(Canvas canvas, Size size) {
    final r = tokenRadius(size);
    if (hintFrom != null && hintFrom! >= 0 && board[hintFrom!] != -1) {
      final c = pointAt(hintFrom!, size);
      canvas.drawCircle(
          c,
          r + 7,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = Lapidary.verdigris.withValues(alpha: 0.9));
    }
    if (hintTo != null && hintTo! >= 0) {
      final c = pointAt(hintTo!, size);
      canvas.drawCircle(
          c,
          r + 7,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = Lapidary.bronzeLight.withValues(alpha: 0.9));
    }
  }

  // --- tokens ----------------------------------------------------------------------
  void _paintTokens(Canvas canvas, Size size) {
    final r = tokenRadius(size);
    for (var i = 0; i < 24; i++) {
      final seat = board[i];
      if (seat == -1) continue;
      var c = pointAt(i, size);
      var rr = r;

      // Placement pop: heavy drop with overshoot.
      if (i == popIdx && popT < 1) {
        final e = Curves.easeOutBack.transform(popT.clamp(0.0, 1.0));
        rr = r * (0.4 + 0.6 * e);
      }
      // Selected token lifts off the stone.
      final lifted = interactive && i == selected;
      if (lifted) {
        c += Offset(-r * 0.18, -r * 0.30);
      }
      _paintToken(canvas, c, rr, seat,
          shadowScale: lifted ? 1.5 : 1.0,
          shadowAlpha: lifted ? 0.5 : 0.38);

      if (interactive && captureTargets.contains(i)) {
        final glow = 0.6 + 0.4 * sin(pulse * 2 * pi);
        canvas.drawCircle(
            c,
            rr + 8,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
              ..color = Lapidary.bronzeLight.withValues(alpha: glow));
        canvas.drawCircle(
            c,
            rr + 13,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = Lapidary.verdigris.withValues(alpha: glow * 0.7));
      }
    }
  }

  /// One physical token: contact shadow, lit disc, bevel, engraved rings,
  /// patina (bronze) and a raised center boss.
  void _paintToken(Canvas canvas, Offset c, double r, int seat,
      {double shadowScale = 1.0, double shadowAlpha = 0.38}) {
    final bronze = seat == 0;
    // Contact shadow with ambient occlusion closest to the token.
    canvas.drawCircle(
        c + Offset(r * 0.22 * shadowScale, r * 0.42 * shadowScale),
        r * 1.02 * shadowScale,
        Paint()
          ..color = Colors.black.withValues(alpha: shadowAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    canvas.drawCircle(
        c + Offset(r * 0.10, r * 0.20),
        r * 0.96,
        Paint()
          ..color = Colors.black.withValues(alpha: shadowAlpha * 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    // Lit disc.
    final discRect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.45, -0.55),
            radius: 1.15,
            colors: bronze
                ? const [
                    Color(0xFFD9A860),
                    Lapidary.bronze,
                    Color(0xFF4A2F18),
                  ]
                : const [
                    Color(0xFFF2E8D6),
                    Lapidary.bone,
                    Color(0xFF7E7263),
                  ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(discRect));

    // Rim bevel: lit upper-left arc, shadowed lower-right arc.
    canvas.drawArc(
        discRect, pi * 0.75, pi * 1.1, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.14
          ..strokeCap = StrokeCap.round
          ..color = (bronze ? Colors.white : Colors.white)
              .withValues(alpha: 0.30));
    canvas.drawArc(
        discRect.deflate(r * 0.07), -pi * 0.25, pi * 1.1, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.12
          ..strokeCap = StrokeCap.round
          ..color = Colors.black.withValues(alpha: 0.35));

    // Concentric engraved rings.
    final ringColor =
        (bronze ? Lapidary.bronzeDark : Lapidary.boneDark)
            .withValues(alpha: 0.75);
    for (final rr in [0.66, 0.44]) {
      canvas.drawCircle(
          c,
          r * rr,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(1.2, r * 0.045)
            ..color = ringColor);
      canvas.drawCircle(
          c + const Offset(-1, -1),
          r * rr,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = Colors.white.withValues(alpha: 0.18));
    }

    // Verdigris patina blooms on bronze.
    if (bronze) {
      final rng = Random(7);
      for (var k = 0; k < 4; k++) {
        final a = rng.nextDouble() * 2 * pi;
        final d = r * (0.45 + rng.nextDouble() * 0.35);
        canvas.drawCircle(
            c + Offset(cos(a) * d, sin(a) * d),
            r * (0.10 + rng.nextDouble() * 0.10),
            Paint()
              ..color = Lapidary.verdigris.withValues(alpha: 0.42)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
      }
    } else {
      // Bone grain: faint carved striations.
      final rng = Random(11);
      for (var k = 0; k < 5; k++) {
        final a = rng.nextDouble() * 2 * pi;
        canvas.drawLine(
            c + Offset(cos(a) * r * 0.2, sin(a) * r * 0.2),
            c + Offset(cos(a) * r * 0.8, sin(a) * r * 0.8),
            Paint()
              ..strokeWidth = 1
              ..color = Lapidary.boneDark.withValues(alpha: 0.25));
      }
    }

    // Raised center boss catching the spotlight.
    final bossR = r * 0.20;
    canvas.drawCircle(
        c + Offset(0, bossR * 0.35),
        bossR,
        Paint()..color = Colors.black.withValues(alpha: 0.30));
    canvas.drawCircle(
        c,
        bossR,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.4, -0.5),
            radius: 1.0,
            colors: bronze
                ? const [Color(0xFFE0B268), Lapidary.bronzeDark]
                : const [Color(0xFFFFF6E6), Lapidary.boneDark],
          ).createShader(Rect.fromCircle(center: c, radius: bossR)));
  }

  // --- mill flash ----------------------------------------------------------------------
  void _paintMillFlash(Canvas canvas, Size size) {
    if (millFlash.isEmpty) return;
    final r = tokenRadius(size);
    final glow = 0.45 + 0.4 * sin(pulse * 2 * pi);
    for (final i in millFlash) {
      if (i < 0 || i >= 24) continue;
      final c = pointAt(i, size);
      canvas.drawCircle(
          c,
          r + 6 + 3 * sin(pulse * 2 * pi),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..color = Lapidary.verdigris.withValues(alpha: glow));
      canvas.drawCircle(
          c,
          r + 12,
          Paint()
            ..color = Lapidary.verdigris.withValues(alpha: 0.14 * glow)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter old) => true;
}
