import 'dart:ui';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qruify/core/qr_payload.dart';
import 'package:qruify/core/qr_style.dart';
import 'package:qruify/core/qr_type.dart';
import 'package:qruify/data/database.dart';
import 'package:qruify/data/history_repository.dart';

void main() {
  late AppDatabase db;
  late HistoryRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = HistoryRepository(db);
  });
  tearDown(() => db.close());

  test('add stores the encoded content and style', () async {
    const style = QrStyle(
      foreground: Color(0xFF112233),
      background: Color(0xFFEEEEEE),
      errorLevel: QrErrorLevel.high,
    );
    final entry = await repo.add(const UrlPayload('example.com'), style);
    expect(entry.type, QrType.url);
    expect(entry.content, 'https://example.com');
    expect(entry.title, 'example.com');
    expect(entry.style, style);
  });

  test('add rejects invalid payloads', () {
    expect(
      () => repo.add(const UrlPayload(''), QrStyle.standard),
      throwsArgumentError,
    );
  });

  test('watch is newest first and filters by query', () async {
    await repo.add(const TextPayload('first note'), QrStyle.standard);
    await repo.add(const PhonePayload('08012345678'), QrStyle.standard);

    final all = await repo.watch().first;
    expect(all.map((e) => e.type), [QrType.phone, QrType.text]);

    final filtered = await repo.watch(query: 'NOTE').first;
    expect(filtered.single.type, QrType.text);
  });

  test('delete and clear', () async {
    final a = await repo.add(const TextPayload('a'), QrStyle.standard);
    await repo.add(const TextPayload('b'), QrStyle.standard);
    await repo.delete(a.id);
    expect((await repo.watch().first).length, 1);
    await repo.clear();
    expect(await repo.watch().first, isEmpty);
  });
}
