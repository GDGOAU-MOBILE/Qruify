import 'dart:ui';

/// Parses `#RRGGBB`, `RRGGBB`, `#RGB` or `RGB` into an opaque color. Returns
/// null when the text is not a valid hex color.
Color? parseHexColor(String input) {
  var s = input.trim();
  if (s.startsWith('#')) s = s.substring(1);
  if (s.length == 3) s = s.split('').map((c) => '$c$c').join();
  if (s.length != 6 || !RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(s)) return null;
  return Color(0xFF000000 | int.parse(s, radix: 16));
}

/// `RRGGBB` in upper case, without the alpha or the `#`.
String hexOf(Color color) => (color.toARGB32() & 0xFFFFFF)
    .toRadixString(16)
    .padLeft(6, '0')
    .toUpperCase();
