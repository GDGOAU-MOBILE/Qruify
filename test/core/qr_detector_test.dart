import 'package:flutter_test/flutter_test.dart';
import 'package:qruify/core/qr_detector.dart';
import 'package:qruify/core/qr_payload.dart';
import 'package:qruify/core/qr_type.dart';

void main() {
  QrType d(String s) => QrDetector.detect(s);

  test('links', () {
    for (final s in [
      'https://example.com',
      'http://example.com/a?b=1',
      'example.com',
      'www.example.com',
      'sub.example.co.uk/path',
      'example.com:8080/x',
      'localhost:3000',
      '  example.com  ',
    ]) {
      expect(d(s), QrType.url, reason: s);
    }
  });

  test('emails', () {
    for (final s in [
      'me@example.com',
      'first.last+tag@sub.example.org',
      'mailto:me@example.com',
    ]) {
      expect(d(s), QrType.email, reason: s);
    }
  });

  test('phone numbers', () {
    for (final s in [
      '+1 555 123 4567',
      '(555) 123-4567',
      '555.123.4567',
      'tel:+15551234567',
      '+234 801 234 5678',
      '+441',
    ]) {
      expect(d(s), QrType.phone, reason: s);
    }
  });

  test('everything else is text', () {
    for (final s in [
      '',
      '   ',
      'hello world',
      '2025',
      '12345',
      'Meet at 5pm.',
      'v1.2.3',
      'not a link',
      'WIFI:T:WPA;S:Net;P:password;;',
      'Dr. Smith',
    ]) {
      expect(d(s), QrType.text, reason: s);
    }
  });

  test('an email wins over a link', () {
    expect(d('me@example.com'), QrType.email);
  });

  test('payloads are built from the detected type', () {
    expect(
      QrDetector.payloadFor('example.com').encode(),
      'https://example.com',
    );
    expect(
      QrDetector.payloadFor('mailto:me@example.com').encode(),
      'mailto:me@example.com',
    );
    expect(
      QrDetector.payloadFor('+1 (555) 123-4567').encode(),
      'tel:+15551234567',
    );
    expect(QrDetector.payloadFor('hello there'), isA<TextPayload>());
    expect(QrDetector.payloadFor('tel:+15551234567').validate(), isNull);
  });
}
