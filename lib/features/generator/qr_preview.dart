import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart' show QrCode, QrImage;

import '../../core/qr_drawing.dart';
import '../../core/qr_style.dart';

/// Draws [data] as a QR code, module by module on whole pixels so edges stay
/// sharp, with the 4 module quiet zone scanners need. Fills its parent, which
/// should be square.
class QrPreview extends StatelessWidget {
  const QrPreview({super.key, required this.data, required this.style});

  final String data;
  final QrStyle style;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _QrPreviewPainter(
        QrImage(
          QrCode.fromData(
            data: data,
            errorCorrectLevel: style.effectiveErrorLevel.qrValue,
          ),
        ),
        style,
      ),
    );
  }
}

class _QrPreviewPainter extends CustomPainter {
  _QrPreviewPainter(this.qr, this.style) : super(repaint: style.logo?.image);

  final QrImage qr;
  final QrStyle style;

  static const int _quiet = 4;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = style.background);
    final total = qr.moduleCount + _quiet * 2;
    final cell = (size.shortestSide / total).floorToDouble();
    final side = cell * total;
    final origin = Offset(
      ((size.width - side) / 2).roundToDouble() + _quiet * cell,
      ((size.height - side) / 2).roundToDouble() + _quiet * cell,
    );
    paintQr(canvas, qr, style, origin: origin, cell: cell);
  }

  @override
  bool shouldRepaint(_QrPreviewPainter old) =>
      old.style != style ||
      old.qr.moduleCount != qr.moduleCount ||
      _differs(old.qr, qr);

  static bool _differs(QrImage a, QrImage b) {
    if (identical(a, b)) return false;
    for (var r = 0; r < a.moduleCount; r++) {
      for (var c = 0; c < a.moduleCount; c++) {
        if (a.isDark(r, c) != b.isDark(r, c)) return true;
      }
    }
    return false;
  }
}
