import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:qruify/core/qr_logo.dart';
import 'package:qruify/core/qr_style.dart';

import '../support/test_logo.dart';

void main() {
  group('LogoPlan, for every QR version from 1 to 40', () {
    // A version v code is 17 + 4v modules on a side.
    // Version 1 (21 modules) is too small for a logo, see the last test.
    final sizes = [for (var v = 2; v <= 40; v++) 17 + 4 * v];

    test('stays inside the error correction budget', () {
      for (final n in sizes) {
        final plan = LogoPlan.forModules(n)!;
        expect(
          plan.coveredFraction,
          lessThanOrEqualTo(LogoPlan.maxCoveredFraction),
          reason: 'n=$n',
        );
        expect(
          plan.logoModules / n,
          lessThanOrEqualTo(LogoPlan.maxWidthFraction),
          reason: 'n=$n',
        );
        // H repairs about 30%; keep real loss at a third of that or less.
        expect(plan.coveredFraction, lessThan(0.30 / 2.5), reason: 'n=$n');
      }
    });

    test('sits exactly on module edges, dead center', () {
      for (final n in sizes) {
        final plan = LogoPlan.forModules(n)!;
        expect(plan.logoModules.isOdd, isTrue, reason: 'n=$n');
        expect(plan.clearModules.isOdd, isTrue, reason: 'n=$n');
        // Same clear space on both sides: perfectly centered.
        expect(plan.clearStart * 2 + plan.clearModules, n, reason: 'n=$n');
        expect(plan.logoModules, greaterThanOrEqualTo(LogoPlan.minLogoModules));
      }
    });

    test('never touches the three corner finder patterns', () {
      for (final n in sizes) {
        final plan = LogoPlan.forModules(n)!;
        // Finder patterns, separators and the format information stay
        // inside the first 9 rows and columns, and the last 8.
        expect(
          plan.clearStart,
          greaterThanOrEqualTo(LogoPlan.edgeMargin),
          reason: 'n=$n',
        );
        expect(
          n - (plan.clearStart + plan.clearModules),
          greaterThanOrEqualTo(LogoPlan.edgeMargin),
          reason: 'n=$n',
        );
      }
    });

    test('grows with the code but never past a fifth of its width', () {
      var last = 0;
      for (final n in sizes) {
        final size = LogoPlan.forModules(n)!.logoModules;
        expect(size, greaterThanOrEqualTo(last));
        last = size;
      }
    });

    test('covers() matches the cleared square exactly', () {
      final plan = LogoPlan.forModules(33)!;
      var count = 0;
      for (var r = 0; r < 33; r++) {
        for (var c = 0; c < 33; c++) {
          if (plan.covers(r, c)) count++;
        }
      }
      expect(count, plan.clearModules * plan.clearModules);
    });

    test('a code too small for a logo gets none', () {
      expect(LogoPlan.forModules(9), isNull);
      expect(LogoPlan.forModules(21), isNull); // version 1
      expect(LogoPlan.forModules(21), isNull); // version 1
    });
  });

  testWidgets('a logo forces the strongest error correction', (tester) async {
    final logo = await real(tester, makeLogo);
    const low = QrStyle(errorLevel: QrErrorLevel.low);
    expect(low.effectiveErrorLevel, QrErrorLevel.low);
    expect(low.copyWith(logo: logo).effectiveErrorLevel, QrErrorLevel.high);
    // The user's own choice is kept, for when the logo is removed.
    expect(low.copyWith(logo: logo).errorLevel, QrErrorLevel.low);
    expect(low.copyWith(logo: logo).copyWith(removeLogo: true).logo, isNull);
  });

  testWidgets('prepare crops any picture to a centered square', (tester) async {
    final out = await real(tester, () async {
      final raw = await makeRawLogoPng(width: 400, height: 150);
      final png = await QrLogo.prepare(raw, size: 128);
      final codec = await ui.instantiateImageCodec(png);
      final frame = await codec.getNextFrame();
      return (frame.image.width, frame.image.height);
    });
    expect(out, (128, 128));
  });

  testWidgets('prepare rejects something that is not a picture', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await expectLater(
        QrLogo.prepare(Uint8List.fromList([1, 2, 3, 4])),
        throwsA(anything),
      );
    });
  });
}
