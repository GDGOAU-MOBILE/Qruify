import 'dart:typed_data';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qruify/core/qr_style.dart';
import 'package:qruify/services/qr_export_service.dart';

void main() {
  testWidgets('renderPng returns a PNG of the requested size', (tester) async {
    final service = QrExportService();
    final bytes = await tester.runAsync(
      () =>
          service.renderPng('https://example.com', QrStyle.standard, size: 256),
    );
    expect(bytes!.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
  });

  test('savePng keeps odd file names inside the folder', () async {
    final dir = await Directory.systemTemp.createTemp('qruify_test');
    addTearDown(() => dir.delete(recursive: true));
    final service = QrExportService(
      saveDirectory: () async => Directory('${dir.path}/out'),
    );
    final file = await service.savePng(Uint8List(1), fileName: '../../evil');
    expect(file.parent.path, '${dir.path}/out');
    expect(file.path.endsWith('evil.png'), isTrue);
  });

  test('savePng writes the file into the chosen folder', () async {
    final dir = await Directory.systemTemp.createTemp('qruify_test');
    addTearDown(() => dir.delete(recursive: true));
    final service = QrExportService(
      saveDirectory: () async => Directory('${dir.path}/out'),
    );
    final file = await service.savePng(
      Uint8List.fromList([1, 2, 3]),
      fileName: 'code',
    );
    expect(file.path.endsWith('code.png'), isTrue);
    expect(await file.readAsBytes(), [1, 2, 3]);
  });
}
