import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:qr_flutter/qr_flutter.dart' show QrCode, QrErrorCorrectLevel;
import 'package:qruify/core/qr_logo.dart';
import 'package:qruify/core/qr_style.dart';
import 'package:qruify/services/qr_export_service.dart';

import '../support/qr_scan.dart';
import '../support/test_logo.dart';

void main() {
  final service = QrExportService();

  Future<Uint8List> render(
    WidgetTester tester,
    String data,
    QrStyle style, {
    int size = 800,
  }) async => (await tester.runAsync(
    () => service.renderPng(data, style, size: size),
  ))!;

  /// The QR version (1 to 40) the code uses at the logo's forced level.
  int versionOf(String data) =>
      (QrCode.fromData(
            data: data,
            errorCorrectLevel: QrErrorCorrectLevel.H,
          ).moduleCount -
          17) ~/
      4;

  // Short to medium payloads, so several QR versions are covered. The long
  // ones are far past version 1, where there is no logo.
  final payloads = <String>[
    'https://qruify.app',
    'https://example.com/a/longer/path?with=query&and=more',
    'Hello from Qruify. This is a plain text note with a few more words in it.',
    'WIFI:T:WPA;S:Home Network;P:correct horse battery staple;;',
    'https://example.com/${'segment/' * 12}end',
    'BEGIN:VCARD\nVERSION:3.0\nFN:Ada Lovelace\nTEL:+441234567890\nEMAIL:ada@example.com\nEND:VCARD',
  ];

  testWidgets('codes with a logo still scan, across QR versions', (
    tester,
  ) async {
    final logo = await real(tester, makeLogo);
    final style = const QrStyle().copyWith(logo: logo);
    final versions = <int>{};
    for (final data in payloads) {
      versions.add(versionOf(data));
      final png = await render(tester, data, style);
      expect(scanPng(png), data, reason: 'version ${versionOf(data)}: $data');
    }
    // Make sure the test really spans more than one size.
    expect(versions.length, greaterThanOrEqualTo(3), reason: '$versions');
  });

  testWidgets('a weak chosen level is raised, so it still scans', (
    tester,
  ) async {
    final logo = await real(tester, makeLogo);
    const data = 'https://example.com/a/longer/path?with=query&and=more';
    for (final level in QrErrorLevel.values) {
      final style = QrStyle(errorLevel: level, logo: logo);
      final png = await render(tester, data, style);
      expect(scanPng(png), data, reason: level.name);
    }
  });

  testWidgets('custom colors with a logo still scan', (tester) async {
    final logo = await real(tester, makeLogo);
    const data = 'https://example.com/a/longer/path?with=query&and=more';
    for (final (fg, bg) in [
      (const Color(0xFF0A2540), const Color(0xFFFFF7E6)),
      (const Color(0xFF7A0019), const Color(0xFFE8F1FF)),
      (const Color(0xFF000000), const Color(0xFFF2F2F7)),
    ]) {
      final style = QrStyle(foreground: fg, background: bg, logo: logo);
      expect(
        scanPng(await render(tester, data, style)),
        data,
        reason: '$fg on $bg',
      );
    }
  });

  testWidgets('a logo with transparent corners still scans', (tester) async {
    // Transparent areas show the background color through, never old modules.
    final logo = await real(tester, () async {
      final recorder = PictureRecorder();
      Canvas(recorder).drawCircle(
        const Offset(64, 64),
        50,
        Paint()..color = const Color(0xFF1A73E8),
      );
      final image = await recorder.endRecording().toImage(128, 128);
      final raw = (await image.toByteData(
        format: ImageByteFormat.png,
      ))!.buffer.asUint8List();
      final out = QrLogo.fromPng(await QrLogo.prepare(raw));
      await out.ready;
      return out;
    });
    const data = 'https://example.com/a/longer/path?with=query&and=more';
    final png = await render(tester, data, QrStyle(logo: logo));
    expect(scanPng(png), data);
  });

  testWidgets('different export sizes all scan', (tester) async {
    final logo = await real(tester, makeLogo);
    const data = 'https://example.com/a/longer/path?with=query&and=more';
    for (final size in [300, 512, 1024, 1600]) {
      final png = await render(tester, data, QrStyle(logo: logo), size: size);
      expect(scanPng(png), data, reason: 'size $size');
    }
  });

  testWidgets('the logo is really in the image, in the middle', (tester) async {
    final logo = await real(tester, makeLogo);
    const data = 'https://example.com/a/longer/path?with=query&and=more';
    final withLogo = await render(tester, data, QrStyle(logo: logo));
    final plain = await render(
      tester,
      data,
      const QrStyle(errorLevel: QrErrorLevel.high),
    );
    expect(withLogo, isNot(plain));
    final image = img.decodePng(withLogo)!;
    expect(image.width, image.height);
    // The test logo is a red field with a white disc. The logo is about a
    // fifth of the width, so a point 7% left of center is on the red field.
    final red = image.getPixel((image.width * 0.43).round(), image.height ~/ 2);
    expect([red.r, red.g, red.b], [229, 57, 53]);
    // And the middle itself is the white disc, not a black module.
    final middle = image.getPixel(image.width ~/ 2, image.height ~/ 2);
    expect([middle.r, middle.g, middle.b], [255, 255, 255]);
  });

  testWidgets('removing the logo gives the plain code back', (tester) async {
    final logo = await real(tester, makeLogo);
    const data = 'https://example.com/a/longer/path?with=query&and=more';
    final withLogo = QrStyle(logo: logo);
    final removed = withLogo.copyWith(removeLogo: true);
    expect(removed, const QrStyle());
    expect(scanPng(await render(tester, data, removed)), data);
  });
}
