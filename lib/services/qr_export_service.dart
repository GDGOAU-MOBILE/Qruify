import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../core/qr_drawing.dart';
import '../core/qr_style.dart';

/// Turns QR content into PNG images, saves them and shares them.
class QrExportService {
  QrExportService({Future<Directory> Function()? saveDirectory})
    : _saveDirectory = saveDirectory ?? _defaultSaveDirectory;

  final Future<Directory> Function() _saveDirectory;

  /// Blank border around the code, in modules. The QR standard asks for 4 so
  /// scanners can find the edges.
  static const int quietZoneModules = 4;

  static Future<Directory> _defaultSaveDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'Qruify'));
  }

  /// Draws [data] as a square PNG with the colors from [style]. Works offline
  /// and does not touch the disk.
  ///
  /// Every module gets a whole number of pixels, which keeps edges sharp and
  /// scans reliably. So the image is the largest square not bigger than
  /// [size] that fits that rule (never smaller than one pixel per module).
  /// Throws an [ArgumentError] when [data] cannot fit in a QR code.
  Future<Uint8List> renderPng(
    String data,
    QrStyle style, {
    int size = 1024,
  }) async {
    final QrImage matrix;
    try {
      matrix = QrImage(
        QrCode.fromData(
          data: data,
          errorCorrectLevel: style.effectiveErrorLevel.qrValue,
        ),
      );
    } catch (_) {
      throw ArgumentError.value(data, 'data', 'Too long for a QR code.');
    }

    final modules = matrix.moduleCount;
    final totalModules = modules + quietZoneModules * 2;
    final pixelsPerModule = math.max(1, size ~/ totalModules);
    final side = totalModules * pixelsPerModule;

    // The logo decodes in the background; wait for it so it is in the image.
    await style.logo?.ready;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, side.toDouble(), side.toDouble()),
      Paint()..color = style.background,
    );
    // Same drawing as the on screen preview, so what is shared matches it.
    final offset = (quietZoneModules * pixelsPerModule).toDouble();
    paintQr(
      canvas,
      matrix,
      style,
      origin: Offset(offset, offset),
      cell: pixelsPerModule.toDouble(),
    );
    final picture = recorder.endRecording();

    final image = await picture.toImage(side, side);
    picture.dispose();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) {
      throw StateError('Could not encode the QR code as a PNG.');
    }
    return bytes.buffer.asUint8List();
  }

  /// Writes [png] into the app's `Qruify` folder and returns the file.
  Future<File> savePng(Uint8List png, {String? fileName}) async {
    final dir = await _saveDirectory();
    await dir.create(recursive: true);
    final name = p.basename(
      fileName ?? 'qruify_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    final file = File(
      p.join(dir.path, name.endsWith('.png') ? name : '$name.png'),
    );
    return file.writeAsBytes(png, flush: true);
  }

  /// Opens the system share sheet with the image.
  ///
  /// On iPad the share sheet needs an anchor, so pass [sharePositionOrigin]
  /// (for example the bounds of the Share button) or it will throw.
  Future<ShareResult> sharePng(
    Uint8List png, {
    String? text,
    Rect? sharePositionOrigin,
  }) {
    return SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(png, mimeType: 'image/png')],
        fileNameOverrides: ['qruify.png'],
        text: text,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }
}
