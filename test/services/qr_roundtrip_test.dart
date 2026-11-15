import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:qr_flutter/qr_flutter.dart' show QrCode, QrImage;
import 'package:qruify/core/qr_payload.dart';
import 'package:qruify/core/qr_style.dart';
import 'package:qruify/services/qr_export_service.dart';
import 'package:zxing2/qrcode.dart';

/// Reads a PNG the way a phone camera app would and returns the text.
String scan(Uint8List png) {
  final image = img.decodePng(png)!;
  final pixels = image
      .convert(numChannels: 4)
      .getBytes(order: img.ChannelOrder.abgr)
      .buffer
      .asInt32List();
  final source = RGBLuminanceSource(image.width, image.height, pixels);
  final bitmap = BinaryBitmap(HybridBinarizer(source));
  return QRCodeReader().decode(bitmap).text;
}

void main() {
  final service = QrExportService();

  Future<Uint8List> render(
    WidgetTester tester,
    String data,
    QrStyle style,
  ) async {
    final bytes = await tester.runAsync(
      () => service.renderPng(data, style, size: 600),
    );
    return bytes!;
  }

  testWidgets('every payload type decodes back to its encoded string', (
    tester,
  ) async {
    const payloads = <QrPayload>[
      UrlPayload('example.com/path?a=1&b=2'),
      TextPayload('Hello, Qruify!\nSecond line, plain ASCII'),
      EmailPayload(
        address: 'a@b.com',
        subject: 'Hi & bye',
        body: 'Line 1\nLine 2',
      ),
      PhonePayload('+234 (801) 234-5678'),
      WifiPayload(ssid: 'Home;Net', password: r'p\ss"w:rd,1'),
    ];
    for (final payload in payloads) {
      expect(payload.validate(), isNull, reason: payload.type.name);
      final png = await render(tester, payload.encode(), QrStyle.standard);
      expect(scan(png), payload.encode(), reason: payload.type.name);
    }
  });

  testWidgets('custom colors and every error level still scan', (tester) async {
    for (final level in QrErrorLevel.values) {
      final style = QrStyle(
        foreground: const Color(0xFF14213D),
        background: const Color(0xFFFCEFD2),
        errorLevel: level,
      );
      expect(style.isLikelyScannable, isTrue);
      final png = await render(tester, 'https://example.com', style);
      expect(scan(png), 'https://example.com', reason: level.name);
    }
  });

  testWidgets('image pixels match the QR matrix for any size', (tester) async {
    const style = QrStyle(
      foreground: Color(0xFF14213D),
      background: Color(0xFFFCEFD2),
      errorLevel: QrErrorLevel.high,
    );
    final texts = [
      'x',
      'Unicode: emoji 🙂 and é',
      'a' * kMaxQrBytes, // the largest allowed payload, version 40
    ];
    for (final text in texts) {
      final png = (await tester.runAsync(
        () => service.renderPng(text, style, size: 1500),
      ))!;
      final image = img.decodePng(png)!;
      final qr = QrCode.fromData(
        data: text,
        errorCorrectLevel: style.errorLevel.qrValue,
      );
      final matrix = QrImage(qr);
      const quiet = QrExportService.quietZoneModules;
      final total = matrix.moduleCount + quiet * 2;
      expect(image.width, image.height);
      expect(image.width % total, 0, reason: 'whole pixels per module');
      expect(image.width, lessThanOrEqualTo(1500));
      final px = image.width ~/ total;

      int colorAt(int module, int other, {required bool row}) {
        final x = (row ? other : module) * px + px ~/ 2;
        final y = (row ? module : other) * px + px ~/ 2;
        final c = image.getPixel(x, y);
        return (c.a.toInt() << 24) |
            (c.r.toInt() << 16) |
            (c.g.toInt() << 8) |
            c.b.toInt();
      }

      var wrong = 0;
      for (var r = -quiet; r < matrix.moduleCount + quiet; r++) {
        for (var c = -quiet; c < matrix.moduleCount + quiet; c++) {
          final dark =
              r >= 0 &&
              c >= 0 &&
              r < matrix.moduleCount &&
              c < matrix.moduleCount &&
              matrix.isDark(r, c);
          final expected = (dark ? style.foreground : style.background)
              .toARGB32();
          if (colorAt(r + quiet, c + quiet, row: true) != expected) wrong++;
        }
      }
      expect(wrong, 0, reason: 'text length ${text.length}');
    }
  });

  testWidgets('data that cannot fit is rejected', (tester) async {
    final error = await tester.runAsync(() async {
      try {
        await service.renderPng('a' * 3000, QrStyle.standard);
        return null;
      } catch (e) {
        return e;
      }
    });
    expect(error, isA<ArgumentError>());
  });
}
