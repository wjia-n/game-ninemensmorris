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
import '../theme/morris_themes.dart';
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

  /// Carved-stone theme (null = the default Lapidary palette).
  final MorrisTheme? theme;

  /// Piece style (null = classic disc).
  final PieceStyle? pieceStyle;

  /// Board accent (null = verdigris default).
  final BoardAccent? accent;

  /// Slide animation: origin of a moving token (drawn as a fading trail).
  final int slideFrom;

  /// Capture staging: the doomed man, ringed before removal.
  final int doomedIdx;

  MorrisTheme get _t => theme ?? morrisThemes.first;
  PieceStyle get _ps => pieceStyle ?? pieceStyles.first;
  BoardAccent get _a => accent ?? boardAccents.first;

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
    this.theme,
    this.pieceStyle,
    this.accent,
    this.slideFrom = -1,
    this.doomedIdx = -1,
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
    _paintSlideTrail(canvas, size);
    _paintTokens(canvas, size);
    _paintDoomed(canvas, size);
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
    Lapidary.paintSlab(canvas, slabRect, base: _t.sandstone, bevel: 8);

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
            ..color = (dark ? _t.bronzeDark : _t.sandstoneLight)
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
            ..color =
                (rng.nextBool() ? _t.bronzeDark : _t.sandstoneLight)
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
              ..color = _t.sandstoneLight.withValues(alpha: 0.55)
              ..strokeWidth = 9
              ..strokeCap = StrokeCap.round);
        canvas.drawLine(
            a,
            b,
            Paint()
              ..color = _t.grooveDark
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
          c, r * 0.58, Paint()..color = _t.socketDeep);
      canvas.drawCircle(
          c + const Offset(-1.5, -1.5),
          r * 0.58,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = _t.sandstoneLight.withValues(alpha: 0.5));
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
            ..color = _a.moveTarget.withValues(alpha: 0.25 * glow)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawCircle(
          c, r, Paint()..color = _a.moveTarget.withValues(alpha: glow));
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
            ..color = _a.millFlash.withValues(alpha: 0.9));
    }
    if (hintTo != null && hintTo! >= 0) {
      final c = pointAt(hintTo!, size);
      canvas.drawCircle(
          c,
          r + 7,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = _t.bronzeLight.withValues(alpha: 0.9));
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
              ..color = _t.bronzeLight.withValues(alpha: glow));
        canvas.drawCircle(
            c,
            rr + 13,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = _a.millFlash.withValues(alpha: glow * 0.7));
      }
    }
  }

  /// One physical token: contact shadow, lit disc, bevel, engraved rings,
  /// patina (bronze) and a raised center boss — in the active carved-stone
  /// theme and piece style.
  void _paintToken(Canvas canvas, Offset c, double r, int seat,
      {double shadowScale = 1.0, double shadowAlpha = 0.38}) {
    final bronze = seat == 0;
    final ps = _ps;
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

    final light = bronze ? _t.bronzeLight : const Color(0xFFF2E8D6);
    final mid = bronze ? _t.bronze : _t.bone;
    final dark = bronze ? _t.bronzeDark : _t.boneDark;

    // Token body: disc, hexagon-cut stone, or square stele per piece style.
    Path? shapePath;
    if (ps.hex || ps.square) {
      shapePath = Path();
      final n = ps.hex ? 6 : 4;
      final rot = ps.hex ? -pi / 6 : -pi / 4;
      for (var k = 0; k < n; k++) {
        final a = rot + k * 2 * pi / n;
        final p = c + Offset(cos(a) * r, sin(a) * r);
        if (k == 0) {
          shapePath.moveTo(p.dx, p.dy);
        } else {
          shapePath.lineTo(p.dx, p.dy);
        }
      }
      shapePath.close();
      canvas.drawPath(
          shapePath,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.45, -0.55),
              radius: 1.15,
              colors: [light, mid, dark],
              stops: const [0.0, 0.55, 1.0],
            ).createShader(Rect.fromCircle(center: c, radius: r)));
    } else {
      // Lit disc.
      final discRect = Rect.fromCircle(center: c, radius: r);
      canvas.drawCircle(
          c,
          r,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.45, -0.55),
              radius: 1.15,
              colors: [light, mid, dark],
              stops: const [0.0, 0.55, 1.0],
            ).createShader(discRect));

      // Rim bevel: lit upper-left arc, shadowed lower-right arc.
      canvas.drawArc(
          discRect, pi * 0.75, pi * 1.1, false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.14
            ..strokeCap = StrokeCap.round
            ..color = Colors.white.withValues(alpha: 0.30));
      canvas.drawArc(
          discRect.deflate(r * 0.07), -pi * 0.25, pi * 1.1, false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.12
            ..strokeCap = StrokeCap.round
            ..color = Colors.black.withValues(alpha: 0.35));
    }

    // Engraving: concentric rings or a carved spiral.
    final ringColor = dark.withValues(alpha: 0.75);
    if (ps.spiral) {
      final path = Path();
      for (var a = 0.0; a < 12.5; a += 0.2) {
        final rr = r * 0.12 + (a / 12.5) * r * 0.60;
        final p = c + Offset(cos(a) * rr, sin(a) * rr);
        if (a == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(1.2, r * 0.045)
            ..color = ringColor);
    } else {
      for (var k = 1; k <= ps.ringCount; k++) {
        final rr = r * (0.24 + 0.22 * k);
        if (rr >= r * 0.92) continue;
        canvas.drawCircle(
            c,
            rr,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = max(1.2, r * 0.045)
              ..color = ringColor);
        canvas.drawCircle(
            c + const Offset(-1, -1),
            rr,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = Colors.white.withValues(alpha: 0.18));
      }
    }

    // Verdigris patina blooms on bronze.
    if (bronze && ps.patina > 0) {
      final rng = Random(7);
      final blooms = (2 + ps.patina * 4).round();
      for (var k = 0; k < blooms; k++) {
        final a = rng.nextDouble() * 2 * pi;
        final d = r * (0.45 + rng.nextDouble() * 0.35);
        canvas.drawCircle(
            c + Offset(cos(a) * d, sin(a) * d),
            r * (0.10 + rng.nextDouble() * 0.10),
            Paint()
              ..color = _t.verdigris.withValues(alpha: 0.42 * ps.patina)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
      }
    } else if (!bronze) {
      // Bone grain: faint carved striations.
      final rng = Random(11);
      for (var k = 0; k < 5; k++) {
        final a = rng.nextDouble() * 2 * pi;
        canvas.drawLine(
            c + Offset(cos(a) * r * 0.2, sin(a) * r * 0.2),
            c + Offset(cos(a) * r * 0.8, sin(a) * r * 0.8),
            Paint()
              ..strokeWidth = 1
              ..color = dark.withValues(alpha: 0.25));
      }
    }

    // Raised center boss catching the spotlight.
    if (ps.bossScale > 0) {
      final bossR = r * 0.20 * ps.bossScale;
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
              colors: [light, dark],
            ).createShader(Rect.fromCircle(center: c, radius: bossR)));
    }
  }

  /// Slide trail: a fading ghost from the move origin to the destination,
  /// so bot (and human) slides read as physical motion, not teleportation.
  void _paintSlideTrail(Canvas canvas, Size size) {
    if (slideFrom < 0 || slideFrom >= 24) return;
    final to = popIdx;
    if (to < 0 || to >= 24 || board[to] == -1) return;
    final a = pointAt(slideFrom, size);
    final b = pointAt(to, size);
    final r = tokenRadius(size);
    final steps = 5;
    for (var k = 1; k <= steps; k++) {
      final t = k / (steps + 1);
      final p = Offset(
        a.dx + (b.dx - a.dx) * t,
        a.dy + (b.dy - a.dy) * t,
      );
      canvas.drawCircle(
          p,
          r * 0.55 * (1 - t * 0.5),
          Paint()
            ..color = _a.moveTarget.withValues(alpha: 0.16 * (1 - t)));
    }
  }

  /// The doomed man (bot capture staging): a pulsing warning ring before the
  /// piece is lifted off the stone.
  void _paintDoomed(Canvas canvas, Size size) {
    if (doomedIdx < 0 || doomedIdx >= 24 || board[doomedIdx] == -1) return;
    final c = pointAt(doomedIdx, size);
    final r = tokenRadius(size);
    final glow = 0.55 + 0.45 * sin(pulse * 2 * pi);
    canvas.drawCircle(
        c,
        r + 8,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = const Color(0xFF9A3A2A).withValues(alpha: glow));
    canvas.drawCircle(
        c,
        r + 14,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFF9A3A2A).withValues(alpha: glow * 0.6));
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
            ..color = _a.millFlash.withValues(alpha: glow));
      canvas.drawCircle(
          c,
          r + 12,
          Paint()
            ..color = _a.millFlash.withValues(alpha: 0.14 * glow)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter old) => true;
}
