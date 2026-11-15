import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One circle in the backdrop. Positions and radius are fractions of the
/// screen width so the shapes scale with any screen. Centers sit on or past
/// the screen edge, so only a curved slice of each circle shows.
class _Blob {
  const _Blob({
    required this.dx,
    required this.dy,
    required this.radius,
    required this.color,
    required this.delay,
    required this.driftPhase,
  });

  final double dx; // center x, as a fraction of width
  final double dy; // center y, as a fraction of width (not height)
  final double radius; // as a fraction of width
  final Color color;
  final double delay; // 0 to 1, when this blob starts within the reveal
  final double driftPhase;
}

/// Circles cut off by the top corners of the screen, each a different tone of
/// black. They draw in as crisp shapes, blow up and soften, and blend into the
/// white page like a reflection. After that they drift very slowly.
///
/// Softness comes from radial gradients rather than a real blur: it looks the
/// same and costs far less to draw every frame.
class OnboardingBackdrop extends StatelessWidget {
  const OnboardingBackdrop({
    super.key,
    required this.reveal,
    required this.drift,
  });

  /// 0 to 1: draw in, blow up, blend.
  final Animation<double> reveal;

  /// 0 to 1, looping: the slow idle movement.
  final Animation<double> drift;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _BackdropPainter(reveal: reveal, drift: drift),
        ),
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter({required this.reveal, required this.drift})
    : super(repaint: Listenable.merge([reveal, drift]));

  final Animation<double> reveal;
  final Animation<double> drift;

  // Different tones of black, darkest at the corner.
  static const _blobs = [
    _Blob(
      dx: -0.04,
      dy: 0.02,
      radius: 0.46,
      color: Color(0xFF050506),
      delay: 0.0,
      driftPhase: 0.0,
    ),
    _Blob(
      dx: 1.06,
      dy: 0.10,
      radius: 0.40,
      color: Color(0xFF1C1C1E),
      delay: 0.12,
      driftPhase: 2.1,
    ),
    _Blob(
      dx: 0.02,
      dy: 0.46,
      radius: 0.26,
      color: Color(0xFF3A3A3C),
      delay: 0.26,
      driftPhase: 4.0,
    ),
    _Blob(
      dx: 0.96,
      dy: -0.06,
      radius: 0.30,
      color: Color(0xFF2C2C2E),
      delay: 0.20,
      driftPhase: 5.3,
    ),
  ];

  static double _span(double t, double from, double to) =>
      ((t - from) / (to - from)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final t = reveal.value;
    final wobble = drift.value * math.pi * 2;

    for (final blob in _blobs) {
      // Each blob runs its own 0 to 1 timeline inside the reveal.
      final p = _span(t, blob.delay, blob.delay + 0.7);
      if (p <= 0) continue;

      // Always soft: the shapes never show a hard edge. They fade in while
      // swelling outward, so they read as a glow spreading from the corners.
      final appear = Curves.easeOut.transform(_span(p, 0.0, 0.7));
      final swell = Curves.easeOutCubic.transform(p);
      final radius = blob.radius * w * (0.7 + 0.6 * swell);

      final center = Offset(
        blob.dx * w + math.sin(wobble + blob.driftPhase) * w * 0.012,
        blob.dy * w + math.cos(wobble * 1.0 + blob.driftPhase) * w * 0.012,
      );

      final color = blob.color.withValues(alpha: appear * 0.82);
      final gradient = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
        stops: const [0.0, 1.0],
        // A gentle curve so the falloff is smooth rather than a straight cone.
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = gradient.createShader(
            Rect.fromCircle(center: center, radius: radius),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter old) =>
      old.reveal != reveal || old.drift != drift;
}
