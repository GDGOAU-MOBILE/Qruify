import 'dart:ui';

import 'package:qr_flutter/qr_flutter.dart';

import 'qr_logo.dart';

/// How much of a damaged code a scanner can still recover. Higher levels
/// survive more damage but make the code denser.
enum QrErrorLevel {
  low(QrErrorCorrectLevel.L),
  medium(QrErrorCorrectLevel.M),
  quartile(QrErrorCorrectLevel.Q),
  high(QrErrorCorrectLevel.H);

  const QrErrorLevel(this.qrValue);

  /// The matching constant from `qr_flutter`.
  final int qrValue;
}

/// Colors and error correction for a rendered QR code.
class QrStyle {
  const QrStyle({
    this.foreground = const Color(0xFF000000),
    this.background = const Color(0xFFFFFFFF),
    this.errorLevel = QrErrorLevel.medium,
    this.logo,
  });

  final Color foreground;
  final Color background;
  final QrErrorLevel errorLevel;

  /// A picture drawn in the middle of the code, or null.
  final QrLogo? logo;

  /// The level actually used to build the code. A logo hides part of the
  /// code, so it always gets the strongest level, whatever was chosen.
  QrErrorLevel get effectiveErrorLevel =>
      logo == null ? errorLevel : QrErrorLevel.high;

  static const QrStyle standard = QrStyle();

  QrStyle copyWith({
    Color? foreground,
    Color? background,
    QrErrorLevel? errorLevel,
    QrLogo? logo,
    bool removeLogo = false,
  }) => QrStyle(
    foreground: foreground ?? this.foreground,
    background: background ?? this.background,
    errorLevel: errorLevel ?? this.errorLevel,
    logo: removeLogo ? null : (logo ?? this.logo),
  );

  /// WCAG contrast ratio between foreground and background, from 1 to 21.
  double get contrastRatio {
    final a = foreground.computeLuminance();
    final b = background.computeLuminance();
    final lighter = a > b ? a : b;
    final darker = a > b ? b : a;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// A rough check that phone cameras will read the code: the modules must be
  /// darker than the background, both fully opaque, with a contrast ratio of
  /// at least 3.
  bool get isLikelyScannable =>
      foreground.a == 1 &&
      background.a == 1 &&
      foreground.computeLuminance() < background.computeLuminance() &&
      contrastRatio >= 3;

  @override
  bool operator ==(Object other) =>
      other is QrStyle &&
      other.foreground == foreground &&
      other.background == background &&
      other.errorLevel == errorLevel &&
      identical(other.logo, logo);

  @override
  int get hashCode => Object.hash(foreground, background, errorLevel, logo);
}
