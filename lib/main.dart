import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'services/app_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Shows the Geist font license on the app's licenses page.
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/Geist-OFL.txt');
    yield LicenseEntryWithLineBreaks(['Geist font'], text);
  });
  final services = await AppServices.create();
  runApp(ServicesScope(services: services, child: const QruifyApp()));
}
