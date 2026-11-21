import 'package:flutter/foundation.dart';

/// Fonts used across the app.
///
/// Apple's own font (San Francisco) may only be used on Apple platforms, so
/// iOS uses the system font, which is San Francisco, by leaving the family
/// unset. Everywhere else the app uses Geist, a free font bundled in
/// `assets/fonts` that sits close to it.
abstract final class AppFonts {
  /// The bundled font.
  static const String geist = 'Geist';

  /// Font family for ordinary UI text. Null means "use the system font".
  static String? get ui =>
      defaultTargetPlatform == TargetPlatform.iOS ? null : geist;
}
