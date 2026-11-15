import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qruify/app.dart';
import 'package:qruify/features/splash/splash_screen.dart';
import 'package:qruify/data/database.dart';
import 'package:qruify/data/settings_service.dart';
import 'package:qruify/services/app_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('Geist')
      ..addFont(rootBundle.load('assets/fonts/Geist.ttf'));
    await loader.load();
  });

  testWidgets('splash, onboarding, then the generator screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final services = AppServices(
      database: AppDatabase(NativeDatabase.memory()),
      settings: await SettingsService.load(),
    );
    addTearDown(services.dispose);

    final field = await tester.runAsync(
      () => SplashField.prepare(const Size(800, 600), SplashField.qrFor()),
    );
    await tester.pumpWidget(
      ServicesScope(
        services: services,
        child: QruifyApp(splashFieldLoader: (_, _) async => field!),
      ),
    );
    await tester.pump(); // layout, then the particles arrive
    await tester.pump(const Duration(milliseconds: 20)); // warm-up frames
    await tester.pump(const Duration(milliseconds: 20));
    // The splash plays first, then the app fades to the Generator screen.
    expect(find.text('Create'), findsNothing);
    await tester.pump(const Duration(seconds: 6)); // animation ends
    await tester.pump(const Duration(seconds: 1)); // pause ends
    await tester.pump(const Duration(seconds: 3)); // onboarding animates in
    await tester.pump(const Duration(seconds: 2)); // button finishes fading in
    expect(find.text('Continue'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    expect(services.settings.onboardingDone, isTrue);
    expect(find.text('Create'), findsOneWidget);
  });

  testWidgets('returning users see the name, no particles, then the app', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'flutter.onboarding.done': true});
    final services = AppServices(
      database: AppDatabase(NativeDatabase.memory()),
      settings: await SettingsService.load(),
    );
    addTearDown(services.dispose);

    var loaderCalls = 0;
    await tester.pumpWidget(
      ServicesScope(
        services: services,
        child: QruifyApp(
          splashFieldLoader: (_, _) async {
            loaderCalls++;
            throw StateError('not needed');
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Create'), findsNothing);
    await tester.pump(const Duration(seconds: 2)); // animation ends
    await tester.pump(const Duration(milliseconds: 300)); // pause ends
    await tester.pumpAndSettle();
    expect(find.text('Create'), findsOneWidget);
    expect(loaderCalls, 0);
    expect(find.text('Continue'), findsNothing);
  });
}
