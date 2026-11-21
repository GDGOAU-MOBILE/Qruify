import 'dart:ui';

import 'package:qr_flutter/qr_flutter.dart' show QrImage;

import 'qr_logo.dart';
import 'qr_style.dart';

/// Draws the dark modules of [qr], and the logo if the style has one, with the
/// top left module at [origin] and each module [cell] pixels wide.
///
/// The caller fills the background first. Preview and export both use this, so
/// what the user sees is exactly what gets shared. Pass a whole number for
/// [cell] and [origin] to keep every edge sharp.
void paintQr(
  Canvas canvas,
  QrImage qr,
  QrStyle style, {
  required Offset origin,
  required double cell,
}) {
  final logoImage = style.logo?.image.value;
  // No picture yet (or it failed to decode): draw a plain code, with no gap.
  final plan = logoImage == null ? null : LogoPlan.forModules(qr.moduleCount);

  final modules = Path();
  for (var row = 0; row < qr.moduleCount; row++) {
    for (var col = 0; col < qr.moduleCount; col++) {
      if (!qr.isDark(row, col)) continue;
      if (plan != null && plan.covers(row, col)) continue;
      modules.addRect(
        Rect.fromLTWH(
          origin.dx + col * cell,
          origin.dy + row * cell,
          cell,
          cell,
        ),
      );
    }
  }
  canvas.drawPath(
    modules,
    Paint()
      ..color = style.foreground
      ..isAntiAlias = false,
  );

  if (plan == null || logoImage == null) return;

  final side = plan.logoModules * cell;
  final topLeft =
      origin +
      Offset((plan.clearStart + 1) * cell, (plan.clearStart + 1) * cell);
  final target = topLeft & Size(side, side);
  canvas.save();
  canvas.clipRRect(
    RRect.fromRectAndRadius(target, Radius.circular(side * 0.16)),
  );
  canvas.drawImageRect(
    logoImage,
    Rect.fromLTWH(
      0,
      0,
      logoImage.width.toDouble(),
      logoImage.height.toDouble(),
    ),
    target,
    Paint()..filterQuality = FilterQuality.high,
  );
  canvas.restore();
}
