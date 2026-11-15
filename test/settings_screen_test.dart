import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qruify/core/qr_payload.dart';
import 'package:qruify/core/qr_style.dart';
import 'package:qruify/data/database.dart';
import 'package:qruify/data/settings_service.dart';
import 'package:qruify/features/settings/settings_screen.dart';
import 'package:qruify/services/app_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppServices> _services(
  WidgetTester tester, [
  Map<String, Object> prefs = const {},
]) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final s = AppServices(
    database: AppDatabase(NativeDatabase.memory()),
    settings: await SettingsService.load(),
  );
  addTearDown(s.dispose);
  await tester.pumpWidget(
    ServicesScope(
      services: s,
      child: const MaterialApp(home: SettingsScreen()),
    ),
  );
  return s;
}

void main() {
  testWidgets('says the app is private and shows the version', (tester) async {
    await _services(tester);
    expect(find.text('Private by design'), findsOneWidget);
    expect(find.text('Qruify $appVersion'), findsOneWidget);
  });

  testWidgets('the welcome screen can be switched back on', (tester) async {
    final s = await _services(tester, {'flutter.onboarding.done': true});
    expect(s.settings.onboardingDone, isTrue);
    await tester.tap(find.text('Show the welcome screen again'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump();
    expect(s.settings.onboardingDone, isFalse);
    expect(find.textContaining('next time you open'), findsWidgets);
  });

  testWidgets('resetting the style asks first, then clears it', (tester) async {
    final s = await _services(tester);
    await tester.runAsync(
      () => s.settings.saveStyle(const QrStyle(foreground: Color(0xFF7A0019))),
    );
    expect(s.settings.loadStyle().foreground, const Color(0xFF7A0019));

    await tester.tap(find.text('Reset saved style'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(s.settings.loadStyle().foreground, const Color(0xFF7A0019));

    await tester.tap(find.text('Reset saved style'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset Style'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pumpAndSettle();
    expect(s.settings.loadStyle(), QrStyle.standard);
  });

  testWidgets('clearing history asks first, then empties it', (tester) async {
    final s = await _services(tester);
    await tester.runAsync(
      () => s.history.add(const TextPayload('abc'), QrStyle.standard),
    );
    await tester.tap(find.text('Clear history'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear All History'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    final left = await tester.runAsync(() => s.history.watch().first);
    expect(left, isEmpty);
    expect(find.text('History cleared.'), findsOneWidget);
  });
}
