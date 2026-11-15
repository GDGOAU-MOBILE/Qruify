import 'package:flutter/widgets.dart';

import '../data/database.dart';
import '../data/history_repository.dart';
import '../data/settings_service.dart';
import '../features/generator/generator_controller.dart';
import 'logo_picker.dart';
import 'qr_export_service.dart';

/// Everything the screens depend on, created once at startup.
class AppServices {
  AppServices({
    required this.database,
    required this.settings,
    QrExportService? export,
    LogoPicker? logoPicker,
  }) : history = HistoryRepository(database),
       export = export ?? QrExportService(),
       logoPicker = logoPicker ?? GalleryLogoPicker();

  final AppDatabase database;
  final SettingsService settings;
  final HistoryRepository history;
  final QrExportService export;
  final LogoPicker logoPicker;

  /// Opens the on device database and loads saved settings.
  static Future<AppServices> create() async => AppServices(
    database: AppDatabase(),
    settings: await SettingsService.load(),
  );

  /// A fresh controller for the generator and customization screens.
  /// Create it once and share it between those screens.
  GeneratorController newGeneratorController() =>
      GeneratorController(history: history, settings: settings);

  Future<void> dispose() => database.close();
}

/// Makes [AppServices] reachable from any widget:
/// `ServicesScope.of(context).history`.
class ServicesScope extends InheritedWidget {
  const ServicesScope({
    super.key,
    required this.services,
    required super.child,
  });

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ServicesScope>();
    assert(scope != null, 'No ServicesScope found above this context.');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(ServicesScope oldWidget) =>
      services != oldWidget.services;
}
