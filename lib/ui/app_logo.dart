import 'package:flutter/material.dart';

import 'theme.dart';

/// The app icon: a document with a highlighted line and an AI sparkle.
/// Drawn in code so the in-app logo and the .ico are the same artwork.
class AppLogoPainter extends CustomPainter {
  const AppLogoPainter({this.rounded = true});

  /// false draws the artwork edge to edge (for icon files that get their own mask).
  final bool rounded;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    Offset p(double x, double y) => Offset(x * s, y * s);
    Rect r(double l, double t, double w, double h) => Rect.fromLTWH(l * s, t * s, w * s, h * s);
    RRect rr(Rect rect, double radius) => RRect.fromRectAndRadius(rect, Radius.circular(radius * s));

    // Background tile.
    final tile = rr(r(0, 0, 1, 1), rounded ? 0.23 : 0);
    canvas.drawRRect(
      tile,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF9B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Offset.zero & size),
    );
    canvas.save();
    canvas.clipRRect(tile);
    canvas.drawCircle(
      p(0.2, 0.05),
      0.55 * s,
      Paint()..shader = RadialGradient(colors: [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: p(0.2, 0.05), radius: 0.55 * s)),
    );
    canvas.restore();

    // Document sheet with a folded corner.
    const fold = 0.15;
    const left = 0.24, top = 0.15, width = 0.50, height = 0.68;
    final sheet = Path()
      ..moveTo((left + 0.05) * s, top * s)
      ..lineTo((left + width - fold) * s, top * s)
      ..lineTo((left + width) * s, (top + fold) * s)
      ..lineTo((left + width) * s, (top + height - 0.05) * s)
      ..quadraticBezierTo((left + width) * s, (top + height) * s, (left + width - 0.05) * s, (top + height) * s)
      ..lineTo((left + 0.05) * s, (top + height) * s)
      ..quadraticBezierTo(left * s, (top + height) * s, left * s, (top + height - 0.05) * s)
      ..lineTo(left * s, (top + 0.05) * s)
      ..quadraticBezierTo(left * s, top * s, (left + 0.05) * s, top * s)
      ..close();
    canvas.drawShadow(sheet, const Color(0xFF1E1B4B), 0.025 * s, true);
    canvas.drawPath(sheet, Paint()..color = Colors.white);

    final foldPath = Path()
      ..moveTo((left + width - fold) * s, top * s)
      ..lineTo((left + width) * s, (top + fold) * s)
      ..lineTo((left + width - fold) * s, (top + fold) * s)
      ..close();
    canvas.drawPath(foldPath, Paint()..color = const Color(0xFFD9D6FF));

    // Text lines; the second one sits on a highlighter stripe.
    final line = Paint()..color = const Color(0xFFB7B9D6);
    canvas.drawRRect(rr(r(0.32, 0.31, 0.26, 0.036), 0.018), line);
    canvas.drawRRect(rr(r(0.30, 0.425, 0.40, 0.085), 0.02), Paint()..color = const Color(0xFFFFE066));
    canvas.drawRRect(rr(r(0.32, 0.4475, 0.34, 0.036), 0.018), Paint()..color = const Color(0xFF4A4670));
    canvas.drawRRect(rr(r(0.32, 0.565, 0.36, 0.036), 0.018), line);
    canvas.drawRRect(rr(r(0.32, 0.655, 0.20, 0.036), 0.018), line);

    // AI sparkle overlapping the lower-right corner.
    final c = p(0.72, 0.74);
    final star = _sparkle(c, 0.16 * s);
    canvas.drawPath(star, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 0.035 * s..strokeJoin = StrokeJoin.round);
    canvas.drawPath(
      star,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFFFFF08A), Color(0xFFFFC53D)], begin: Alignment.topLeft, end: Alignment.bottomRight)
            .createShader(Rect.fromCircle(center: c, radius: 0.16 * s)),
    );
    // Small companion sparkle.
    final small = _sparkle(p(0.86, 0.57), 0.055 * s);
    canvas.drawPath(small, Paint()..color = Colors.white.withValues(alpha: 0.95));
  }

  /// Four-pointed star with concave sides.
  Path _sparkle(Offset c, double r) {
    final k = r * 0.22; // pinch
    return Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + k, c.dy - k, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + k, c.dy + k, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - k, c.dy + k, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - k, c.dy - k, c.dx, c.dy - r)
      ..close();
  }

  @override
  bool shouldRepaint(covariant AppLogoPainter old) => old.rounded != rounded;
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 40, this.glow = false});
  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final logo = SizedBox(width: size, height: size, child: CustomPaint(painter: const AppLogoPainter()));
    if (!glow) return logo;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.23),
        boxShadow: [BoxShadow(color: context.brand.gradientStart.withValues(alpha: 0.45), blurRadius: size * 0.5, offset: Offset(0, size * 0.18))],
      ),
      child: logo,
    );
  }
}
