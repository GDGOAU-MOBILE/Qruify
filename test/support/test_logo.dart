import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:qruify/core/qr_logo.dart';

/// A wide, colorful test picture (not square on purpose, to exercise the
/// center crop). Call inside `tester.runAsync`.
Future<Uint8List> makeRawLogoPng({int width = 300, int height = 180}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xFFE53935),
  );
  canvas.drawCircle(
    ui.Offset(width / 2, height / 2),
    height * 0.35,
    ui.Paint()..color = const ui.Color(0xFFFFFFFF),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

/// A ready to use logo. Call inside `tester.runAsync`.
Future<QrLogo> makeLogo() async {
  final logo = QrLogo.fromPng(await QrLogo.prepare(await makeRawLogoPng()));
  await logo.ready;
  return logo;
}

/// Runs async work in real time inside a widget test.
Future<T> real<T>(WidgetTester tester, Future<T> Function() body) async =>
    (await tester.runAsync(body)) as T;
