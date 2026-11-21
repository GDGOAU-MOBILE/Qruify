import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart' show QrImage;

import '../splash/splash_screen.dart';
import 'onboarding_backdrop.dart';

/// First screen a new user sees, right after the splash.
///
/// It starts on exactly the frame the splash ends on (the finished QR code),
/// so the hand off is invisible. Then the code lifts straight up, the text
/// fades in underneath, and last a black pill button appears.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onContinue, this.qr});

  final VoidCallback onContinue;

  /// The code to show. Defaults to the splash's code.
  final QrImage? qr;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  // The corner circles: draw in, blow up and blend (once), then drift (loop).
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );
  late final QrImage _qr = widget.qr ?? SplashField.qrFor();
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      _reveal.value = 1;
    } else {
      _reveal.forward();
      _drift.repeat();
      // A beat of stillness so the QR is seen before it moves.
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _reveal.dispose();
    _drift.dispose();
    super.dispose();
  }

  static double _span(double t, double from, double to) =>
      ((t - from) / (to - from)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final layout = SplashField.qrLayout(size, _qr.moduleCount);
          final side = layout.cell * _qr.moduleCount;
          final lift = size.height * 0.10;
          final bottomInset = MediaQuery.paddingOf(context).bottom;

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              final tilt = Curves.easeInOutCubic.transform(_span(t, 0, 0.5));
              final text = Curves.easeOut.transform(_span(t, 0.4, 0.8));
              final button = Curves.easeOut.transform(_span(t, 0.6, 1.0));

              // The code stays straight; it only lifts to make room for the text.
              final matrix = Matrix4.translationValues(0, -lift * tilt, 0);

              return Stack(
                children: [
                  Positioned.fill(
                    child: OnboardingBackdrop(reveal: _reveal, drift: _drift),
                  ),
                  Positioned(
                    left: layout.origin.dx,
                    top: layout.origin.dy,
                    width: side,
                    height: side,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: matrix,
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: _QrPainter(_qr, layout.cell),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 32,
                    right: 32,
                    top: layout.origin.dy - lift + side + 56,
                    child: Opacity(
                      opacity: text,
                      child: Transform.translate(
                        offset: Offset(0, 14 * (1 - text)),
                        child: Column(
                          children: [
                            Text(
                              'Make a QR code\nin seconds.',
                              textAlign: TextAlign.center,
                              style: style.headlineMedium?.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.8,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Links, text, Wi-Fi and more. No account, no internet. Everything stays on your phone.',
                              textAlign: TextAlign.center,
                              style: style.bodyLarge?.copyWith(
                                color: const Color(0xFF6E6E73),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: bottomInset + 24,
                    child: Opacity(
                      opacity: button,
                      child: Transform.translate(
                        offset: Offset(0, 14 * (1 - button)),
                        child: IgnorePointer(
                          ignoring: button < 1,
                          child: SizedBox(
                            height: 58,
                            child: FilledButton(
                              onPressed: widget.onContinue,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                shape: const StadiumBorder(),
                                textStyle: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text('Continue'),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// The finished QR code, drawn module by module on whole pixels so it matches
/// the last frame of the splash.
class _QrPainter extends CustomPainter {
  _QrPainter(this.qr, this.cell);

  final QrImage qr;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..isAntiAlias = false
      ..color = Colors.black;
    for (var r = 0; r < qr.moduleCount; r++) {
      for (var c = 0; c < qr.moduleCount; c++) {
        if (qr.isDark(r, c)) {
          canvas.drawRect(Rect.fromLTWH(c * cell, r * cell, cell, cell), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter old) => old.qr != qr || old.cell != cell;
}
