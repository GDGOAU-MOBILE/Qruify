import 'package:flutter/foundation.dart';

import '../../core/qr_detector.dart';
import '../../core/qr_payload.dart';
import '../../core/qr_style.dart';
import '../../core/qr_type.dart';
import '../../data/history_repository.dart';
import '../../data/settings_service.dart';

/// Text inputs on the generator form. Each type uses a subset.
enum GeneratorField {
  url,
  text,
  emailAddress,
  emailSubject,
  emailBody,
  phone,
  wifiSsid,
  wifiPassword,

  /// The single smart input used in auto detect mode.
  smart,
}

/// Holds everything the generator and customization screens edit, and
/// exposes what they need to show: the live QR data, the validation error
/// and the current style.
///
/// Typed values are kept per field, so switching type and coming back does
/// not lose what the user wrote. The controller has no widget code. Listen
/// to it with `ListenableBuilder`.
class GeneratorController extends ChangeNotifier {
  GeneratorController({
    required HistoryRepository history,
    required SettingsService settings,
    QrStyle? initialStyle,
    bool autoDetect = true,
  }) : _auto = autoDetect,
       _history = history,
       _settings = settings,
       _style = initialStyle ?? settings.loadStyle();

  final HistoryRepository _history;
  final SettingsService _settings;

  /// In auto mode one input is used and the type is worked out from it.
  /// Picking a type with [setType] switches to manual mode (used for Wi-Fi).
  bool _auto;
  QrType _type = QrType.url;
  QrStyle _style;
  final Map<GeneratorField, String> _values = {};
  WifiSecurity _wifiSecurity = WifiSecurity.wpa;
  bool _wifiHidden = false;

  bool get isAuto => _auto;

  /// The detected type in auto mode, otherwise the chosen one.
  QrType get type =>
      _auto ? QrDetector.detect(valueOf(GeneratorField.smart)) : _type;
  QrStyle get style => _style;
  WifiSecurity get wifiSecurity => _wifiSecurity;
  bool get wifiHidden => _wifiHidden;

  String valueOf(GeneratorField field) => _values[field] ?? '';

  void setType(QrType type) {
    if (type == _type && !_auto) return;
    _type = type;
    _auto = false;
    notifyListeners();
  }

  /// Back to the single smart input.
  void useAutoDetect() {
    if (_auto) return;
    _auto = true;
    notifyListeners();
  }

  void setValue(GeneratorField field, String value) {
    if (valueOf(field) == value) return;
    _values[field] = value;
    notifyListeners();
  }

  void setWifiSecurity(WifiSecurity security) {
    if (security == _wifiSecurity) return;
    _wifiSecurity = security;
    notifyListeners();
  }

  void setWifiHidden(bool hidden) {
    if (hidden == _wifiHidden) return;
    _wifiHidden = hidden;
    notifyListeners();
  }

  /// Changes the look of the code and remembers it for next time.
  Future<void> setStyle(QrStyle style) async {
    if (style == _style) return;
    _style = style;
    notifyListeners();
    await _settings.saveStyle(style);
  }

  /// The payload for the current type and inputs.
  QrPayload get payload => _auto
      ? QrDetector.payloadFor(valueOf(GeneratorField.smart))
      : switch (_type) {
          QrType.url => UrlPayload(valueOf(GeneratorField.url)),
          QrType.text => TextPayload(valueOf(GeneratorField.text)),
          QrType.email => EmailPayload(
            address: valueOf(GeneratorField.emailAddress),
            subject: valueOf(GeneratorField.emailSubject),
            body: valueOf(GeneratorField.emailBody),
          ),
          QrType.phone => PhonePayload(valueOf(GeneratorField.phone)),
          QrType.wifi => WifiPayload(
            ssid: valueOf(GeneratorField.wifiSsid),
            password: valueOf(GeneratorField.wifiPassword),
            security: _wifiSecurity,
            hidden: _wifiHidden,
          ),
        };

  /// True once the user has typed something for the current type.
  bool get hasInput => !payload.isBlank;

  /// The first problem with the current input, or null when it is valid.
  /// Show it only when [hasInput] is true to avoid scolding an empty form.
  String? get validationError => payload.validate();

  bool get isValid => validationError == null;

  /// The string to feed the live preview, or null while input is invalid.
  String? get qrData => isValid ? payload.encode() : null;

  /// False when the chosen colors would make the code hard to scan.
  bool get styleIsScannable => _style.isLikelyScannable;

  /// Saves the current code to history and returns it. Throws a
  /// [StateError] if the input is not valid, so check [isValid] first.
  Future<HistoryEntry> generate() async {
    final error = validationError;
    if (error != null) throw StateError(error);
    return _history.add(payload, _style);
  }

  /// Clears every typed value and returns to the default security options.
  void reset() {
    _values.clear();
    _wifiSecurity = WifiSecurity.wpa;
    _wifiHidden = false;
    notifyListeners();
  }
}
