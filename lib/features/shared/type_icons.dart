import 'package:hugeicons/hugeicons.dart';

import '../../core/qr_type.dart';

/// The icon for each kind of QR code, used wherever a type is shown.
List<List<dynamic>> iconForType(QrType type) => switch (type) {
  QrType.url => HugeIcons.strokeRoundedLink01,
  QrType.text => HugeIcons.strokeRoundedTextFont,
  QrType.email => HugeIcons.strokeRoundedMail01,
  QrType.phone => HugeIcons.strokeRoundedCall,
  QrType.wifi => HugeIcons.strokeRoundedWifi01,
};
