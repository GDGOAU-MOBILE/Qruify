import 'package:csv/csv.dart';
import 'package:drift/drift.dart';

import 'database.dart';

/// The result of verifying a scanned QR code against the guest list.
enum CheckInResultType {
  /// The code was found in the list and marked as checked in.
  approved,

  /// The code was found, but it was already checked in earlier.
  alreadyCheckedIn,

  /// The code was not found in the guest list.
  notFound,
}

class CheckInResult {
  const CheckInResult({
    required this.type,
    required this.scannedCode,
    this.guest,
  });

  final CheckInResultType type;
  final String scannedCode;
  final GuestEntry? guest;

  bool get isApproved => type == CheckInResultType.approved;
  bool get isAlreadyCheckedIn => type == CheckInResultType.alreadyCheckedIn;
  bool get isNotFound => type == CheckInResultType.notFound;
}

/// Manages imported guest list entries and check-in verifications.
class GuestRepository {
  GuestRepository(this._db);

  final AppDatabase _db;

  /// Watch all guests in the list.
  Stream<List<GuestEntry>> watch({String query = ''}) {
    final q = query.trim().toLowerCase();
    return _db.watchGuests().map((list) {
      if (q.isEmpty) return list;
      return list.where((g) {
        return g.name.toLowerCase().contains(q) ||
            g.code.toLowerCase().contains(q) ||
            g.extra.toLowerCase().contains(q);
      }).toList();
    });
  }

  /// Get current total count and checked-in count.
  Future<({int total, int checkedIn})> getStats() async {
    final all = await _db.getAllGuests();
    final checked = all.where((g) => g.isCheckedIn).length;
    return (total: all.length, checkedIn: checked);
  }

  /// Check a scanned code against the guest list.
  Future<CheckInResult> checkIn(String rawCode) async {
    final code = rawCode.trim();
    if (code.isEmpty) {
      return CheckInResult(
        type: CheckInResultType.notFound,
        scannedCode: rawCode,
      );
    }

    final all = await _db.getAllGuests();
    GuestEntry? match;
    for (final g in all) {
      if (g.code == code) {
        match = g;
        break;
      }
    }
    // Case-insensitive fallback if exact match wasn't found
    if (match == null) {
      final lower = code.toLowerCase();
      for (final g in all) {
        if (g.code.toLowerCase() == lower) {
          match = g;
          break;
        }
      }
    }

    if (match == null) {
      return CheckInResult(
        type: CheckInResultType.notFound,
        scannedCode: code,
      );
    }

    if (match.isCheckedIn) {
      return CheckInResult(
        type: CheckInResultType.alreadyCheckedIn,
        scannedCode: code,
        guest: match,
      );
    }

    final now = DateTime.now();
    await _db.setCheckInStatus(match.id, true, now);
    final updated = match.copyWith(
      isCheckedIn: true,
      checkedInAt: Value(now),
    );
    return CheckInResult(
      type: CheckInResultType.approved,
      scannedCode: code,
      guest: updated,
    );
  }

  /// Manually mark a guest as checked in.
  Future<void> manualCheckIn(int id) =>
      _db.setCheckInStatus(id, true, DateTime.now());

  /// Revert check-in back to pending.
  Future<void> undoCheckIn(int id) => _db.setCheckInStatus(id, false, null);

  /// Delete one guest.
  Future<int> deleteGuest(int id) => _db.deleteGuest(id);

  /// Clear the entire guest list.
  Future<int> clear() => _db.clearGuests();

  /// Parse and import a CSV string into the database.
  /// Replaces the current guest list.
  Future<int> importCsv(String csvContent) async {
    final trimmed = csvContent.trim();
    if (trimmed.isEmpty) return 0;

    final rows = csv.decode(trimmed);
    if (rows.isEmpty) return 0;

    // Detect header row if present
    final firstRow = rows.first.map((e) => e.toString().trim()).toList();
    var hasHeader = false;
    var codeCol = 0;
    var nameCol = -1;
    var extraCol = -1;

    for (var i = 0; i < firstRow.length; i++) {
      final header = firstRow[i].toLowerCase();
      if (header == 'code' ||
          header == 'id' ||
          header == 'ticket' ||
          header == 'qr' ||
          header == 'token' ||
          header == 'uuid') {
        codeCol = i;
        hasHeader = true;
      } else if (header == 'name' ||
          header == 'full name' ||
          header == 'fullname' ||
          header == 'guest' ||
          header == 'attendee') {
        nameCol = i;
        hasHeader = true;
      } else if (header == 'extra' ||
          header == 'email' ||
          header == 'category' ||
          header == 'type' ||
          header == 'role') {
        extraCol = i;
        hasHeader = true;
      }
    }

    // Default column mappings if no header row was detected
    if (!hasHeader) {
      codeCol = 0;
      if (firstRow.length > 1) nameCol = 1;
      if (firstRow.length > 2) extraCol = 2;
    } else {
      if (nameCol == -1 && firstRow.length > 1) {
        nameCol = (codeCol == 0) ? 1 : 0;
      }
    }

    final dataRows = hasHeader ? rows.skip(1) : rows;
    final entries = <GuestEntriesCompanion>[];

    for (final row in dataRows) {
      if (row.isEmpty) continue;
      final code = (codeCol < row.length ? row[codeCol].toString() : '').trim();
      if (code.isEmpty) continue;

      final name = (nameCol >= 0 && nameCol < row.length
              ? row[nameCol].toString()
              : '')
          .trim();

      String extra = '';
      if (extraCol >= 0 && extraCol < row.length) {
        extra = row[extraCol].toString().trim();
      } else if (row.length > 2 && !hasHeader) {
        extra = row.skip(2).map((e) => e.toString().trim()).join(' · ');
      }

      entries.add(
        GuestEntriesCompanion.insert(
          code: code,
          name: Value(name),
          extra: Value(extra),
        ),
      );
    }

    if (entries.isEmpty) return 0;

    await _db.clearGuests();
    await _db.insertGuests(entries);
    return entries.length;
  }

  /// Export the current list and check-in statuses to CSV format.
  Future<String> exportCsv() async {
    final guests = await _db.getAllGuests();
    final rows = <List<dynamic>>[
      ['Code', 'Name', 'Extra', 'Status', 'CheckedInAt'],
      for (final g in guests)
        [
          g.code,
          g.name,
          g.extra,
          g.isCheckedIn ? 'Checked In' : 'Pending',
          g.checkedInAt?.toIso8601String() ?? '',
        ],
    ];
    return csv.encode(rows);
  }
}
