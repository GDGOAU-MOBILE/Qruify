import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:qruify/core/qr_style.dart';

void main() {
  test('black on white is scannable with maximum contrast', () {
    expect(QrStyle.standard.isLikelyScannable, isTrue);
    expect(QrStyle.standard.contrastRatio, closeTo(21, 0.01));
  });
  test('low contrast is flagged', () {
    const style = QrStyle(
      foreground: Color(0xFFCCCCCC),
      background: Color(0xFFFFFFFF),
    );
    expect(style.isLikelyScannable, isFalse);
  });
  test('translucent colors are flagged', () {
    const style = QrStyle(foreground: Color(0x80000000));
    expect(style.isLikelyScannable, isFalse);
  });
  test('inverted colors are flagged', () {
    const style = QrStyle(
      foreground: Color(0xFFFFFFFF),
      background: Color(0xFF000000),
    );
    expect(style.isLikelyScannable, isFalse);
  });
}
