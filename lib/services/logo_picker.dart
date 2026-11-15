import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Lets the user choose a picture for the middle of a QR code. A separate
/// class so tests can answer without opening the photo library.
abstract class LogoPicker {
  /// The chosen picture's bytes, or null if the user backed out.
  Future<Uint8List?> pick();
}

/// Opens the phone's photo picker. It needs no permission on Android 13+ and
/// iOS 14+, because the system shows the picker itself.
class GalleryLogoPicker implements LogoPicker {
  GalleryLogoPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<Uint8List?> pick() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      // The logo ends up a few hundred pixels wide; no need for a full photo.
      maxWidth: 1024,
      maxHeight: 1024,
    );
    return file?.readAsBytes();
  }
}
