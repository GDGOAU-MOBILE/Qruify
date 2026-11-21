import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart' show QrImage;
import 'package:qruify/features/splash/splash_screen.dart';

const _size = Size(390, 844);

/// Particles for the test screen, built once (it needs real async).
Future<SplashField> _buildField(WidgetTester tester, QrImage qr) async {
  final field = await tester.runAsync(() => SplashField.prepare(_size, qr));
  return field!;
}

Future<ui.Image> _frame(
  WidgetTester tester,
  SplashField field,
  double t,
) async {
  final image = await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(Offset.zero & _size, Paint()..color = Colors.white);
    SplashPainter(progress: t, field: field).paint(canvas, _size);
    return recorder.endRecording().toImage(390, 844);
  });
  return image!;
}

void main() {
  setUpAll(() async {
    final loader = FontLoader('Geist')
      ..addFont(rootBundle.load('assets/fonts/Geist.ttf'));
    await loader.load();
  });

  testWidgets('nine particles per dark module', (tester) async {
    final qr = SplashField.qrFor();
    final field = await _buildField(tester, qr);
    var dark = 0;
    for (var r = 0; r < qr.moduleCount; r++) {
      for (var c = 0; c < qr.moduleCount; c++) {
        if (qr.isDark(r, c)) dark++;
      }
    }
    expect(field.count, dark * 9);
  });

  testWidgets('the last frame is exactly the QR code', (tester) async {
    final qr = SplashField.qrFor();
    final field = await _buildField(tester, qr);
    final image = await _frame(tester, field, 1);
    final data = (await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    ))!;

    final layout = SplashField.qrLayout(_size, qr.moduleCount);
    var wrong = 0, light = 0;
    // Check the middle of every module, and every pixel of the quiet zone edge.
    for (var r = 0; r < qr.moduleCount; r++) {
      for (var c = 0; c < qr.moduleCount; c++) {
        final x = (layout.origin.dx + (c + 0.5) * layout.cell).round();
        final y = (layout.origin.dy + (r + 0.5) * layout.cell).round();
        final dark = data.getUint8((y * 390 + x) * 4) < 128;
        if (dark != qr.isDark(r, c)) wrong++;
        if (!qr.isDark(r, c)) light++;
      }
    }
    expect(wrong, 0);
    expect(light, greaterThan(0));

    // No gaps inside a dark module: all 9 corners of its slices are black.
    var gaps = 0;
    for (var r = 0; r < qr.moduleCount; r++) {
      for (var c = 0; c < qr.moduleCount; c++) {
        if (!qr.isDark(r, c)) continue;
        for (final fx in [0.05, 0.5, 0.95]) {
          for (final fy in [0.05, 0.5, 0.95]) {
            final x = (layout.origin.dx + (c + fx) * layout.cell).floor();
            final y = (layout.origin.dy + (r + fy) * layout.cell).floor();
            if (data.getUint8((y * 390 + x) * 4) >= 128) gaps++;
          }
        }
      }
    }
    expect(gaps, 0);
  });

  testWidgets('the first frames show the wordmark, the middle a scatter', (
    tester,
  ) async {
    final qr = SplashField.qrFor();
    final field = await _buildField(tester, qr);

    Future<int> inkPixels(double t) async {
      final image = await _frame(tester, field, t);
      final data = (await tester.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
      ))!;
      var n = 0;
      for (var i = 0; i < data.lengthInBytes; i += 4) {
        if (data.getUint8(i) < 200) n++;
      }
      return n;
    }

    expect(await inkPixels(0.0), 0); // blank white to start
    expect(await inkPixels(0.29), greaterThan(2000)); // the dark wordmark
    expect(await inkPixels(0.56), greaterThan(1000)); // particles in the air
  });

  testWidgets('every frame paints without errors', (tester) async {
    final field = await _buildField(tester, SplashField.qrFor());
    await tester.runAsync(() async {
      for (var i = 0; i <= 100; i++) {
        final recorder = ui.PictureRecorder();
        SplashPainter(
          progress: i / 100,
          field: field,
        ).paint(Canvas(recorder), _size);
        recorder.endRecording().dispose();
      }
    });
  });

  testWidgets('onFinished runs once after the animation', (tester) async {
    final field = await _buildField(tester, SplashField.qrFor());
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          duration: const Duration(milliseconds: 400),
          fieldLoader: (_, _) async => field,
          onFinished: () => calls++,
        ),
      ),
    );
    await tester.pump(); // layout, particles requested
    await tester.pump(const Duration(milliseconds: 20)); // warm-up frames
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 200));
    expect(calls, 0);
    // The animation ends, then a short pause runs before the hand-off.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(calls, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(calls, 1);
  });

  testWidgets('Reduce Motion skips the animation', (tester) async {
    final field = await _buildField(tester, SplashField.qrFor());
    var calls = 0;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: SplashScreen(
            fieldLoader: (_, _) async => field,
            onFinished: () => calls++,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(calls, 1);
  });

  testWidgets('a failure building particles never traps the user', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          fieldLoader: (_, _) async => throw StateError('boom'),
          onFinished: () => calls++,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(calls, 1);
  });
}
