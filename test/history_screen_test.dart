import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qruify/core/qr_payload.dart';
import 'package:qruify/core/qr_style.dart';
import 'package:qruify/data/database.dart';
import 'package:qruify/data/settings_service.dart';
import 'package:qruify/features/history/history_screen.dart';
import 'package:qruify/services/app_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppServices> _services(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final s = AppServices(
    database: AppDatabase(NativeDatabase.memory()),
    settings: await SettingsService.load(),
  );
  addTearDown(s.dispose);
  return s;
}

Widget _app(AppServices s) => ServicesScope(
  services: s,
  child: const MaterialApp(home: HistoryScreen()),
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump();
  }
}

/// Drops the screen so drift's stream clean-up timer fires inside the test.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 10));
}

void main() {
  test('relativeDate reads naturally', () {
    final now = DateTime(2026, 11, 15, 12);
    expect(relativeDate(now, now: now), 'Just now');
    expect(
      relativeDate(now.subtract(const Duration(minutes: 5)), now: now),
      '5 min ago',
    );
    expect(
      relativeDate(now.subtract(const Duration(hours: 3)), now: now),
      '3 h ago',
    );
    expect(relativeDate(DateTime(2026, 11, 14, 20), now: now), 'Yesterday');
    expect(relativeDate(DateTime(2026, 3, 2), now: now), '2 Mar');
    expect(relativeDate(DateTime(2025, 3, 2), now: now), '2 Mar 2025');
  });

  testWidgets('empty history says so', (tester) async {
    final s = await _services(tester);
    await tester.pumpWidget(_app(s));
    await _settle(tester);
    expect(find.text('No codes yet'), findsOneWidget);
    expect(find.bySemanticsLabel('Clear all'), findsNothing);
    await _unmount(tester);
  });

  testWidgets('lists codes, searches, opens one, deletes it', (tester) async {
    final s = await _services(tester);
    await tester.runAsync(() async {
      await s.history.add(const UrlPayload('example.com'), QrStyle.standard);
      await s.history.add(const TextPayload('hello there'), QrStyle.standard);
    });
    await tester.pumpWidget(_app(s));
    await _settle(tester);
    expect(find.text('example.com'), findsOneWidget);
    expect(find.text('hello there'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'hello');
    await _settle(tester);
    expect(find.text('example.com'), findsNothing);
    expect(find.text('hello there'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzz');
    await _settle(tester);
    expect(find.text('Nothing matches'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '');
    await _settle(tester);
    await tester.tap(find.text('hello there'));
    await tester.pumpAndSettle();
    expect(find.text('Share'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await _settle(tester);
    await tester.pumpAndSettle();
    expect(find.text('hello there'), findsNothing);
    expect(find.text('example.com'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('Clear all asks first, then empties the list', (tester) async {
    final s = await _services(tester);
    await tester.runAsync(
      () => s.history.add(const TextPayload('abc'), QrStyle.standard),
    );
    await tester.pumpWidget(_app(s));
    await _settle(tester);
    await tester.tap(find.bySemanticsLabel('Clear all'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('abc'), findsOneWidget);

    // Dragging the sheet down cancels too.
    await tester.tap(find.bySemanticsLabel('Clear all'));
    await tester.pumpAndSettle();
    await tester.drag(find.text('Clear all history?'), const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.text('Clear all history?'), findsNothing);
    expect(find.text('abc'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Clear all'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear All History'));
    await _settle(tester);
    await tester.pumpAndSettle();
    expect(find.text('No codes yet'), findsOneWidget);
    await _unmount(tester);
  });
}
