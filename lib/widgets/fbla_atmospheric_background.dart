import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fbla_member_app/theme/fbla_colors.dart';

class FblaAtmosphericBackground extends StatelessWidget {
  const FblaAtmosphericBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF021a33),
                FblaColors.navyDark,
                Color(0xFF0c3566),
                Color(0xFF143d7a),
              ],
              stops: [0.0, 0.35, 0.65, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.85, -0.55),
              radius: 1.1,
              colors: [
                FblaColors.gold.withOpacity(0.22),
                FblaColors.crimson.withOpacity(0.08),
                Colors.transparent,
              ],
              stops: const [0.0, 0.35, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.9, 0.75),
              radius: 1.15,
              colors: [
                const Color(0xFF2563eb).withOpacity(0.28),
                Colors.transparent,
              ],
            ),
          ),
        ),
        CustomPaint(
          painter: _MeshPainter(),
          child: const SizedBox.expand(),
        ),
        CustomPaint(
          painter: _RibbonPainter(),
          child: const SizedBox.expand(),
        ),
      ],
    );
  }
}

class _MeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withOpacity(0.045);

    const step = 48.0;
    for (var x = 0.0; x < size.width + step; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height * 0.35, size.height),
        line,
      );
    }
    for (var y = 0.0; y < size.height + step; y += step) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y - size.width * 0.12),
        line,
      );
    }

    final dot = Paint()..color = Colors.white.withOpacity(0.06);
    final rnd = math.Random(42);
    for (var i = 0; i < 80; i++) {
      final ox = rnd.nextDouble() * size.width;
      final oy = rnd.nextDouble() * size.height;
      canvas.drawCircle(Offset(ox, oy), rnd.nextDouble() * 1.8 + 0.4, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RibbonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.65, -20)
      ..quadraticBezierTo(
        size.width * 0.95,
        size.height * 0.35,
        size.width * 0.55,
        size.height * 0.55,
      )
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.72,
        -40,
        size.height * 0.88,
      );

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = FblaColors.gold.withOpacity(0.15)
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, stroke);

    final path2 = Path()
      ..moveTo(size.width * 1.05, size.height * 0.15)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.42,
        size.width * 0.2,
        size.height * 1.05,
      );
    canvas.drawPath(
      path2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withOpacity(0.07)
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
