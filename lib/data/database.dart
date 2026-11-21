import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../core/qr_style.dart';
import '../core/qr_type.dart';

part 'database.g.dart';

class QrCodes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => textEnum<QrType>()();

  /// The exact string encoded in the QR code.
  TextColumn get content => text()();

  /// Short label shown in the history list.
  TextColumn get title => text().withDefault(const Constant(''))();

  /// Style options as ARGB ints, so a code can be redrawn the same way.
  IntColumn get foregroundColor =>
      integer().withDefault(const Constant(0xFF000000))();
  IntColumn get backgroundColor =>
      integer().withDefault(const Constant(0xFFFFFFFF))();

  IntColumn get errorLevel => integer()
      .map(const _ErrorLevelConverter())
      .withDefault(const Constant(1))();

  /// The logo drawn in the middle of the code, as PNG bytes. Null for none.
  BlobColumn get logo => blob().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// A guest or item imported from a CSV for QR scanning and verification.
class GuestEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The exact value to match when scanning the QR code.
  TextColumn get code => text()();

  /// Name or label of the guest or ticket.
  TextColumn get name => text().withDefault(const Constant(''))();

  /// Any extra details from the CSV (e.g. email, category, role).
  TextColumn get extra => text().withDefault(const Constant(''))();

  /// Whether this entry has been approved / checked in.
  BoolColumn get isCheckedIn => boolean().withDefault(const Constant(false))();

  /// The timestamp when the code was approved.
  DateTimeColumn get checkedInAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Stores [QrErrorLevel] by index. Append new levels at the end only.
class _ErrorLevelConverter extends TypeConverter<QrErrorLevel, int> {
  const _ErrorLevelConverter();

  @override
  QrErrorLevel fromSql(int fromDb) => QrErrorLevel.values[fromDb];

  @override
  int toSql(QrErrorLevel value) => value.index;
}

@DriftDatabase(tables: [QrCodes, GuestEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'qruify'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.addColumn(qrCodes, qrCodes.logo);
      if (from < 3) await m.createTable(guestEntries);
    },
  );

  Stream<List<QrCode>> watchHistory() =>
      (select(qrCodes)..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
          .watch();

  Future<int> addCode(QrCodesCompanion entry) => into(qrCodes).insert(entry);

  Future<int> clearHistory() => delete(qrCodes).go();

  Future<int> deleteCode(int id) =>
      (delete(qrCodes)..where((t) => t.id.equals(id))).go();

  Stream<List<GuestEntry>> watchGuests() =>
      (select(guestEntries)..orderBy([
            (t) => OrderingTerm.asc(t.isCheckedIn),
            (t) => OrderingTerm.asc(t.name),
            (t) => OrderingTerm.asc(t.code),
          ]))
          .watch();

  Future<List<GuestEntry>> getAllGuests() => select(guestEntries).get();

  Future<GuestEntry?> findGuestByCode(String code) =>
      (select(guestEntries)..where((t) => t.code.equals(code))).getSingleOrNull();

  Future<void> insertGuests(List<GuestEntriesCompanion> entries) =>
      batch((b) => b.insertAll(guestEntries, entries));

  Future<void> setCheckInStatus(int id, bool checkedIn, DateTime? time) =>
      (update(guestEntries)..where((t) => t.id.equals(id))).write(
        GuestEntriesCompanion(
          isCheckedIn: Value(checkedIn),
          checkedInAt: Value(time),
        ),
      );

  Future<int> clearGuests() => delete(guestEntries).go();

  Future<int> deleteGuest(int id) =>
      (delete(guestEntries)..where((t) => t.id.equals(id))).go();
}
