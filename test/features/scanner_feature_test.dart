import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qruify/data/database.dart';
import 'package:qruify/data/settings_service.dart';
import 'package:qruify/features/generator/generator_screen.dart';
import 'package:qruify/features/scanner/guest_list_sheet.dart';
import 'package:qruify/services/app_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppServices> _services(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 2600);
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

Widget _app(AppServices s, Widget child) => ServicesScope(
      services: s,
      child: MaterialApp(home: child),
    );

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump();
  }
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 10));
}

void main() {
  testWidgets('scan FAB is visible above Generate', (tester) async {
    final s = await _services(tester);

    await tester.pumpWidget(_app(s, const GeneratorScreen()));
    await _settle(tester);

    // Verify the scan button exists and NO "NEW" badge is present
    expect(find.text('NEW'), findsNothing);
    expect(find.byKey(const Key('scan_button')), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Generate'), findsOneWidget);

    // Verify the scan button is positioned above Generate (y-coordinate is smaller)
    final scanFabCenter = tester.getCenter(find.byKey(const Key('scan_button')));
    final generateCenter = tester.getCenter(find.widgetWithText(FilledButton, 'Generate'));
    expect(scanFabCenter.dy, lessThan(generateCenter.dy));

    await _unmount(tester);
  });

  testWidgets('scan FAB is hidden in result view after Generate is pressed', (tester) async {
    final s = await _services(tester);

    await tester.pumpWidget(_app(s, const GeneratorScreen()));
    await _settle(tester);

    // Type valid content
    await tester.enterText(find.byType(TextField), 'https://example.com');
    await tester.pump(const Duration(milliseconds: 300));

    // Tap Generate
    await tester.tap(find.widgetWithText(FilledButton, 'Generate'));
    await tester.pumpAndSettle();

    // Now in result view -> scan button should be hidden
    expect(find.byKey(const Key('scan_button')), findsNothing);
    expect(find.text('NEW'), findsNothing);
    expect(find.text('Share'), findsOneWidget);

    await _unmount(tester);
  });

  testWidgets('GuestListSheet renders empty state and action options', (tester) async {
    final s = await _services(tester);

    await tester.pumpWidget(_app(s, const Scaffold(body: GuestListSheet())));
    await _settle(tester);

    expect(find.text('Guest List & Approver'), findsOneWidget);
    expect(find.text('No list imported'), findsOneWidget);
    expect(find.text('No Guest List Yet'), findsOneWidget);
    expect(find.text('Import CSV'), findsOneWidget);

    await _unmount(tester);
  });

  testWidgets('GuestListSheet displays loaded guests and supports toggle check in', (tester) async {
    final s = await _services(tester);

    // Seed guest data
    await s.guests.importCsv('T-1,Grace Hopper,VIP\nT-2,Ada Lovelace,Speaker');

    await tester.pumpWidget(_app(s, const Scaffold(body: GuestListSheet())));
    await _settle(tester);

    expect(find.text('0 of 2 checked in (0%)'), findsOneWidget);
    expect(find.text('Grace Hopper'), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsOneWidget);

    // Tap to manually check in Grace Hopper
    await tester.tap(find.text('Grace Hopper'));
    await _settle(tester);

    expect(find.text('1 of 2 checked in (50%)'), findsOneWidget);

    await _unmount(tester);
  });
}
