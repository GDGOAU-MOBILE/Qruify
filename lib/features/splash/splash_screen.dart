import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart'
    show QrCode, QrErrorCorrectLevel, QrImage;

import '../../core/app_fonts.dart';

/// Builds the particles for a given screen size. Tests pass their own.
typedef SplashFieldLoader = Future<SplashField> Function(Size size, QrImage qr);

/// White screen. "Qruify" holds, bursts into particles, and the particles
/// fly back together to form a QR code (the same one as the app icon, which
/// scans as "Qruify"). [onFinished] runs once, after a short pause.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.onFinished,
    this.explode = true,
    this.duration,
    this.fieldLoader = SplashField.prepare,
  });

  /// True for a first launch: the name bursts into particles that form a QR
  /// code. False for returning users: just the name, then straight in.
  final bool explode;

  final VoidCallback onFinished;
  final Duration? duration;
  final SplashFieldLoader fieldLoader;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration:
        widget.duration ?? Duration(milliseconds: widget.explode ? 2800 : 1300),
  );
  late final QrImage _qr = SplashField.qrFor();

  SplashField? _field;
  Size? _requestedSize;
  bool _started = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _finish(Duration(milliseconds: widget.explode ? 100 : 150));
      }
    });
  }

  /// Builds the particles once the screen size is known, then starts.
  void _ensureField(Size size) {
    if (_requestedSize == size) return;
    _requestedSize = size;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        final field = await widget.fieldLoader(size, _qr);
        if (!mounted || _requestedSize != size) return;
        setState(() => _field = field);
        if (_started) return;
        _started = true;
        if (MediaQuery.disableAnimationsOf(context)) {
          // Reduce Motion: show the finished QR code briefly, no animation.
          _controller.value = 1;
          _finish(const Duration(milliseconds: 700));
        } else {
          // The first frames are slow (graphics set up the first time they are
          // used). Let them pass before the clock starts, or the animation
          // would jump past its opening.
          await WidgetsBinding.instance.endOfFrame;
          await WidgetsBinding.instance.endOfFrame;
          if (!mounted) return;
          _controller.forward();
        }
      } catch (_) {
        _finish(Duration.zero); // never trap the user on the splash
      }
    });
  }

  void _finish(Duration pause) {
    if (_finished) return;
    _finished = true;
    Future<void>.delayed(pause, () {
      if (mounted) widget.onFinished();
    });
  }

  /// Returning users: the name fades in and holds. No particles.
  Widget _quickName(Size size) {
    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (MediaQuery.disableAnimationsOf(context)) {
          _controller.value = 1;
          _finish(const Duration(milliseconds: 500));
        } else {
          _controller.forward();
        }
      });
    }
    final probe = SplashField.wordmark(100);
    final text = SplashField.wordmark(100 * (size.width * 0.62) / probe.width);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Center(
        child: Opacity(
          opacity: Curves.easeOut.transform(
            (_controller.value / 0.3).clamp(0.0, 1.0),
          ),
          child: RichText(text: text.text!, textDirection: TextDirection.ltr),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Semantics(
        label: 'Qruify',
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (!widget.explode) return _quickName(constraints.biggest);
            _ensureField(constraints.biggest);
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                size: Size.infinite,
                painter: SplashPainter(
                  progress: _controller.value,
                  field: _field,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Everything the animation needs, worked out once per screen size.
///
/// The wordmark is cut into small squares ("particles"). There are nine
/// particles for every dark module of the QR code, so at the end they tile
/// each module exactly, with no gaps. Positions are stored in flat lists
/// of x, y pairs.
class SplashField {
  SplashField._({
    required this.text,
    required this.textOffset,
    required this.origins,
    required this.scattered,
    required this.targets,
    required this.delays,
    required this.bends,
    required this.startSize,
    required this.endSize,
  });

  /// The crisp wordmark, drawn before the burst.
  final TextPainter text;
  final Offset textOffset;

  /// Where each particle starts (inside a letter), where the burst throws it,
  /// and where it ends up (a slice of a QR module).
  final Float32List origins;
  final Float32List scattered;
  final Float32List targets;

  /// Per particle: 0 to 1 start delay while regrouping, and a sideways bend
  /// from -1 to 1 so the paths swirl instead of running straight.
  final Float32List delays;
  final Float32List bends;

  final double startSize;
  final double endSize;

  int get count => delays.length;

  static QrImage qrFor() => QrImage(
    QrCode.fromData(data: 'Qruify', errorCorrectLevel: QrErrorCorrectLevel.H),
  );

  static TextPainter wordmark(double fontSize) => TextPainter(
    text: TextSpan(
      text: 'Qruify',
      style: TextStyle(
        fontFamily: AppFonts.geist,
        fontSize: fontSize,
        // Geist is a variable font: ask for the weight on its axis.
        fontVariations: const [FontVariation('wght', 700)],
        letterSpacing: -fontSize * 0.04,
        color: Colors.black,
        height: 1.0,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  /// Layout of the final QR code for a screen: whole pixel modules, in
  /// multiples of 3 so each module splits into 3 x 3 whole pixel slices.
  static ({double cell, Offset origin}) qrLayout(Size size, int modules) {
    final cell = math.max(
      6.0,
      ((size.shortestSide * 0.5 / modules) / 3).round() * 3.0,
    );
    final side = cell * modules;
    return (
      cell: cell,
      origin: Offset(
        ((size.width - side) / 2).roundToDouble(),
        ((size.height - side) / 2).roundToDouble(),
      ),
    );
  }

  static Future<SplashField> prepare(Size size, QrImage qr) async {
    final random = math.Random(7);

    // 1. The wordmark, sized to 62% of the screen width.
    final probe = wordmark(100);
    final text = wordmark(100 * (size.width * 0.62) / probe.width);
    final textOffset = Offset(
      (size.width - text.width) / 2,
      (size.height - text.height) / 2,
    );

    // 2. QR slices: 3 x 3 per dark module.
    final modules = qr.moduleCount;
    final layout = qrLayout(size, modules);
    final slice = layout.cell / 3;
    final targets = <Offset>[];
    for (var r = 0; r < modules; r++) {
      for (var c = 0; c < modules; c++) {
        if (!qr.isDark(r, c)) continue;
        for (var j = 0; j < 3; j++) {
          for (var i = 0; i < 3; i++) {
            targets.add(
              layout.origin +
                  Offset(
                    c * layout.cell + (i + 0.5) * slice,
                    r * layout.cell + (j + 0.5) * slice,
                  ),
            );
          }
        }
      }
    }
    final n = targets.length;

    // 3. Draw the wordmark to pixels so we know where the ink is.
    final w = text.width.ceil() + 2;
    final h = text.height.ceil() + 2;
    final recorder = ui.PictureRecorder();
    text.paint(Canvas(recorder), const Offset(1, 1));
    final image = await recorder.endRecording().toImage(w, h);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    image.dispose();
    bool ink(double x, double y) {
      final px = x.floor(), py = y.floor();
      if (px < 0 || py < 0 || px >= w || py >= h) return false;
      return bytes.getUint8((py * w + px) * 4 + 3) >= 110;
    }

    int countAt(double g) {
      var count = 0;
      for (var y = g / 2; y < h; y += g) {
        for (var x = g / 2; x < w; x += g) {
          if (ink(x, y)) count++;
        }
      }
      return count;
    }

    // 4. Pick the grid step that gives at least n squares of ink, so the
    // squares tile the letters without speckle.
    var lo = 0.5, hi = 8.0;
    for (var i = 0; i < 12; i++) {
      final mid = (lo + hi) / 2;
      if (countAt(mid) >= n) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final step = lo;
    final points = <Offset>[];
    for (var y = step / 2; y < h; y += step) {
      for (var x = step / 2; x < w; x += step) {
        if (ink(x, y)) points.add(Offset(x - 1, y - 1) + textOffset);
      }
    }
    points.shuffle(random);
    while (points.length < n) {
      points.add(points[random.nextInt(points.length)]); // very small screens
    }
    final origins = points.sublist(0, n);
    targets.shuffle(random);

    // 5. The burst: every particle is thrown away from the middle of the text.
    final middle = Offset(size.width / 2, size.height / 2);
    final scattered = List<Offset>.generate(n, (i) {
      final away = origins[i] - middle;
      final angle =
          math.atan2(away.dy, away.dx) + (random.nextDouble() - 0.5) * 1.4;
      final distance = size.shortestSide * (0.3 + 0.9 * random.nextDouble());
      return origins[i] + Offset(math.cos(angle), math.sin(angle)) * distance;
    });

    Float32List flat(List<Offset> list) {
      final out = Float32List(list.length * 2);
      for (var i = 0; i < list.length; i++) {
        out[i * 2] = list[i].dx;
        out[i * 2 + 1] = list[i].dy;
      }
      return out;
    }

    return SplashField._(
      text: text,
      textOffset: textOffset,
      origins: flat(origins),
      scattered: flat(scattered),
      targets: flat(targets),
      delays: Float32List.fromList(
        List.generate(n, (_) => random.nextDouble()),
      ),
      bends: Float32List.fromList(
        List.generate(n, (_) => random.nextDouble() * 2 - 1),
      ),
      startSize: step,
      endSize: slice,
    );
  }
}

/// Draws one frame of the splash. [progress] runs from 0 to 1.
///
///  0.00 to 0.07  "Qruify" fades in
///  0.07 to 0.16  it darkens to solid black
///  0.16 to 0.32  it holds, so the name can be read
///  0.32 to 0.44  it bursts apart into particles
///  0.44 to 0.90  they snap back together into the QR code (no pause between)
///  0.90 to 1.00  the finished QR code holds
class SplashPainter extends CustomPainter {
  SplashPainter({required this.progress, required this.field});

  final double progress;
  final SplashField? field;

  static const double burstStart = 0.32;
  static const double burstEnd = 0.44;
  static const double regroupStart = 0.44;
  static const double regroupSpan = 0.30; // each particle's own travel time
  static const double regroupDelay = 0.16; // spread of start times

  /// Fast start, soft landing: particles snap back instead of lingering.
  static const Curve _snap = Cubic(0.22, 1.0, 0.36, 1.0);

  static double _span(double t, double from, double to) =>
      ((t - from) / (to - from)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final f = field;
    if (f == null) return;
    final t = progress;

    if (t < burstStart) {
      final fadeIn = Curves.easeOut.transform(_span(t, 0.0, 0.07));
      final darken = Curves.easeInOut.transform(_span(t, 0.07, 0.16));
      final alpha = fadeIn * (0.09 + 0.91 * darken);
      // Warm up the batched particle draw with an invisible triangle, so
      // its first real use (the burst) does not stall.
      canvas.drawVertices(
        ui.Vertices.raw(ui.VertexMode.triangles, Float32List(6)),
        BlendMode.srcOver,
        Paint(),
      );
      if (alpha <= 0.002) return;
      final bounds = f.textOffset & Size(f.text.width, f.text.height);
      canvas.saveLayer(
        bounds.inflate(4),
        Paint()..color = Color.fromRGBO(0, 0, 0, alpha),
      );
      f.text.paint(canvas, f.textOffset);
      canvas.restore();
      return;
    }

    final burst = Curves.easeOutCubic.transform(_span(t, burstStart, burstEnd));
    // One draw call for every particle (two triangles each). Thousands of
    // separate drawRect calls took ~50 ms a frame; this is a fraction of it.
    final quads = Float32List(f.count * 12);

    for (var i = 0; i < f.count; i++) {
      final ox = f.origins[i * 2], oy = f.origins[i * 2 + 1];
      var x = ox + (f.scattered[i * 2] - ox) * burst;
      var y = oy + (f.scattered[i * 2 + 1] - oy) * burst;

      final d = f.delays[i] * regroupDelay;
      final s = _snap.transform(
        _span(t, regroupStart + d, regroupStart + d + regroupSpan),
      );

      // A little drift while the particles hang in the air.
      final hang = burst * (1 - s);
      x += math.sin(t * 16 + i * 1.7) * 3 * hang;
      y += math.cos(t * 14 + i * 2.3) * 3 * hang;

      if (s > 0) {
        final tx = f.targets[i * 2], ty = f.targets[i * 2 + 1];
        final dx = tx - x, dy = ty - y;
        final bend = f.bends[i] * 0.12 * math.sin(math.pi * s);
        x += dx * s - dy * bend;
        y += dy * s + dx * bend;
      }

      // Particles grow while they fly so the burst reads clearly, then settle
      // to the exact slice size.
      final flying =
          f.startSize + (math.max(f.endSize * 1.4, 4.0) - f.startSize) * burst;
      final side = flying + (f.endSize - flying) * s;
      final h = side / 2;
      final left = x - h, top = y - h, right = x + h, bottom = y + h;
      final k = i * 12;
      quads[k] = left;
      quads[k + 1] = top;
      quads[k + 2] = right;
      quads[k + 3] = top;
      quads[k + 4] = left;
      quads[k + 5] = bottom;
      quads[k + 6] = right;
      quads[k + 7] = top;
      quads[k + 8] = right;
      quads[k + 9] = bottom;
      quads[k + 10] = left;
      quads[k + 11] = bottom;
    }
    final vertices = ui.Vertices.raw(ui.VertexMode.triangles, quads);
    canvas.drawVertices(
      vertices,
      BlendMode.srcOver,
      Paint()
        ..isAntiAlias = false
        ..color = Colors.black,
    );
    vertices.dispose();
  }

  @override
  bool shouldRepaint(SplashPainter old) =>
      old.progress != progress || old.field != field;
}
