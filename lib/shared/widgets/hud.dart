import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

/// Colours of the HUD (dark) look that have no light-theme counterpart.
class Hud {
  Hud._();

  static const Color bg = Color(0xFF041418);
  static const Color bgRaised = Color(0xFF06191E);
  static const Color panelTop = Color(0xFF0F3D45);
  static const Color panelBottom = Color(0xFF08242A);
  static const Color line = Color(0xFF1AA3B8);
  static const Color cyan = Color(0xFF3FF0FF);
  static const Color amber = Color(0xFFFFB347);
  static const Color text = Color(0xFFEAFCFF);
  static const Color muted = Color(0xFF8FD3DE);

  /// Outline of a panel: cut top-left and bottom-right corners, or, with
  /// [tabWidth], a raised label tab on the top-left and cut bottom corners.
  static Path panelPath(Size s, {double cut = 14, double? tabWidth}) {
    final w = s.width, h = s.height;
    final c = math.min(cut, math.min(w, h) / 2);
    if (tabWidth != null && tabWidth + 18 < w) {
      return Path()
        ..moveTo(0, 0)
        ..lineTo(tabWidth, 0)
        ..lineTo(tabWidth + 18, 18)
        ..lineTo(w, 18)
        ..lineTo(w, h - c)
        ..lineTo(w - c, h)
        ..lineTo(c, h)
        ..lineTo(0, h - c)
        ..close();
    }
    return Path()
      ..moveTo(c, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h - c)
      ..lineTo(w - c, h)
      ..lineTo(0, h)
      ..lineTo(0, c)
      ..close();
  }
}

/// A cut-corner panel with a thin outline and bright edge bars.
class HudFrame extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double cut;

  /// Width of the raised label tab; null for the plain cut-corner shape.
  final double? tabWidth;

  /// Outline colour; brighter when the panel is selected.
  final Color? lineColor;

  /// Solid fill instead of the panel gradient (filled buttons).
  final Color? fill;

  /// Bright bars on the top and bottom edges. Off for small chips.
  final bool bars;

  const HudFrame({
    super.key,
    required this.child,
    this.padding,
    this.cut = 14,
    this.tabWidth,
    this.lineColor,
    this.fill,
    this.bars = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FramePainter(
        cut: cut,
        tabWidth: tabWidth,
        line: lineColor ?? Hud.line,
        fill: fill,
        bars: bars,
      ),
      child: ClipPath(
        clipper: _FrameClipper(cut: cut, tabWidth: tabWidth),
        child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
      ),
    );
  }
}

class _FrameClipper extends CustomClipper<Path> {
  final double cut;
  final double? tabWidth;
  const _FrameClipper({required this.cut, this.tabWidth});

  @override
  Path getClip(Size size) => Hud.panelPath(size, cut: cut, tabWidth: tabWidth);

  @override
  bool shouldReclip(_FrameClipper old) =>
      old.cut != cut || old.tabWidth != tabWidth;
}

class _FramePainter extends CustomPainter {
  final double cut;
  final double? tabWidth;
  final Color line;
  final Color? fill;
  final bool bars;

  const _FramePainter({
    required this.cut,
    required this.tabWidth,
    required this.line,
    required this.fill,
    required this.bars,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Hud.panelPath(size, cut: cut, tabWidth: tabWidth);
    final rect = Offset.zero & size;
    final fillPaint = Paint();
    if (fill != null) {
      fillPaint.color = fill!;
    } else {
      fillPaint.shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Hud.panelTop, Hud.panelBottom],
      ).createShader(rect);
    }
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = line,
    );
    if (!bars || size.width < 200 || size.height < 60) return;
    final bar = Paint()..color = Hud.cyan;
    final len = math.min(90.0, size.width * 0.25);
    if (tabWidth == null) {
      canvas.drawRect(Rect.fromLTWH(40, 0, len, 3.5), bar);
    }
    canvas.drawRect(
      Rect.fromLTWH(
          size.width - 40 - len * 0.66, size.height - 3.5, len * 0.66, 3.5),
      bar,
    );
  }

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.cut != cut ||
      old.tabWidth != tabWidth ||
      old.line != line ||
      old.fill != fill ||
      old.bars != bars;
}

/// The faint dot grid behind every HUD screen.
class HudBackdrop extends StatelessWidget {
  final Widget child;
  const HudBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Hud.bg,
      child: CustomPaint(painter: const _DotGridPainter(), child: child),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Hud.cyan.withValues(alpha: 0.13);
    const step = 22.0;
    final points = <Offset>[
      for (var y = step / 2; y < size.height; y += step)
        for (var x = step / 2; x < size.width; x += step) Offset(x, y),
    ];
    canvas.drawPoints(
      PointMode.points,
      points,
      paint
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => false;
}

/// A bar of [count] blocks, [value] (0..1) of them lit, revealed left to
/// right as [reveal] goes 0..1.
class HudSegments extends StatelessWidget {
  final double value;
  final Color color;
  final int count;
  final double reveal;
  final double height;

  const HudSegments({
    super.key,
    required this.value,
    required this.color,
    this.count = 10,
    this.reveal = 1,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    final lit = (value.clamp(0.0, 1.0) * count).round();
    final shown = (reveal.clamp(0.0, 1.0) * count).ceil();
    return Row(
      children: [
        for (var i = 0; i < count; i++)
          Expanded(
            child: Container(
              height: height,
              margin: EdgeInsets.only(right: i == count - 1 ? 0 : 2),
              color: i < lit && i < shown
                  ? color
                  : Hud.cyan.withValues(alpha: 0.15),
            ),
          ),
      ],
    );
  }
}
