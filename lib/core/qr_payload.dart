import 'dart:convert';

import 'qr_type.dart';

/// Largest payload, in UTF-8 bytes, that fits a QR code at every error
/// correction level (version 40, level H holds 1273 bytes).
const int kMaxQrBytes = 1273;

/// What goes into a QR code, plus the rules for turning user input into the
/// exact string that gets encoded.
///
/// Each subclass keeps the raw input the user typed. [validate] returns a
/// message for the first problem found, or null when the input is usable.
/// [encode] must only be called when [validate] returns null.
sealed class QrPayload {
  const QrPayload();

  QrType get type;

  /// True when the user has not typed anything relevant yet. Use it to hold
  /// back error messages on a fresh form.
  bool get isBlank;

  /// Short label for the history list.
  String get title;

  /// A user facing message for the first problem, or null if valid.
  String? validate();

  /// The exact string stored in the QR code.
  String encode();

  /// Shared size check, applied by every subclass after its own checks.
  String? _checkSize(String encoded) {
    if (utf8.encode(encoded).length > kMaxQrBytes) {
      return 'This is too long for a QR code.';
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// URL
// ---------------------------------------------------------------------------

class UrlPayload extends QrPayload {
  const UrlPayload(this.input);

  final String input;

  static final _hasScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.\-]*://');

  /// The input with surrounding spaces removed and `https://` added when no
  /// scheme was typed.
  String get normalized {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return trimmed;
    return _hasScheme.hasMatch(trimmed) ? trimmed : 'https://$trimmed';
  }

  @override
  QrType get type => QrType.url;

  @override
  bool get isBlank => input.trim().isEmpty;

  @override
  String get title {
    final host = Uri.tryParse(normalized)?.host ?? '';
    return host.isEmpty ? input.trim() : host;
  }

  @override
  String? validate() {
    if (isBlank) return 'Enter a link.';
    final value = normalized;
    if (RegExp(r'\s').hasMatch(value)) return 'A link cannot contain spaces.';
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) {
      return 'That does not look like a valid link.';
    }
    if (uri.userInfo.isNotEmpty) {
      return 'Links with a username or password are not supported.';
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return 'Links must start with http or https.';
    }
    final host = uri.host;
    final looksLikeHost =
        host.contains('.') ||
        host == 'localhost' ||
        RegExp(r'^\[.*\]$').hasMatch(host);
    if (!looksLikeHost) return 'That does not look like a valid link.';
    return _checkSize(value);
  }

  @override
  String encode() => normalized;
}

// ---------------------------------------------------------------------------
// Plain text
// ---------------------------------------------------------------------------

class TextPayload extends QrPayload {
  const TextPayload(this.input);

  final String input;

  @override
  QrType get type => QrType.text;

  @override
  bool get isBlank => input.trim().isEmpty;

  @override
  String get title {
    final firstLine = input.trim().split('\n').first;
    return firstLine.length > 40
        ? '${firstLine.substring(0, 40)}...'
        : firstLine;
  }

  @override
  String? validate() {
    if (isBlank) return 'Enter some text.';
    return _checkSize(input);
  }

  @override
  String encode() => input;
}

// ---------------------------------------------------------------------------
// Email
// ---------------------------------------------------------------------------

class EmailPayload extends QrPayload {
  const EmailPayload({
    required this.address,
    this.subject = '',
    this.body = '',
  });

  final String address;
  final String subject;
  final String body;

  static final _emailPattern = RegExp(
    r'^[^\s@,;<>]+@[^\s@,;<>]+\.[^\s@,;<>]{2,}$',
  );

  String get _address => address.trim();

  @override
  QrType get type => QrType.email;

  @override
  bool get isBlank =>
      _address.isEmpty && subject.trim().isEmpty && body.trim().isEmpty;

  @override
  String get title => _address;

  @override
  String? validate() {
    if (_address.isEmpty) return 'Enter an email address.';
    if (!_emailPattern.hasMatch(_address)) {
      return 'That does not look like a valid email address.';
    }
    return _checkSize(encode());
  }

  /// A `mailto:` link. Subject and body are percent encoded.
  @override
  String encode() {
    final params = <String>[
      if (subject.trim().isNotEmpty)
        'subject=${Uri.encodeComponent(subject.trim())}',
      if (body.trim().isNotEmpty) 'body=${Uri.encodeComponent(body.trim())}',
    ];
    return params.isEmpty
        ? 'mailto:$_address'
        : 'mailto:$_address?${params.join('&')}';
  }
}

// ---------------------------------------------------------------------------
// Phone
// ---------------------------------------------------------------------------

class PhonePayload extends QrPayload {
  const PhonePayload(this.input);

  final String input;

  /// The number with spaces, dashes, dots and brackets removed. A leading
  /// plus sign is kept.
  String get cleaned => input.trim().replaceAll(RegExp(r'[\s\-.()]'), '');

  @override
  QrType get type => QrType.phone;

  @override
  bool get isBlank => input.trim().isEmpty;

  @override
  String get title => input.trim();

  @override
  String? validate() {
    if (isBlank) return 'Enter a phone number.';
    if (!RegExp(r'^\+?\d+$').hasMatch(cleaned)) {
      return 'Phone numbers can only contain digits and a leading +.';
    }
    final digits = cleaned.replaceFirst('+', '').length;
    if (digits < 3 || digits > 15) {
      return 'Phone numbers must have 3 to 15 digits.';
    }
    return null;
  }

  @override
  String encode() => 'tel:$cleaned';
}

// ---------------------------------------------------------------------------
// Wi-Fi
// ---------------------------------------------------------------------------

enum WifiSecurity {
  wpa('WPA'),
  wep('WEP'),
  none('nopass');

  const WifiSecurity(this.code);

  /// The value written after `T:` in the Wi-Fi QR format.
  final String code;
}

class WifiPayload extends QrPayload {
  const WifiPayload({
    required this.ssid,
    this.password = '',
    this.security = WifiSecurity.wpa,
    this.hidden = false,
  });

  final String ssid;
  final String password;
  final WifiSecurity security;
  final bool hidden;

  @override
  QrType get type => QrType.wifi;

  @override
  bool get isBlank => ssid.isEmpty && password.isEmpty;

  @override
  String get title => ssid;

  @override
  String? validate() {
    if (ssid.isEmpty) return 'Enter the network name.';
    if (utf8.encode(ssid).length > 32) {
      return 'Network names can be at most 32 bytes.';
    }
    if (security != WifiSecurity.none) {
      if (password.isEmpty) return 'Enter the password.';
      final isHexKey = RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(password);
      if (security == WifiSecurity.wpa &&
          !isHexKey &&
          (password.length < 8 || password.length > 63)) {
        return 'WPA passwords must be 8 to 63 characters.';
      }
    }
    return _checkSize(encode());
  }

  /// Backslash, semicolon, comma, colon and double quote are special in the
  /// Wi-Fi format and need a backslash in front.
  static String escape(String value) =>
      value.replaceAllMapped(RegExp(r'[\\;,:"]'), (m) => '\\${m[0]}');

  @override
  String encode() {
    final buffer = StringBuffer('WIFI:T:${security.code};S:${escape(ssid)};');
    if (security != WifiSecurity.none) {
      buffer.write('P:${escape(password)};');
    }
    if (hidden) buffer.write('H:true;');
    buffer.write(';');
    return buffer.toString();
  }
}
