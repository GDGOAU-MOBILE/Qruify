import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qruify/core/qr_payload.dart';
import 'package:qruify/core/qr_style.dart';
import 'package:qruify/data/database.dart';
import 'package:qruify/data/history_repository.dart';
import 'package:qruify/data/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_logo.dart';

void main() {
  testWidgets('a saved code keeps its logo', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = HistoryRepository(db);
    final logo = await real(tester, makeLogo);

    final withLogo = await real(
      tester,
      () => repo.add(const UrlPayload('example.com'), QrStyle(logo: logo)),
    );
    final without = await real(
      tester,
      () => repo.add(const UrlPayload('example.org'), const QrStyle()),
    );

    expect(withLogo.style.logo, isNotNull);
    expect(withLogo.style.logo!.png, logo.png);
    expect(without.style.logo, isNull);

    // And it survives being read back from the database.
    final all = await real(tester, () => repo.watch().first);
    final saved = all.firstWhere((e) => e.content.contains('example.com'));
    expect(saved.style.logo!.png, logo.png);
    await real(tester, () => saved.style.logo!.ready);
    expect(saved.style.logo!.image.value, isNotNull);
  });

  testWidgets('the last used logo is remembered across launches', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await SettingsService.load();
    final logo = await real(tester, makeLogo);

    await settings.saveStyle(QrStyle(logo: logo));
    final loaded = settings.loadStyle();
    expect(loaded.logo, isNotNull);
    expect(loaded.logo!.png, logo.png);

    await settings.saveStyle(const QrStyle());
    expect(settings.loadStyle().logo, isNull);
  });

  testWidgets('a corrupt saved logo is ignored, not a crash', (tester) async {
    SharedPreferences.setMockInitialValues({
      'flutter.style.logo': '%%% not base64',
    });
    final settings = await SettingsService.load();
    expect(settings.loadStyle().logo, isNull);
  });
}
