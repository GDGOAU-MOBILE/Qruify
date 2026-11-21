import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qruify/data/database.dart';
import 'package:qruify/data/guest_repository.dart';

void main() {
  late AppDatabase db;
  late GuestRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = GuestRepository(db);
  });

  tearDown(() => db.close());

  test('importCsv parses headers and maps columns accurately', () async {
    const csvData = '''
Code,Name,Extra
TCK-1001,Ada Lovelace,VIP Attendee
TCK-1002,Alan Turing,Speaker
TCK-1003,Grace Hopper,Organizer
''';

    final count = await repo.importCsv(csvData);
    expect(count, 3);

    final stats = await repo.getStats();
    expect(stats.total, 3);
    expect(stats.checkedIn, 0);

    final guests = await repo.watch().first;
    expect(guests.length, 3);
    expect(guests.any((g) => g.code == 'TCK-1001' && g.name == 'Ada Lovelace'), isTrue);
  });

  test('importCsv works with raw unheadered rows', () async {
    const rawCsv = '''
TICKET-A,John Doe,Table 1
TICKET-B,Jane Smith,Table 2
''';
    final count = await repo.importCsv(rawCsv);
    expect(count, 2);

    final guests = await repo.watch().first;
    expect(guests.any((g) => g.code == 'TICKET-A' && g.name == 'John Doe' && g.extra == 'Table 1'), isTrue);
    expect(guests.any((g) => g.code == 'TICKET-B' && g.name == 'Jane Smith' && g.extra == 'Table 2'), isTrue);
  });

  test('checkIn approves valid pending code and timestamps it', () async {
    await repo.importCsv('T-123,Margaret Hamilton,NASA\n');

    final result = await repo.checkIn('T-123');
    expect(result.type, CheckInResultType.approved);
    expect(result.isApproved, isTrue);
    expect(result.guest?.name, 'Margaret Hamilton');
    expect(result.guest?.isCheckedIn, isTrue);
    expect(result.guest?.checkedInAt, isNotNull);

    final stats = await repo.getStats();
    expect(stats.checkedIn, 1);
  });

  test('checkIn detects duplicate scans and flags alreadyCheckedIn', () async {
    await repo.importCsv('T-999,Linus Torvalds,Kernel');

    // First scan -> approved
    final first = await repo.checkIn('T-999');
    expect(first.type, CheckInResultType.approved);

    // Second scan -> duplicate warning
    final second = await repo.checkIn('T-999');
    expect(second.type, CheckInResultType.alreadyCheckedIn);
    expect(second.isAlreadyCheckedIn, isTrue);
    expect(second.guest?.name, 'Linus Torvalds');
  });

  test('checkIn flags notFound for unknown codes', () async {
    await repo.importCsv('VALID-1,Alice\n');

    final result = await repo.checkIn('UNKNOWN-CODE');
    expect(result.type, CheckInResultType.notFound);
    expect(result.isNotFound, isTrue);
    expect(result.guest, isNull);
  });

  test('undoCheckIn and manualCheckIn toggle status', () async {
    await repo.importCsv('CODE-1,Bob');
    final approved = await repo.checkIn('CODE-1');
    final guestId = approved.guest!.id;

    await repo.undoCheckIn(guestId);
    final statsAfterUndo = await repo.getStats();
    expect(statsAfterUndo.checkedIn, 0);

    await repo.manualCheckIn(guestId);
    final statsAfterManual = await repo.getStats();
    expect(statsAfterManual.checkedIn, 1);
  });

  test('exportCsv outputs updated check-in report', () async {
    await repo.importCsv('TCK-1,Alice,VIP');
    await repo.checkIn('TCK-1');

    final exported = await repo.exportCsv();
    expect(exported.contains('Code,Name,Extra,Status,CheckedInAt'), isTrue);
    expect(exported.contains('TCK-1'), isTrue);
    expect(exported.contains('Checked In'), isTrue);
  });
}
