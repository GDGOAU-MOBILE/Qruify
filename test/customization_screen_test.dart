import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qruify/core/qr_style.dart';
import 'package:qruify/data/database.dart';
import 'package:qruify/data/settings_service.dart';
import 'package:qruify/features/customization/customization_screen.dart';
import 'package:qruify/features/generator/generator_controller.dart';
import 'package:qruify/features/generator/qr_preview.dart';
import 'package:qruify/services/app_services.dart';
import 'package:qruify/services/logo_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_logo.dart';

class _FakePicker implements LogoPicker {
  _FakePicker(this.result);
  final Uint8List? result;
  int calls = 0;

  @override
  Future<Uint8List?> pick() async {
    calls++;
    return result;
  }
}

Future<(AppServices, GeneratorController)> _setup(
  WidgetTester tester, {
  LogoPicker? picker,
  String? content,
}) async {
  tester.view.physicalSize = const Size(900, 3000);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final s = AppServices(
    database: AppDatabase(NativeDatabase.memory()),
    settings: await SettingsService.load(),
  );
  addTearDown(s.dispose);
  final c = s.newGeneratorController();
  addTearDown(c.dispose);
  if (content != null) c.setValue(GeneratorField.smart, content);
  await tester.pumpWidget(
    MaterialApp(
      home: CustomizationScreen(controller: c, picker: picker),
    ),
  );
  return (s, c);
}

/// Image decoding runs in real time while the widget code runs on the test's
/// fake clock, so alternate between waiting a little and pumping.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump();
  }
}

void main() {
  testWidgets('shows a preview, even with nothing typed yet', (tester) async {
    await _setup(tester);
    expect(find.byType(QrPreview), findsOneWidget);
    expect(find.text('Code color'), findsOneWidget);
    expect(find.text('Background'), findsOneWidget);
    expect(find.text('Error correction'), findsOneWidget);
  });

  testWidgets('picking a swatch changes the style', (tester) async {
    final (_, c) = await _setup(tester);
    await tester.tap(find.bySemanticsLabel('#0A2540'));
    await tester.pump();
    expect(c.style.foreground, const Color(0xFF0A2540));
    await tester.tap(find.bySemanticsLabel('#FFF7E6'));
    await tester.pump();
    expect(c.style.background, const Color(0xFFFFF7E6));
    expect(c.styleIsScannable, isTrue);
  });

  testWidgets('a typed hex color applies, a half typed one is ignored', (
    tester,
  ) async {
    final (_, c) = await _setup(tester);
    final codeField = find.byType(TextField).first;
    await tester.enterText(codeField, '12');
    await tester.pump();
    expect(c.style.foreground, QrStyle.standard.foreground);
    await tester.enterText(codeField, '1A73E8');
    await tester.pump();
    expect(c.style.foreground, const Color(0xFF1A73E8));
  });

  testWidgets('error correction can be changed and explains itself', (
    tester,
  ) async {
    final (_, c) = await _setup(tester);
    expect(find.text('Balanced. The default.'), findsOneWidget);
    await tester.tap(find.text('Max'));
    await tester.pump();
    expect(c.style.errorLevel, QrErrorLevel.high);
    expect(find.text('Most damage resistant. Bigger code.'), findsOneWidget);
  });

  testWidgets('colors that will not scan get a warning', (tester) async {
    final (_, c) = await _setup(tester);
    expect(find.textContaining('hard to scan'), findsNothing);
    await tester.enterText(find.byType(TextField).first, 'EEEEEE');
    await tester.pump();
    expect(c.styleIsScannable, isFalse);
    expect(find.textContaining('hard to scan'), findsOneWidget);
  });

  testWidgets('Reset brings back the standard style', (tester) async {
    final (_, c) = await _setup(tester);
    await tester.tap(find.bySemanticsLabel('#7A0019'));
    await tester.pump();
    expect(c.style, isNot(QrStyle.standard));
    await tester.tap(find.text('Reset'));
    await tester.pump();
    expect(c.style, QrStyle.standard);
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );
  });

  group('logo', () {
    testWidgets('adding one puts it on the code and forces Max', (
      tester,
    ) async {
      final raw = await real(tester, makeRawLogoPng);
      final picker = _FakePicker(raw);
      final (_, c) = await _setup(tester, picker: picker);
      expect(find.text('Add a logo'), findsOneWidget);

      await tester.tap(find.text('Add a logo'));
      await _settle(tester);

      expect(picker.calls, 1);
      expect(c.style.logo, isNotNull);
      expect(find.text('Logo added'), findsOneWidget);
      expect(c.style.effectiveErrorLevel, QrErrorLevel.high);
      expect(find.text('Most damage resistant. Bigger code.'), findsOneWidget);

      // The other levels are switched off while a logo is shown.
      await tester.tap(find.text('Low'));
      await tester.pump();
      expect(c.style.errorLevel, QrErrorLevel.medium);
      expect(c.style.effectiveErrorLevel, QrErrorLevel.high);
    });

    testWidgets('backing out of the picker changes nothing', (tester) async {
      final picker = _FakePicker(null);
      final (_, c) = await _setup(tester, picker: picker);
      await tester.tap(find.text('Add a logo'));
      await _settle(tester);
      expect(c.style.logo, isNull);
      expect(find.text('Add a logo'), findsOneWidget);
      expect(find.textContaining('could not be used'), findsNothing);
    });

    testWidgets('something that is not a picture says so', (tester) async {
      final picker = _FakePicker(Uint8List.fromList([1, 2, 3, 4]));
      final (_, c) = await _setup(tester, picker: picker);
      await tester.tap(find.text('Add a logo'));
      await _settle(tester);
      expect(c.style.logo, isNull);
      expect(find.textContaining('could not be used'), findsOneWidget);
    });

    testWidgets('Remove takes it off and brings the choices back', (
      tester,
    ) async {
      final raw = await real(tester, makeRawLogoPng);
      final (_, c) = await _setup(tester, picker: _FakePicker(raw));
      await tester.tap(find.text('Add a logo'));
      await _settle(tester);
      await tester.tap(find.text('Remove'));
      await tester.pump();
      expect(c.style.logo, isNull);
      expect(find.text('Add a logo'), findsOneWidget);
      await tester.tap(find.text('Low'));
      await tester.pump();
      expect(c.style.errorLevel, QrErrorLevel.low);
    });

    testWidgets('the smallest code has no room and says so', (tester) async {
      final raw = await real(tester, makeRawLogoPng);
      // Four letters make the smallest (version 1) code.
      await _setup(tester, picker: _FakePicker(raw), content: 'abcd');
      await tester.tap(find.text('Add a logo'));
      await _settle(tester);
      expect(find.textContaining('too small to hold a logo'), findsOneWidget);
    });

    testWidgets('Reset removes the logo too', (tester) async {
      final raw = await real(tester, makeRawLogoPng);
      final (_, c) = await _setup(tester, picker: _FakePicker(raw));
      await tester.tap(find.text('Add a logo'));
      await _settle(tester);
      await tester.tap(find.text('Reset'));
      await tester.pump();
      expect(c.style, QrStyle.standard);
    });
  });
}
