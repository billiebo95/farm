import 'package:flutter/material.dart';

/// Small stroke-style icons matching the inline SVGs in the prototype.
/// Kept as CustomPainters (no icon font / asset dependency) so the app
/// doesn't need a bundled icon set for a handful of glyphs.
class AppIcon extends StatelessWidget {
  const AppIcon.grid({super.key, this.size = 22, this.color = Colors.black}) : _kind = _Kind.grid;
  const AppIcon.cart({super.key, this.size = 22, this.color = Colors.black}) : _kind = _Kind.cart;
  const AppIcon.orders({super.key, this.size = 22, this.color = Colors.black}) : _kind = _Kind.orders;
  const AppIcon.person({super.key, this.size = 22, this.color = Colors.black}) : _kind = _Kind.person;
  const AppIcon.search({super.key, this.size = 17, this.color = Colors.black}) : _kind = _Kind.search;
  const AppIcon.scan({super.key, this.size = 20, this.color = Colors.black}) : _kind = _Kind.scan;
  const AppIcon.trash({super.key, this.size = 15, this.color = Colors.black}) : _kind = _Kind.trash;
  const AppIcon.back({super.key, this.size = 18, this.color = Colors.black}) : _kind = _Kind.back;
  const AppIcon.check({super.key, this.size = 36, this.color = Colors.black}) : _kind = _Kind.check;

  final double size;
  final Color color;
  final _Kind _kind;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _IconPainter(_kind, color));
  }
}

enum _Kind { grid, cart, orders, person, search, scan, trash, back, check }

class _IconPainter extends CustomPainter {
  _IconPainter(this.kind, this.color);
  final _Kind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = w * 0.1;
    final fill = Paint()..color = color;

    switch (kind) {
      case _Kind.grid:
        stroke.strokeWidth = w * 0.09;
        final cell = w * 0.34, gap = w * 0.12, r = Radius.circular(w * 0.09);
        for (final dx in [0.0, cell + gap]) {
          for (final dy in [0.0, cell + gap]) {
            canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(dx, dy, cell, cell), r), stroke);
          }
        }
      case _Kind.cart:
        stroke.strokeWidth = w * 0.09;
        final path = Path()
          ..moveTo(w * 0.18, h * 0.22)
          ..lineTo(w * 0.32, h * 0.22)
          ..lineTo(w * 0.42, h * 0.68)
          ..lineTo(w * 0.85, h * 0.68)
          ..lineTo(w * 0.95, h * 0.35)
          ..lineTo(w * 0.32, h * 0.35);
        canvas.drawPath(path, stroke);
        canvas.drawCircle(Offset(w * 0.45, h * 0.88), w * 0.07, fill);
        canvas.drawCircle(Offset(w * 0.8, h * 0.88), w * 0.07, fill);
      case _Kind.orders:
        stroke.strokeWidth = w * 0.09;
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.17, h * 0.12, w * 0.66, h * 0.78), Radius.circular(w * 0.13)),
          stroke,
        );
        for (final f in [0.4, 0.58, 0.76]) {
          final lineW = f == 0.76 ? w * 0.32 : w * 0.4;
          canvas.drawLine(Offset(w * 0.32, h * f), Offset(w * 0.32 + lineW, h * f), stroke);
        }
      case _Kind.person:
        stroke.strokeWidth = w * 0.09;
        canvas.drawCircle(Offset(w * 0.5, h * 0.36), w * 0.17, stroke);
        final path = Path()
          ..moveTo(w * 0.18, h * 0.87)
          ..quadraticBezierTo(w * 0.5, h * 0.6, w * 0.82, h * 0.87);
        canvas.drawPath(path, stroke);
      case _Kind.search:
        stroke.strokeWidth = w * 0.13;
        canvas.drawCircle(Offset(w * 0.42, h * 0.42), w * 0.32, stroke);
        canvas.drawLine(Offset(w * 0.68, h * 0.68), Offset(w * 0.95, h * 0.95), stroke);
      case _Kind.scan:
        stroke.strokeWidth = w * 0.1;
        final corner = w * 0.22;
        void bracket(double x, double y, double dx, double dy) {
          canvas.drawPath(
            Path()
              ..moveTo(x, y + dy * corner)
              ..lineTo(x, y)
              ..lineTo(x + dx * corner, y),
            stroke,
          );
        }
        bracket(w * 0.05, h * 0.05, 1, 1);
        bracket(w * 0.95, h * 0.05, -1, 1);
        bracket(w * 0.05, h * 0.95, 1, -1);
        bracket(w * 0.95, h * 0.95, -1, -1);
        canvas.drawLine(Offset(w * 0.33, h * 0.5), Offset(w * 0.67, h * 0.5), stroke);
      case _Kind.trash:
        stroke.strokeWidth = w * 0.13;
        canvas.drawLine(Offset(w * 0.15, h * 0.28), Offset(w * 0.85, h * 0.28), stroke);
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.32, h * 0.28)
            ..lineTo(w * 0.32, h * 0.12)
            ..lineTo(w * 0.68, h * 0.12)
            ..lineTo(w * 0.68, h * 0.28),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.24, h * 0.28)
            ..lineTo(w * 0.3, h * 0.95)
            ..lineTo(w * 0.7, h * 0.95)
            ..lineTo(w * 0.76, h * 0.28),
          stroke,
        );
      case _Kind.back:
        stroke.strokeWidth = w * 0.16;
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.62, h * 0.12)
            ..lineTo(w * 0.3, h * 0.5)
            ..lineTo(w * 0.62, h * 0.88),
          stroke,
        );
      case _Kind.check:
        stroke.strokeWidth = w * 0.11;
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.17, h * 0.55)
            ..lineTo(w * 0.4, h * 0.78)
            ..lineTo(w * 0.85, h * 0.28),
          stroke,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _IconPainter oldDelegate) => oldDelegate.color != color || oldDelegate.kind != kind;
}
