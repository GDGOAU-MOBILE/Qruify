import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// A logo drawn in the middle of a QR code.
///
/// Build it from PNG bytes (see [prepare]). The picture decodes in the
/// background; [image] fills in when it is ready, and painters listen to it.
class QrLogo {
  QrLogo.fromPng(this.png) {
    ready = _decode();
  }

  /// The prepared square PNG.
  final Uint8List png;

  /// The decoded picture, or null until it is ready (or if it cannot decode).
  final ValueNotifier<ui.Image?> image = ValueNotifier<ui.Image?>(null);

  /// Completes when decoding has finished, successfully or not.
  late final Future<void> ready;

  Future<void> _decode() async {
    try {
      final codec = await ui.instantiateImageCodec(png);
      final frame = await codec.getNextFrame();
      image.value = frame.image;
    } catch (_) {
      // Leave it null: the code is drawn without a logo and without a gap.
    }
  }

  /// Turns any picture into a square PNG, cropped from the middle, so a
  /// wide photo or a tall banner both end up filling the logo space.
  static Future<Uint8List> prepare(Uint8List raw, {int size = 256}) async {
    final codec = await ui.instantiateImageCodec(raw);
    final frame = await codec.getNextFrame();
    final source = frame.image;
    final side = math.min(source.width, source.height).toDouble();
    final from = ui.Rect.fromLTWH(
      (source.width - side) / 2,
      (source.height - side) / 2,
      side,
      side,
    );
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawImageRect(
      source,
      from,
      ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      ui.Paint()..filterQuality = ui.FilterQuality.high,
    );
    final picture = recorder.endRecording();
    final out = await picture.toImage(size, size);
    picture.dispose();
    source.dispose();
    final bytes = await out.toByteData(format: ui.ImageByteFormat.png);
    out.dispose();
    if (bytes == null) throw StateError('Could not prepare the logo.');
    return bytes.buffer.asUint8List();
  }
}

/// How much room the logo gets, and which QR modules it replaces.
///
/// A QR code survives losing part of itself because of its error correction.
/// With the top level (H) a scanner can rebuild up to about 30% of the data.
/// A logo erases the modules under it, so the plan keeps that loss well inside
/// the budget:
///
/// * The logo, plus one module of clear space on every side, may cover at most
///   [maxCoveredFraction] of all modules (11%, about a third of what H can
///   repair).
/// * The logo is at most [maxWidthFraction] of the code's width.
/// * The cleared area stays at least [edgeMargin] modules from every edge, so
///   it never touches the three corner finder patterns or the format and
///   version information that sits beside them.
/// * The logo and its clear space are an odd number of modules, centered on
///   the odd sized module grid, so they sit exactly on module edges and
///   nothing is half covered.
///
/// Callers must also use the top error level while a logo is shown.
class LogoPlan {
  const LogoPlan._(this.moduleCount, this.logoModules);

  static const double maxCoveredFraction = 0.11;
  static const double maxWidthFraction = 0.20;

  /// Keeps the cleared area off the finder patterns (7 modules plus a
  /// separator) and the format information in row and column 8.
  static const int edgeMargin = 9;

  /// Smallest logo that is still recognizable. Below this there is no logo.
  static const int minLogoModules = 3;

  /// Modules per side of the whole QR code.
  final int moduleCount;

  /// Modules per side of the logo picture.
  final int logoModules;

  /// Modules per side of the area cleared of code: the logo plus clear space.
  int get clearModules => logoModules + 2;

  /// First module (row and column) of the cleared area.
  int get clearStart => (moduleCount - clearModules) ~/ 2;

  /// The share of all modules that the cleared area replaces.
  double get coveredFraction =>
      (clearModules * clearModules) / (moduleCount * moduleCount);

  /// True when the module at [row], [col] is under the logo or its clear space.
  bool covers(int row, int col) =>
      row >= clearStart &&
      row < clearStart + clearModules &&
      col >= clearStart &&
      col < clearStart + clearModules;

  /// The plan for a code with [moduleCount] modules per side, or null when the
  /// code is too small to carry a logo.
  static LogoPlan? forModules(int moduleCount) {
    final byWidth = maxWidthFraction * moduleCount;
    final byArea = math.sqrt(maxCoveredFraction) * moduleCount - 2;
    final byMargin = moduleCount - 2 * edgeMargin - 2;
    var logo = math.min(math.min(byWidth, byArea), byMargin.toDouble()).floor();
    if (logo.isEven) logo -= 1; // odd, so it centers on the odd grid
    if (logo < minLogoModules) return null;
    return LogoPlan._(moduleCount, logo);
  }
}
