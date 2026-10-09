/// Customization stele: renameable players, 14 carved-stone themes, 10 piece
/// styles, 7 board accents, and a custom theme creator. Pro-gated choices
/// show a lock and deep-link to the PRO screen.
library;

import 'dart:math';

import 'package:flutter/material.dart';

import '../../audio/sound.dart';
import '../../state/settings.dart';
import '../../theme/morris_themes.dart';
import '../lapidary.dart';
import '../widgets.dart';

class CustomizeScreen extends StatelessWidget {
  final VoidCallback onOpenPro;
  const CustomizeScreen({super.key, required this.onOpenPro});

  @override
  Widget build(BuildContext context) {
    final s = SettingsStore.I;
    return Scaffold(
      body: VaultBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: s,
            builder: (context, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Cartouche(
                      title: 'CUSTOMIZE', subtitle: 'NAMES · STONE · STYLE'),
                  const SizedBox(height: 14),
                  _namesPanel(s),
                  const SizedBox(height: 12),
                  _heading('CARVED-STONE THEMES'),
                  const SizedBox(height: 8),
                  _themeGrid(context, s),
                  const SizedBox(height: 14),
                  _heading('PIECE STYLES'),
                  const SizedBox(height: 8),
                  _styleList(context, s),
                  const SizedBox(height: 14),
                  _heading('BOARD ACCENTS'),
                  const SizedBox(height: 8),
                  _accentRow(context, s),
                  const SizedBox(height: 14),
                  _heading('CUSTOM THEME CREATOR'),
                  const SizedBox(height: 8),
                  _customCreator(context, s),
                  const SizedBox(height: 18),
                  BronzeTablet(
                    label: 'BACK',
                    fontSize: 16,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _heading(String text) {
    return Text(text,
        style: Lapidary.letterpress(14, weight: FontWeight.bold));
  }

  // --- names ------------------------------------------------------------------
  Widget _namesPanel(SettingsStore s) {
    return ParchmentPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('PLAYERS',
              style: Lapidary.letterpress(13, weight: FontWeight.bold)),
          const SizedBox(height: 8),
          _nameField(s, 0),
          const SizedBox(height: 8),
          _nameField(s, 1),
        ],
      ),
    );
  }

  Widget _nameField(SettingsStore s, int seat) {
    final ctl = TextEditingController(text: s.playerName(seat));
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: seat == 0 ? s.activeTheme.bronze : s.activeTheme.bone,
            border: Border.all(color: Lapidary.umber, width: 1.2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: ctl,
            maxLength: 14,
            style: Lapidary.body(15),
            decoration: InputDecoration(
              counterText: '',
              labelText: seat == 0 ? 'Bronze player' : 'Bone player',
              labelStyle: Lapidary.body(12,
                  color: Lapidary.sepiaInk.withValues(alpha: 0.6)),
              filled: true,
              fillColor: Lapidary.parchmentDeep,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
            ),
            onSubmitted: (v) {
              s.setPlayerName(seat, v);
              Sound.I.click();
            },
            onChanged: (v) => s.setPlayerName(seat, v),
          ),
        ),
      ],
    );
  }

  // --- themes ------------------------------------------------------------------
  Widget _themeGrid(BuildContext context, SettingsStore s) {
    final all = [...morrisThemes];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: all.length + 1, // +1 for the custom slot
      itemBuilder: (ctx, i) {
        if (i == all.length) return _customSlot(context, s);
        final t = all[i];
        final unlocked = s.choiceUnlocked(proOnly: t.proOnly);
        final selected = s.themeId == t.id;
        return GestureDetector(
          onTap: () {
            if (!unlocked) {
              onOpenPro();
              return;
            }
            s.setTheme(t.id);
            Sound.I.click();
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? Lapidary.verdigris
                    : Lapidary.bronzeDark.withValues(alpha: 0.5),
                width: selected ? 2.5 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    offset: const Offset(0, 3),
                    blurRadius: 5),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        color: t.sandstone,
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _dot(t.bronze),
                              const SizedBox(width: 6),
                              _dot(t.bone),
                              const SizedBox(width: 6),
                              _dot(t.verdigris),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        color: t.parchment,
                        alignment: Alignment.center,
                        child: Text(t.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Lapidary.letterpress(11,
                                weight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                if (!unlocked)
                  Container(
                    color: Colors.black.withValues(alpha: 0.45),
                    alignment: Alignment.center,
                    child: const Icon(Icons.lock_outline,
                        color: Lapidary.parchment, size: 26),
                  ),
                if (selected)
                  const Positioned(
                    top: 6,
                    right: 8,
                    child: Icon(Icons.check_circle,
                        color: Lapidary.verdigris, size: 20),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _customSlot(BuildContext context, SettingsStore s) {
    final unlocked = s.proUnlocked;
    final selected = s.themeId == 'custom';
    final ct = s.customTheme;
    return GestureDetector(
      onTap: () {
        if (!unlocked) {
          onOpenPro();
          return;
        }
        s.setTheme('custom');
        Sound.I.click();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Lapidary.verdigris
                : Lapidary.bronzeDark.withValues(alpha: 0.5),
            width: selected ? 2.5 : 1.2,
            style: BorderStyle.solid,
          ),
          color: Lapidary.parchmentDeep,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _dot(ct.sandstone),
                        const SizedBox(width: 6),
                        _dot(ct.bronze),
                        const SizedBox(width: 6),
                        _dot(ct.bone),
                        const SizedBox(width: 6),
                        _dot(ct.verdigris),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text('Your Carving',
                        style: Lapidary.letterpress(11,
                            weight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            if (!unlocked)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black.withValues(alpha: 0.45),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.lock_outline,
                    color: Lapidary.parchment, size: 26),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color c) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c,
        border: Border.all(color: Colors.black.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(0, 2),
              blurRadius: 2),
        ],
      ),
    );
  }

  // --- piece styles ---------------------------------------------------------------
  Widget _styleList(BuildContext context, SettingsStore s) {
    return Column(
      children: [
        for (final ps in pieceStyles)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _choiceRow(
              context,
              s,
              title: ps.name,
              blurb: ps.blurb,
              proOnly: ps.proOnly,
              selected: s.pieceStyleId == ps.id,
              preview: _piecePreview(ps, s.activeTheme),
              onTap: () => s.setPieceStyle(ps.id),
            ),
          ),
      ],
    );
  }

  Widget _piecePreview(PieceStyle ps, MorrisTheme t) {
    return SizedBox(
      width: 40,
      height: 40,
      child: CustomPaint(painter: _StylePreviewPainter(ps, t)),
    );
  }

  // --- accents -----------------------------------------------------------------------
  Widget _accentRow(BuildContext context, SettingsStore s) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final a in boardAccents)
          GestureDetector(
            onTap: () {
              if (!s.choiceUnlocked(proOnly: a.proOnly)) {
                onOpenPro();
                return;
              }
              s.setAccent(a.id);
              Sound.I.click();
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: a.inlay,
                    border: Border.all(
                      color: s.accentId == a.id
                          ? Lapidary.verdigris
                          : Lapidary.bronzeDark.withValues(alpha: 0.5),
                      width: s.accentId == a.id ? 3 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          offset: const Offset(0, 3),
                          blurRadius: 4),
                    ],
                  ),
                  child: !s.choiceUnlocked(proOnly: a.proOnly)
                      ? const Icon(Icons.lock_outline,
                          color: Colors.white70, size: 20)
                      : (s.accentId == a.id
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 20)
                          : null),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 64,
                  child: Text(a.name,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: Lapidary.body(10,
                          color: Lapidary.parchment
                              .withValues(alpha: 0.85))),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // --- custom creator -------------------------------------------------------------------
  Widget _customCreator(BuildContext context, SettingsStore s) {
    if (!s.proUnlocked) {
      return ParchmentPanel(
        child: Column(
          children: [
            Text('Carve your own stone — a PRO craft.',
                style: Lapidary.body(14), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            BronzeTablet(
                label: 'UNLOCK PRO', fontSize: 14, onTap: onOpenPro),
          ],
        ),
      );
    }
    const labels = ['Sandstone', 'Bronze', 'Bone', 'Accent'];
    return ParchmentPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var k = 0; k < 4; k++) ...[
            Text(labels[k],
                style: Lapidary.letterpress(12,
                    weight: FontWeight.bold)),
            const SizedBox(height: 6),
            _swatchRow(s, k),
            if (k < 3) const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          BronzeTablet(
            label: s.themeId == 'custom'
                ? 'CARVING ACTIVE ✓'
                : 'CARVE THIS STONE',
            fontSize: 14,
            selected: s.themeId == 'custom',
            onTap: () {
              s.setTheme('custom');
              Sound.I.click();
            },
          ),
        ],
      ),
    );
  }

  Widget _swatchRow(SettingsStore s, int slot) {
    const swatches = [
      0xFFC2A87D, 0xFFD9B77C, 0xFFB49B6E, 0xFF6E6258, 0xFFD8D2C4, 0xFF9A7A52,
      0xFFC89A72, 0xFF4A4450, 0xFFB8724E, 0xFF6E8A72, 0xFF8E8A82, 0xFFD4B98E,
      0xFF8C6239, 0xFF4A7C6D, 0xFF2E4A8A, 0xFF9A3A2A, 0xFFB8862A, 0xFFD0C5B7,
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final hex in swatches)
          GestureDetector(
            onTap: () {
              final next = List<int>.from(s.customColors);
              next[slot] = hex;
              s.setCustomColors(next);
              Sound.I.click();
            },
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(hex),
                border: Border.all(
                  color: s.customColors[slot] == hex
                      ? Lapidary.verdigris
                      : Colors.black.withValues(alpha: 0.35),
                  width: s.customColors[slot] == hex ? 3 : 1.2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // --- shared ---------------------------------------------------------------------------
  Widget _choiceRow(
    BuildContext context,
    SettingsStore s, {
    required String title,
    required String blurb,
    required bool proOnly,
    required bool selected,
    required Widget preview,
    required VoidCallback onTap,
  }) {
    final unlocked = s.choiceUnlocked(proOnly: proOnly);
    return GestureDetector(
      onTap: () {
        if (!unlocked) {
          onOpenPro();
          return;
        }
        onTap();
        Sound.I.click();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Lapidary.parchment.withValues(alpha: selected ? 1.0 : 0.85),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? Lapidary.verdigris
                : Lapidary.sepiaInk.withValues(alpha: 0.25),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Opacity(opacity: unlocked ? 1.0 : 0.45, child: preview),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Lapidary.letterpress(14,
                          weight: FontWeight.bold)),
                  Text(blurb, style: Lapidary.body(11)),
                ],
              ),
            ),
            if (!unlocked)
              const Icon(Icons.lock_outline,
                  color: Lapidary.sepiaInk, size: 20)
            else if (selected)
              const Icon(Icons.check_circle,
                  color: Lapidary.verdigris, size: 22),
          ],
        ),
      ),
    );
  }
}

/// Tiny live preview of a piece style: one bronze token drawn the style's way.
class _StylePreviewPainter extends CustomPainter {
  final PieceStyle style;
  final MorrisTheme theme;
  _StylePreviewPainter(this.style, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 2;
    if (style.square) {
      final rect = Rect.fromCircle(center: c, radius: r);
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(6)),
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.4, -0.5),
              radius: 1.2,
              colors: [theme.bronzeLight, theme.bronze, theme.bronzeDark],
            ).createShader(rect));
    } else if (style.hex) {
      final path = Path();
      for (var k = 0; k < 6; k++) {
        final a = k * 3.14159 / 3 - 3.14159 / 6;
        final p = c + Offset(cos(a) * r, sin(a) * r);
        if (k == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(
          path,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.4, -0.5),
              radius: 1.2,
              colors: [theme.bronzeLight, theme.bronze, theme.bronzeDark],
            ).createShader(Rect.fromCircle(center: c, radius: r)));
    } else {
      canvas.drawCircle(
          c,
          r,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.4, -0.5),
              radius: 1.2,
              colors: [theme.bronzeLight, theme.bronze, theme.bronzeDark],
            ).createShader(Rect.fromCircle(center: c, radius: r)));
    }
    // Engraving.
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = theme.bronzeDark.withValues(alpha: 0.8);
    if (style.spiral) {
      final path = Path();
      for (var a = 0.0; a < 12.5; a += 0.15) {
        final rr = r * 0.12 + (a / 12.5) * r * 0.62;
        final p = c + Offset(cos(a) * rr, sin(a) * rr);
        if (a == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, ringPaint);
    } else {
      for (var k = 1; k <= style.ringCount; k++) {
        canvas.drawCircle(
            c, r * (0.28 + 0.2 * k), ringPaint);
      }
    }
    if (style.bossScale > 0) {
      canvas.drawCircle(
          c, r * 0.20 * style.bossScale, Paint()..color = theme.bronzeLight);
    }
    if (style.patina > 0.7) {
      canvas.drawCircle(
          c + Offset(-r * 0.3, -r * 0.25),
          r * 0.18,
          Paint()..color = theme.verdigris.withValues(alpha: 0.7));
    }
  }

  @override
  bool shouldRepaint(covariant _StylePreviewPainter old) => true;
}
