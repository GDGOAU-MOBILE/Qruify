import 'package:drift/drift.dart';
import 'package:flutter/painting.dart';

import '../core/qr_logo.dart';
import '../core/qr_payload.dart';
import '../core/qr_style.dart';
import '../core/qr_type.dart';
import 'database.dart';

/// A saved QR code, as the UI sees it.
class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.type,
    required this.content,
    required this.title,
    required this.style,
    required this.createdAt,
  });

  final int id;
  final QrType type;

  /// The exact string encoded in the QR code.
  final String content;
  final String title;
  final QrStyle style;
  final DateTime createdAt;

  /// Whether this entry matches a search [query] (case insensitive, on the
  /// title and content).
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return title.toLowerCase().contains(q) || content.toLowerCase().contains(q);
  }
}

/// Reads and writes the history of generated codes.
class HistoryRepository {
  HistoryRepository(this._db);

  final AppDatabase _db;

  // A logo is decoded once and reused every time the list refreshes.
  final Map<int, QrLogo> _logos = {};

  QrLogo? _logoFor(QrCode row) {
    final png = row.logo;
    if (png == null) return null;
    final cached = _logos[row.id];
    if (cached != null && cached.png.length == png.length) return cached;
    return _logos[row.id] = QrLogo.fromPng(png);
  }

  HistoryEntry _toEntry(QrCode row) => HistoryEntry(
    id: row.id,
    type: row.type,
    content: row.content,
    title: row.title,
    style: QrStyle(
      foreground: Color(row.foregroundColor),
      background: Color(row.backgroundColor),
      errorLevel: row.errorLevel,
      logo: _logoFor(row),
    ),
    createdAt: row.createdAt,
  );

  /// Newest first. Emits again whenever history changes. Pass a [query] to
  /// filter by title or content.
  Stream<List<HistoryEntry>> watch({String query = ''}) =>
      _db.watchHistory().map(
        (rows) => rows
            .map(_toEntry)
            .where((entry) => entry.matches(query))
            .toList(growable: false),
      );

  /// Saves a code. The payload must be valid.
  Future<HistoryEntry> add(QrPayload payload, QrStyle style) async {
    final error = payload.validate();
    if (error != null) {
      throw ArgumentError.value(payload, 'payload', error);
    }
    final id = await _db.addCode(
      QrCodesCompanion.insert(
        type: payload.type,
        content: payload.encode(),
        title: Value(payload.title),
        foregroundColor: Value(style.foreground.toARGB32()),
        backgroundColor: Value(style.background.toARGB32()),
        errorLevel: Value(style.errorLevel),
        logo: Value(style.logo?.png),
      ),
    );
    final row = await (_db.select(
      _db.qrCodes,
    )..where((t) => t.id.equals(id))).getSingle();
    return _toEntry(row);
  }

  Future<void> delete(int id) {
    _logos.remove(id);
    return _db.deleteCode(id);
  }

  Future<void> clear() {
    _logos.clear();
    return _db.clearHistory();
  }
}
