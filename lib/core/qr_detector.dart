import 'qr_payload.dart';
import 'qr_type.dart';

/// Works out what a single typed or pasted string is, so the user never has to
/// pick a type. The rules are deliberately simple and run in this order:
///
/// 1. `mailto:` or something shaped like `name@site.tld`  -> email
/// 2. `tel:` or something that is mostly digits           -> phone
/// 3. `http(s)://`, `www.`, `localhost`, or `site.tld/..`  -> link
/// 4. anything else                                       -> text
///
/// Wi-Fi is not detected here. It needs a password and a security type, so it
/// has its own form.
class QrDetector {
  const QrDetector._();

  static final _email = RegExp(r'^[^\s@,;<>]+@[^\s@,;<>]+\.[^\s@,;<>]{2,}$');
  static final _phoneChars = RegExp(r'^\+?[\d\s\-.()]+$');
  static final _scheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.\-]*://');
  // site.tld, optional port and path. The last label must be letters.
  static final _domain = RegExp(
    r'^([a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}(:\d+)?([/?#]\S*)?$',
  );

  /// The type of [input]. Blank input counts as text.
  static QrType detect(String input) {
    final s = input.trim();
    if (s.isEmpty) return QrType.text;

    final lower = s.toLowerCase();
    if (lower.startsWith('mailto:')) return QrType.email;
    if (_email.hasMatch(s)) return QrType.email;

    if (lower.startsWith('tel:')) return QrType.phone;
    if (_looksLikePhone(s)) return QrType.phone;

    if (_scheme.hasMatch(s) &&
        (lower.startsWith('http://') || lower.startsWith('https://'))) {
      return QrType.url;
    }
    if (lower.startsWith('www.') && !s.contains(' ')) return QrType.url;
    if (lower.startsWith('localhost') && !s.contains(' ')) return QrType.url;
    if (_domain.hasMatch(s)) return QrType.url;

    return QrType.text;
  }

  /// Digits with the usual separators. Needs 7 to 15 digits, or a leading
  /// plus with at least 3, so a year like "2025" stays text.
  static bool _looksLikePhone(String s) {
    if (!_phoneChars.hasMatch(s)) return false;
    final digits = s.replaceAll(RegExp(r'\D'), '').length;
    if (s.startsWith('+')) return digits >= 3 && digits <= 15;
    return digits >= 7 && digits <= 15;
  }

  /// The payload for [input], using the detected type.
  static QrPayload payloadFor(String input) {
    final s = input.trim();
    switch (detect(s)) {
      case QrType.email:
        final address = s.toLowerCase().startsWith('mailto:')
            ? s.substring(7)
            : s;
        return EmailPayload(address: address);
      case QrType.phone:
        final number = s.toLowerCase().startsWith('tel:') ? s.substring(4) : s;
        return PhonePayload(number);
      case QrType.url:
        return UrlPayload(s);
      case QrType.text:
      case QrType.wifi:
        return TextPayload(input);
    }
  }
}
