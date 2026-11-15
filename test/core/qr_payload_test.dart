import 'package:flutter_test/flutter_test.dart';
import 'package:qruify/core/qr_payload.dart';

void main() {
  group('UrlPayload', () {
    test('adds https when the scheme is missing', () {
      expect(
        const UrlPayload(' example.com/a ').encode(),
        'https://example.com/a',
      );
    });
    test('keeps an existing scheme', () {
      expect(
        const UrlPayload('http://example.com').encode(),
        'http://example.com',
      );
    });
    test('rejects blanks, spaces, bad hosts and other schemes', () {
      expect(const UrlPayload('').validate(), isNotNull);
      expect(const UrlPayload('exa mple.com').validate(), isNotNull);
      expect(const UrlPayload('notahost').validate(), isNotNull);
      expect(const UrlPayload('ftp://example.com').validate(), isNotNull);
      expect(const UrlPayload('example.com').validate(), isNull);
    });
    test('rejects a username or password in the link', () {
      expect(const UrlPayload('mailto:a@b.com').validate(), isNotNull);
      expect(const UrlPayload('user:pw@example.com').validate(), isNotNull);
    });
    test('title is the host', () {
      expect(const UrlPayload('example.com/x').title, 'example.com');
    });
  });

  group('TextPayload', () {
    test('keeps text exactly as typed', () {
      expect(const TextPayload('  hi\nthere ').encode(), '  hi\nthere ');
    });
    test('rejects blank and oversized text', () {
      expect(const TextPayload('   ').validate(), isNotNull);
      expect(TextPayload('a' * (kMaxQrBytes + 1)).validate(), isNotNull);
      expect(TextPayload('a' * kMaxQrBytes).validate(), isNull);
    });
  });

  group('EmailPayload', () {
    test('plain address', () {
      expect(const EmailPayload(address: 'a@b.com').encode(), 'mailto:a@b.com');
    });
    test('encodes subject and body', () {
      expect(
        const EmailPayload(
          address: 'a@b.com',
          subject: 'Hi & bye',
          body: 'Line 1',
        ).encode(),
        'mailto:a@b.com?subject=Hi%20%26%20bye&body=Line%201',
      );
    });
    test('validates the address', () {
      expect(const EmailPayload(address: '').validate(), isNotNull);
      expect(const EmailPayload(address: 'nope').validate(), isNotNull);
      expect(const EmailPayload(address: 'a@b').validate(), isNotNull);
      expect(const EmailPayload(address: 'a@b.co').validate(), isNull);
    });
  });

  group('PhonePayload', () {
    test('strips formatting but keeps the plus', () {
      expect(
        const PhonePayload('+234 (801) 234-5678').encode(),
        'tel:+2348012345678',
      );
    });
    test('validates digits and length', () {
      expect(const PhonePayload('').validate(), isNotNull);
      expect(const PhonePayload('12ab').validate(), isNotNull);
      expect(const PhonePayload('12').validate(), isNotNull);
      expect(const PhonePayload('+1234567890123456').validate(), isNotNull);
      expect(const PhonePayload('08012345678').validate(), isNull);
    });
  });

  group('WifiPayload', () {
    test('WPA network', () {
      expect(
        const WifiPayload(ssid: 'Home', password: 'secret123').encode(),
        'WIFI:T:WPA;S:Home;P:secret123;;',
      );
    });
    test('open network leaves out the password', () {
      expect(
        const WifiPayload(
          ssid: 'Cafe',
          security: WifiSecurity.none,
          password: 'x',
        ).encode(),
        'WIFI:T:nopass;S:Cafe;;',
      );
    });
    test('hidden flag', () {
      expect(
        const WifiPayload(
          ssid: 'H',
          password: '12345678',
          hidden: true,
        ).encode(),
        'WIFI:T:WPA;S:H;P:12345678;H:true;;',
      );
    });
    test('escapes special characters', () {
      expect(
        const WifiPayload(ssid: r'a;b:c', password: r'p\"q,r1').encode(),
        r'WIFI:T:WPA;S:a\;b\:c;P:p\\\"q\,r1;;',
      );
    });
    test('WPA accepts a 64 digit hex key', () {
      expect(WifiPayload(ssid: 'x', password: 'a' * 64).validate(), isNull);
      expect(WifiPayload(ssid: 'x', password: 'g' * 64).validate(), isNotNull);
    });
    test('validation rules', () {
      expect(const WifiPayload(ssid: '').validate(), isNotNull);
      expect(
        const WifiPayload(ssid: 'x', password: 'short').validate(),
        isNotNull,
      );
      expect(const WifiPayload(ssid: 'x', password: '').validate(), isNotNull);
      expect(
        WifiPayload(ssid: 'a' * 33, password: '12345678').validate(),
        isNotNull,
      );
      expect(
        const WifiPayload(ssid: 'x', security: WifiSecurity.none).validate(),
        isNull,
      );
    });
  });
}
