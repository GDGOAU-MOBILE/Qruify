import 'dart:ui';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qruify/core/qr_payload.dart';
import 'package:qruify/core/qr_style.dart';
import 'package:qruify/core/qr_type.dart';
import 'package:qruify/data/database.dart';
import 'package:qruify/data/history_repository.dart';
import 'package:qruify/data/settings_service.dart';
import 'package:qruify/features/generator/generator_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;
  late SettingsService settings;
  late GeneratorController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    settings = await SettingsService.load();
    controller = GeneratorController(
      history: HistoryRepository(db),
      settings: settings,
      autoDetect: false, // these tests cover the manual, per type mode
    );
  });
  tearDown(() => db.close());

  test('starts blank and invalid on the url type', () {
    expect(controller.type, QrType.url);
    expect(controller.hasInput, isFalse);
    expect(controller.isValid, isFalse);
    expect(controller.qrData, isNull);
  });

  test('qrData follows the input and notifies', () {
    var notified = 0;
    controller.addListener(() => notified++);
    controller.setValue(GeneratorField.url, 'example.com');
    expect(controller.qrData, 'https://example.com');
    expect(notified, 1);
    controller.setValue(GeneratorField.url, 'example.com'); // unchanged
    expect(notified, 1);
  });

  test('values survive switching type', () {
    controller.setValue(GeneratorField.url, 'example.com');
    controller.setType(QrType.text);
    expect(controller.hasInput, isFalse);
    controller.setType(QrType.url);
    expect(controller.valueOf(GeneratorField.url), 'example.com');
  });

  test('wifi options feed the payload', () {
    controller
      ..setType(QrType.wifi)
      ..setValue(GeneratorField.wifiSsid, 'Home')
      ..setWifiSecurity(WifiSecurity.none)
      ..setWifiHidden(true);
    expect(controller.qrData, 'WIFI:T:nopass;S:Home;H:true;;');
  });

  test('generate saves to history and rejects invalid input', () async {
    await expectLater(controller.generate(), throwsStateError);
    controller.setValue(GeneratorField.url, 'example.com');
    final entry = await controller.generate();
    expect(entry.content, 'https://example.com');
    expect((await HistoryRepository(db).watch().first).length, 1);
  });

  test('style is persisted', () async {
    const style = QrStyle(foreground: Color(0xFF0000FF));
    await controller.setStyle(style);
    expect(settings.loadStyle(), style);
  });

  group('auto detect', () {
    late GeneratorController auto;
    setUp(() {
      auto = GeneratorController(
        history: HistoryRepository(db),
        settings: settings,
      );
    });

    test('one input, the type follows what is typed', () {
      expect(auto.isAuto, isTrue);
      auto.setValue(GeneratorField.smart, 'example.com');
      expect(auto.type, QrType.url);
      expect(auto.qrData, 'https://example.com');
      auto.setValue(GeneratorField.smart, 'me@example.com');
      expect(auto.type, QrType.email);
      expect(auto.qrData, 'mailto:me@example.com');
      auto.setValue(GeneratorField.smart, '+1 555 123 4567');
      expect(auto.type, QrType.phone);
      expect(auto.qrData, 'tel:+15551234567');
      auto.setValue(GeneratorField.smart, 'just some words');
      expect(auto.type, QrType.text);
      expect(auto.qrData, 'just some words');
    });

    test('blank is invalid and not scolded', () {
      expect(auto.isValid, isFalse);
      expect(auto.hasInput, isFalse);
    });

    test('choosing Wi-Fi leaves auto mode, and it can come back', () {
      auto.setValue(GeneratorField.smart, 'example.com');
      auto.setType(QrType.wifi);
      expect(auto.isAuto, isFalse);
      expect(auto.type, QrType.wifi);
      auto.useAutoDetect();
      expect(auto.isAuto, isTrue);
      expect(auto.valueOf(GeneratorField.smart), 'example.com');
    });
  });
}
