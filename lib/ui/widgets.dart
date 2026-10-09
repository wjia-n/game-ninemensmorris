/// Carved-stone UI widgets: bronze tablets, icon reliefs, parchment panels,
/// stone toggles, carved sliders, chiseled cartouches, vault background.
/// Icon-only where the design calls for it; min touch target 56px.
library;

import 'package:flutter/material.dart';

import '../audio/sound.dart';
import 'lapidary.dart';

/// Warm basalt vault canvas with museum spotlight and vignette.
class VaultBackground extends StatelessWidget {
  final Widget child;
  const VaultBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.35, -0.55),
          radius: 1.35,
          colors: [
            Color(0xFF54432E), // warm spotlight pool
            Lapidary.basalt,
            Lapidary.basaltDeep,
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: child,
    );
  }
}

/// Chiseled title cartouche: sandstone slab with engraved inscription text.
class Cartouche extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double fontSize;
  const Cartouche(
      {super.key, required this.title, this.subtitle, this.fontSize = 30});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CartouchePainter(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                textAlign: TextAlign.center,
                style: Lapidary.chiseled(fontSize)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: Lapidary.chiseled(12, spacing: 4)),
            ],
          ],
        ),
      ),
    );
  }
}

class _CartouchePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
        Offset.zero & size, const Radius.circular(12));
    // Drop shadow.
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            (Offset.zero & size).shift(const Offset(0, 8)),
            const Radius.circular(12)),
        Paint()..color = Colors.black.withValues(alpha: 0.4));
    Lapidary.paintSlab(canvas, rect, base: Lapidary.sandstone);
    // Engraved inner border.
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            (Offset.zero & size).deflate(10), const Radius.circular(8)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Lapidary.chiselShadow.withValues(alpha: 0.55));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            (Offset.zero & size).deflate(13), const Radius.circular(7)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Lapidary.sandstoneLight.withValues(alpha: 0.7));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Aged bronze tablet button with embossed lettering.
/// Pressed state sinks with an inner shadow.
class BronzeTablet extends StatefulWidget {
  final String label;
  final String? sublabel;
  final VoidCallback? onTap;
  final double fontSize;
  final bool selected; // e.g. active difficulty tablet
  const BronzeTablet({
    super.key,
    required this.label,
    this.sublabel,
    this.onTap,
    this.fontSize = 18,
    this.selected = false,
  });

  @override
  State<BronzeTablet> createState() => _BronzeTabletState();
}

class _BronzeTabletState extends State<BronzeTablet> {
  bool _pressed = false;

  void _down(TapDownDetails _) => setState(() => _pressed = true);
  void _up() {
    if (!_pressed) return;
    setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final down = _pressed || widget.selected;
    return GestureDetector(
      onTapDown: _down,
      onTapUp: (_) {
        _up();
        Sound.I.click();
        widget.onTap?.call();
      },
      onTapCancel: _up,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: down
                ? [Lapidary.bronzeDark, Lapidary.bronze]
                : [Lapidary.bronzeLight, Lapidary.bronze, Lapidary.bronzeDark],
            stops: down ? const [0.0, 1.0] : const [0.0, 0.55, 1.0],
          ),
          border: Border.all(
              color: down ? Lapidary.umber : Lapidary.sandstoneDeep, width: 2),
          boxShadow: down
              ? [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.55),
                      blurRadius: 4,
                      offset: const Offset(0, 1))
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 5)),
                  BoxShadow(
                      color: Colors.white.withValues(alpha: 0.14),
                      blurRadius: 1,
                      offset: const Offset(0, -1)),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.label,
                textAlign: TextAlign.center,
                style: Lapidary.embossed(widget.fontSize)),
            if (widget.sublabel != null)
              Text(widget.sublabel!,
                  textAlign: TextAlign.center,
                  style: Lapidary.embossed(11, spacing: 1.5)),
          ],
        ),
      ),
    );
  }
}

/// Icon-only sandstone relief button (toolbar). Carved glyph, no text.
class ReliefIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;
  final bool disabled;
  const ReliefIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.disabled = false,
  });

  @override
  State<ReliefIconButton> createState() => _ReliefIconButtonState();
}

class _ReliefIconButtonState extends State<ReliefIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          if (!widget.disabled) {
            Sound.I.click();
            widget.onTap?.call();
          }
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _pressed
                  ? [Lapidary.sandstoneDeep, Lapidary.sandstone]
                  : [Lapidary.sandstoneLight, Lapidary.sandstone],
            ),
            border:
                Border.all(color: Lapidary.bronzeDark.withValues(alpha: 0.8)),
            boxShadow: _pressed
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        offset: const Offset(0, 1),
                        blurRadius: 2)
                  ]
                : [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        offset: const Offset(0, 4),
                        blurRadius: 8),
                  ],
          ),
          child: Icon(widget.icon,
              size: 26,
              color: widget.disabled
                  ? Lapidary.sandstoneDeep.withValues(alpha: 0.5)
                  : Lapidary.umber,
              shadows: const [
                Shadow(
                    offset: Offset(0, -1),
                    color: Color(0xAAFFFFFF),
                    blurRadius: 0),
              ]),
        ),
      ),
    );
  }
}

/// Parchment panel with letterpressed content.
class ParchmentPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const ParchmentPanel(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ParchmentPainter(),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _ParchmentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Lapidary.paintParchment(canvas,
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Stone toggle switch with a bronze lever.
class StoneToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const StoneToggle(
      {super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Sound.I.click();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 76,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: value
                ? [Lapidary.bronzeDark, Lapidary.bronze]
                : [Lapidary.umber, Lapidary.basalt],
          ),
          border: Border.all(color: Lapidary.sandstoneDeep, width: 2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                offset: const Offset(0, 3),
                blurRadius: 5),
            const BoxShadow(
                color: Color(0x33FFFFFF),
                offset: Offset(0, -1),
                blurRadius: 1),
          ],
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              alignment:
                  value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Lapidary.bronzeLight, Lapidary.bronzeDark],
                  ),
                  border: Border.all(color: Lapidary.umber, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        offset: const Offset(0, 2),
                        blurRadius: 3),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: value
                          ? Lapidary.verdigris
                          : Lapidary.sandstoneDeep,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            offset: const Offset(0, 1),
                            blurRadius: 1),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Slider with a track carved into stone and a bronze knob.
class CarvedSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const CarvedSlider(
      {super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      return GestureDetector(
        onHorizontalDragUpdate: (d) =>
            onChanged(((d.localPosition.dx / w).clamp(0.0, 1.0))),
        onTapDown: (d) =>
            onChanged(((d.localPosition.dx / w).clamp(0.0, 1.0))),
        child: SizedBox(
          height: 40,
          child: CustomPaint(
            painter: _CarvedSliderPainter(value),
            size: Size(w, 40),
          ),
        ),
      );
    });
  }
}

class _CarvedSliderPainter extends CustomPainter {
  final double value;
  _CarvedSliderPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final trackY = size.height / 2;
    final trackRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(4, trackY - 7, size.width - 8, 14),
        const Radius.circular(7));
    // Carved groove: dark cut with lit lower lip.
    canvas.drawRRect(trackRect, Paint()..color = Lapidary.chiselShadow);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(6, trackY + 4, size.width - 12, 2),
            const Radius.circular(1)),
        Paint()..color = Lapidary.sandstoneLight.withValues(alpha: 0.6));
    // Bronze knob.
    final kx = 4 + value * (size.width - 8);
    final knobR = 15.0;
    canvas.drawCircle(Offset(kx + 2, trackY + 4), knobR,
        Paint()..color = Colors.black.withValues(alpha: 0.45));
    final knob = Rect.fromCircle(
        center: Offset(kx, trackY), radius: knobR);
    canvas.drawCircle(
        Offset(kx, trackY),
        knobR,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.4, -0.5),
            radius: 1.1,
            colors: [Lapidary.bronzeLight, Lapidary.bronze, Lapidary.bronzeDark],
          ).createShader(knob));
    canvas.drawCircle(
        Offset(kx, trackY),
        knobR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Lapidary.umber);
    canvas.drawCircle(
        Offset(kx - 4, trackY - 5), 4,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
  }

  @override
  bool shouldRepaint(covariant _CarvedSliderPainter old) =>
      old.value != value;
}

/// Thin engraved divider with a bronze diamond.
class EngravedDivider extends StatelessWidget {
  const EngravedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const Expanded(child: _Line()),
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            transform: Matrix4.rotationZ(0.785),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Lapidary.bronzeLight, Lapidary.bronzeDark],
              ),
              border: Border.all(color: Lapidary.umber, width: 1),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    offset: const Offset(0, 2),
                    blurRadius: 2),
              ],
            ),
          ),
          const Expanded(child: _Line()),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            height: 2, color: Lapidary.chiselShadow.withValues(alpha: 0.6)),
        Container(
            height: 1,
            color: Lapidary.sandstoneLight.withValues(alpha: 0.5)),
      ],
    );
  }
}

/// Carved-bone chip showing a reserve count (small token stack icon).
class ReserveChip extends StatelessWidget {
  final int count;
  final int seat; // 0 bronze, 1 bone
  final String label;
  const ReserveChip(
      {super.key, required this.count, required this.seat, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: Lapidary.letterpress(11, weight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _miniToken(seat),
            const SizedBox(width: 6),
            Text('× $count', style: Lapidary.letterpress(15)),
          ],
        ),
      ],
    );
  }

  Widget _miniToken(int s) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.5),
          radius: 1.1,
          colors: s == 0
              ? [Lapidary.bronzeLight, Lapidary.bronze, Lapidary.bronzeDark]
              : [Lapidary.boneLight, Lapidary.bone, Lapidary.boneDark],
        ),
        border: Border.all(color: Lapidary.umber, width: 1.2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              offset: const Offset(0, 2),
              blurRadius: 2),
        ],
      ),
    );
  }
}
