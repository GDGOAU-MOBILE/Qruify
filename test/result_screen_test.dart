import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qruify/core/qr_style.dart';
import 'package:qruify/core/qr_type.dart';
import 'package:qruify/data/database.dart';
import 'package:qruify/data/history_repository.dart';
import 'package:qruify/data/settings_service.dart';
import 'package:qruify/features/generator/qr_preview.dart';
import 'package:qruify/features/result/result_screen.dart';
import 'package:qruify/services/app_services.dart';
import 'package:qruify/services/qr_export_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

class _FakeExport extends QrExportService {
  int shared = 0;
  bool fail = false;

  @override
  Future<Uint8List> renderPng(
    String data,
    QrStyle style, {
    int size = 1024,
  }) async {
    if (fail) throw StateError('no');
    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  Future<ShareResult> sharePng(
    Uint8List png, {
    String? text,
    Rect? sharePositionOrigin,
  }) async {
    shared++;
    return const ShareResult('', ShareResultStatus.success);
  }
}

final _entry = HistoryEntry(
  id: 1,
  type: QrType.url,
  content: 'https://example.com',
  title: 'example.com',
  style: QrStyle.standard,
  createdAt: DateTime(2026, 1, 1),
);

Future<(AppServices, _FakeExport)> _setup() async {
  SharedPreferences.setMockInitialValues({});
  final export = _FakeExport();
  final s = AppServices(
    database: AppDatabase(NativeDatabase.memory()),
    settings: await SettingsService.load(),
    export: export,
  );
  return (s, export);
}

void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

Widget _app(AppServices s) => ServicesScope(
  services: s,
  child: MaterialApp(home: ResultScreen(entry: _entry)),
);

void main() {
  testWidgets('shows the code and what it holds', (tester) async {
    _tall(tester);
    final (s, _) = await _setup();
    addTearDown(s.dispose);
    await tester.pumpWidget(_app(s));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(QrPreview), findsOneWidget);
    expect(find.text('Link'), findsOneWidget);
    expect(find.text('example.com'), findsOneWidget);
    expect(find.text('https://example.com'), findsOneWidget);
  });

  testWidgets('Copy puts the content on the clipboard and says so', (
    tester,
  ) async {
    _tall(tester);
    final (s, _) = await _setup();
    addTearDown(s.dispose);
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(_app(s));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Copy'));
    await tester.pump();
    expect(copied, 'https://example.com');
    expect(find.text('Copied'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Copy'), findsOneWidget);
  });

  testWidgets('Share renders the image and opens the share sheet', (
    tester,
  ) async {
    _tall(tester);
    final (s, export) = await _setup();
    addTearDown(s.dispose);
    await tester.pumpWidget(_app(s));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(export.shared, 1);
    expect(find.textContaining('Could not share'), findsNothing);
  });

  testWidgets('a failed share says so instead of failing silently', (
    tester,
  ) async {
    _tall(tester);
    final (s, export) = await _setup();
    addTearDown(s.dispose);
    export.fail = true;
    await tester.pumpWidget(_app(s));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(find.text('Could not share the code. Try again.'), findsOneWidget);
    expect(export.shared, 0);
  });
}
