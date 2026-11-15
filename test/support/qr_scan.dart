import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

/// Reads a PNG the way a phone camera app would and returns the text.
/// Throws if no code can be read.
String scanPng(Uint8List png) {
  final image = img.decodePng(png)!;
  final pixels = image
      .convert(numChannels: 4)
      .getBytes(order: img.ChannelOrder.abgr)
      .buffer
      .asInt32List();
  final source = RGBLuminanceSource(image.width, image.height, pixels);
  final bitmap = BinaryBitmap(HybridBinarizer(source));
  return QRCodeReader().decode(bitmap).text;
}
