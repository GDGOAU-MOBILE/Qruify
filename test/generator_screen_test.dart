import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qruify/data/database.dart';
import 'package:qruify/data/settings_service.dart';
import 'package:qruify/features/generator/generator_screen.dart';
import 'package:qruify/features/generator/qr_preview.dart';
import 'package:qruify/services/app_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppServices> _services() async {
  SharedPreferences.setMockInitialValues({});
  return AppServices(
    database: AppDatabase(NativeDatabase.memory()),
    settings: await SettingsService.load(),
  );
}

void _tallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

Widget _app(AppServices s) => ServicesScope(
  services: s,
  child: const MaterialApp(home: GeneratorScreen()),
);

FilledButton _generateButton(WidgetTester tester) =>
    tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Generate'));

void main() {
  testWidgets('empty form: no preview, Generate disabled, no scolding', (
    tester,
  ) async {
    _tallScreen(tester);
    final s = await _services();
    addTearDown(s.dispose);
    await tester.pumpWidget(_app(s));
    expect(find.byType(QrPreview), findsNothing);
    expect(find.text('Your code appears here'), findsOneWidget);
    expect(_generateButton(tester).onPressed, isNull);
    expect(find.text('Enter a link.'), findsNothing);
  });

  testWidgets('typing a link shows the code and enables Generate', (
    tester,
  ) async {
    _tallScreen(tester);
    final s = await _services();
    addTearDown(s.dispose);
    await tester.pumpWidget(_app(s));
    await tester.enterText(find.byType(TextField), 'example.com');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(QrPreview), findsOneWidget);
    expect(_generateButton(tester).onPressed, isNotNull);
  });

  testWidgets('the type is detected as you type, no picking needed', (
    tester,
  ) async {
    _tallScreen(tester);
    final s = await _services();
    addTearDown(s.dispose);
    await tester.pumpWidget(_app(s));
    expect(find.textContaining('Detected'), findsNothing);
    for (final (input, label) in [
      ('example.com', 'Link'),
      ('me@example.com', 'Email'),
      ('+1 555 123 4567', 'Phone'),
      ('hello there', 'Text'),
    ]) {
      await tester.enterText(find.byType(TextField), input);
      await tester.pump();
      expect(find.text('Detected: $label'), findsOneWidget, reason: input);
    }
  });

  testWidgets('input that cannot fit explains itself and keeps Generate off', (
    tester,
  ) async {
    _tallScreen(tester);
    final s = await _services();
    addTearDown(s.dispose);
    await tester.pumpWidget(_app(s));
    await tester.enterText(find.byType(TextField), 'a' * 1400);
    await tester.pump();
    expect(find.text('This is too long for a QR code.'), findsOneWidget);
    expect(_generateButton(tester).onPressed, isNull);
  });

  testWidgets('Wi-Fi has its own form, and Smart brings the input back', (
    tester,
  ) async {
    _tallScreen(tester);
    final s = await _services();
    addTearDown(s.dispose);
    await tester.pumpWidget(_app(s));
    await tester.enterText(find.byType(TextField), 'example.com');
    await tester.tap(find.text('Wi-Fi'));
    await tester.pump();
    expect(find.text('Network name'), findsOneWidget);
    expect(find.text('Security'), findsOneWidget);
    expect(find.text('Hidden network'), findsOneWidget);
    await tester.tap(find.text('Smart'));
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'example.com',
    );
  });

  testWidgets('Generate turns the same screen into the result, no new page', (
    tester,
  ) async {
    _tallScreen(tester);
    final s = await _services();
    addTearDown(s.dispose);
    await tester.pumpWidget(_app(s));
    await tester.enterText(find.byType(TextField), 'example.com');
    await tester.pump();
    await tester.tap(find.text('Generate'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
    // Same screen: the buttons and header changed, nothing was pushed.
    expect(find.byType(GeneratorScreen), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Generate'), findsNothing);
    expect(find.text('Your code'), findsOneWidget);
    expect(find.text('https://example.com'), findsOneWidget);

    // Back returns to editing, with what was typed still there.
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Generate'), findsOneWidget);
    expect(find.text('Copy'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'example.com',
    );
  });
}
