import 'dart:convert';
import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/qr_logo.dart';
import '../core/qr_style.dart';

/// Small preferences that survive restarts. Currently the last style used.
class SettingsService {
  SettingsService(this._prefs);

  final SharedPreferences _prefs;

  static const _kForeground = 'style.foreground';
  static const _kBackground = 'style.background';
  static const _kErrorLevel = 'style.errorLevel';
  static const _kLogo = 'style.logo';

  static const _kOnboardingDone = 'onboarding.done';

  bool get onboardingDone => _prefs.getBool(_kOnboardingDone) ?? false;

  Future<void> setOnboardingDone() => _prefs.setBool(_kOnboardingDone, true);

  /// Shows the welcome screen again the next time the app opens.
  Future<void> resetOnboarding() => _prefs.remove(_kOnboardingDone);

  /// Forgets the saved colors, error correction and logo. The next time the
  /// app opens it starts from the standard style again.
  Future<void> clearStyle() async {
    await _prefs.remove(_kForeground);
    await _prefs.remove(_kBackground);
    await _prefs.remove(_kErrorLevel);
    await _prefs.remove(_kLogo);
  }

  static Future<SettingsService> load() async =>
      SettingsService(await SharedPreferences.getInstance());

  QrStyle loadStyle() {
    final fg = _prefs.getInt(_kForeground);
    final bg = _prefs.getInt(_kBackground);
    final level = _prefs.getInt(_kErrorLevel);
    final logo = _prefs.getString(_kLogo);
    return QrStyle(
      logo: logo == null ? null : _decodeLogo(logo),
      foreground: fg == null ? QrStyle.standard.foreground : Color(fg),
      background: bg == null ? QrStyle.standard.background : Color(bg),
      errorLevel:
          level != null && level >= 0 && level < QrErrorLevel.values.length
          ? QrErrorLevel.values[level]
          : QrStyle.standard.errorLevel,
    );
  }

  static QrLogo? _decodeLogo(String encoded) {
    try {
      return QrLogo.fromPng(base64Decode(encoded));
    } on FormatException {
      return null;
    }
  }

  Future<void> saveStyle(QrStyle style) async {
    final logo = style.logo;
    if (logo == null) {
      await _prefs.remove(_kLogo);
    } else {
      await _prefs.setString(_kLogo, base64Encode(logo.png));
    }
    await _prefs.setInt(_kForeground, style.foreground.toARGB32());
    await _prefs.setInt(_kBackground, style.background.toARGB32());
    await _prefs.setInt(_kErrorLevel, style.errorLevel.index);
  }
}
