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

/// Stores [QrErrorLevel] by index. Append new levels at the end only.
class _ErrorLevelConverter extends TypeConverter<QrErrorLevel, int> {
  const _ErrorLevelConverter();

  @override
  QrErrorLevel fromSql(int fromDb) => QrErrorLevel.values[fromDb];

  @override
  int toSql(QrErrorLevel value) => value.index;
}

@DriftDatabase(tables: [QrCodes])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'qruify'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.addColumn(qrCodes, qrCodes.logo);
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
}
