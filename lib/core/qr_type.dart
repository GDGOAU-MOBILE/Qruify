/// The kinds of content a QR code can hold.
///
/// Stored by name in the database, so do not rename values.
enum QrType {
  url('Link'),
  text('Text'),
  email('Email'),
  phone('Phone'),
  wifi('Wi-Fi');

  const QrType(this.label);

  /// Default display name. The UI is free to ignore it.
  final String label;
}
