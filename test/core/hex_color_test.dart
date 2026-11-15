import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:qruify/core/hex_color.dart';

void main() {
  test('parses common forms', () {
    expect(parseHexColor('#112233'), const Color(0xFF112233));
    expect(parseHexColor('112233'), const Color(0xFF112233));
    expect(parseHexColor('  #abc '), const Color(0xFFAABBCC));
    expect(parseHexColor('FFF'), const Color(0xFFFFFFFF));
  });

  test('rejects anything else', () {
    for (final s in [
      '',
      '#',
      '12',
      '1234',
      '12345',
      '1234567',
      'GGGGGG',
      '#12 34 56',
    ]) {
      expect(parseHexColor(s), isNull, reason: s);
    }
  });

  test('hexOf round trips', () {
    expect(hexOf(const Color(0xFF0A2540)), '0A2540');
    expect(
      parseHexColor(hexOf(const Color(0xFF7A0019))),
      const Color(0xFF7A0019),
    );
  });
}
