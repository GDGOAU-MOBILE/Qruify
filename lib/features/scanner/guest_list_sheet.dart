import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/database.dart';
import '../../services/app_services.dart';
import '../history/history_screen.dart' show relativeDate;
import '../shared/confirm_sheet.dart';

const _ink = Colors.black;
const _fill = Color(0xFFF2F2F7);
const _secondary = Color(0xFF6E6E73);
const _line = Color(0xFFE5E5EA);
const _green = Color(0xFF34C759);

/// Shows the loaded guest list, lets users search, import a new CSV,
/// export current check-in data, or manually toggle check-in status.
class GuestListSheet extends StatefulWidget {
  const GuestListSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const GuestListSheet(),
    );
  }

  @override
  State<GuestListSheet> createState() => _GuestListSheetState();
}

class _GuestListSheetState extends State<GuestListSheet> {
  final _search = TextEditingController();
  String _query = '';
  bool _importing = false;
  String? _message;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _pickCsvFile() async {
    setState(() {
      _importing = true;
      _message = null;
    });

    try {
      List<PlatformFile> files = [];
      try {
        files = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['csv', 'txt'],
        );
      } catch (e) {
        if (e is MissingPluginException) rethrow;
        // Fallback for devices where custom mime filters are unsupported
        files = await FilePicker.pickFiles(type: FileType.any);
      }

      if (files.isEmpty) return;

      final file = files.first;
      final content = await file.xFile.readAsString();

      if (!mounted) return;
      final count = await ServicesScope.of(context).guests.importCsv(content);
      if (mounted) {
        setState(() => _message = 'Successfully loaded $count entries.');
      }
    } on MissingPluginException {
      if (mounted) {
        setState(
          () => _message =
              'New plugin requires a full app restart. Stop and run "flutter run", or tap "Paste CSV" below.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _message = 'Failed to import CSV: $e');
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _pasteCsvSheet() async {
    final textController = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(ctx).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Paste CSV',
                    style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                          color: _ink,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                  ),
                ),
                _RoundIcon(
                  icon: HugeIcons.strokeRoundedCancel01,
                  label: 'Close',
                  onTap: () => Navigator.pop(ctx, false),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Paste comma-separated rows. Columns can be: Code, Name, Extra details.',
              style: TextStyle(color: _secondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              minLines: 4,
              maxLines: 7,
              autofocus: true,
              cursorColor: _ink,
              decoration: InputDecoration(
                hintText:
                    'TICK-101, Alice Smith, VIP\nTICK-102, Bob Jones, General',
                hintStyle: const TextStyle(color: Color(0xFFB0B0B5)),
                filled: true,
                fillColor: _fill,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _ink, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: _ink,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Import Entries'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: FilledButton.styleFrom(
                  backgroundColor: _fill,
                  foregroundColor: _ink,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );

    if (ok == true && textController.text.trim().isNotEmpty) {
      if (!mounted) return;
      final count = await ServicesScope.of(context).guests.importCsv(
            textController.text,
          );
      if (mounted) {
        setState(() => _message = 'Successfully loaded $count entries.');
      }
    }
  }

  Future<void> _exportCsv() async {
    final guests = ServicesScope.of(context).guests;
    final csv = await guests.exportCsv();
    await SharePlus.instance.share(
      ShareParams(
        text: csv,
        subject: 'Qruify Guest List Check-in Report',
      ),
    );
  }

  Future<void> _clearList() async {
    final ok = await showConfirmSheet(
      context,
      title: 'Clear guest list?',
      body: 'All imported guests and check-in records will be removed.',
      action: 'Clear List',
    );
    if (ok && mounted) {
      await ServicesScope.of(context).guests.clear();
      setState(() => _message = 'Guest list cleared.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final guestRepo = ServicesScope.of(context).guests;

    return StreamBuilder<List<GuestEntry>>(
      stream: guestRepo.watch(query: _query),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? const <GuestEntry>[];
        final total = entries.length;
        final checkedIn = entries.where((e) => e.isCheckedIn).length;
        final searching = _query.trim().isNotEmpty;

        return SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.88,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row matching HistoryScreen
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Row(
                  children: [
                    _RoundIcon(
                      icon: HugeIcons.strokeRoundedArrowLeft01,
                      label: 'Back',
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Guest List & Approver',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: _ink,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.8,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            total == 0
                                ? 'No list imported'
                                : '$checkedIn of $total checked in (${total > 0 ? (checkedIn * 100 ~/ total) : 0}%)',
                            style: TextStyle(
                              color: checkedIn > 0 ? _green : _secondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (total > 0 && !searching)
                      _RoundIcon(
                        icon: HugeIcons.strokeRoundedDelete02,
                        label: 'Clear list',
                        onTap: _clearList,
                      ),
                  ],
                ),
              ),

              // Chips Row matching UI Kit
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _Chip(
                        icon: HugeIcons.strokeRoundedFileImport,
                        label: _importing ? 'Loading...' : 'Import CSV',
                        selected: false,
                        onTap: _importing ? () {} : _pickCsvFile,
                      ),
                      const SizedBox(width: 8),
                      _Chip(
                        icon: HugeIcons.strokeRoundedText,
                        label: 'Paste CSV',
                        selected: false,
                        onTap: _pasteCsvSheet,
                      ),
                      if (total > 0) ...[
                        const SizedBox(width: 8),
                        _Chip(
                          icon: HugeIcons.strokeRoundedShare08,
                          label: 'Export',
                          selected: false,
                          onTap: _exportCsv,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              if (_message != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Text(
                    _message!,
                    style: const TextStyle(color: _green, fontSize: 13),
                  ),
                ),

              // Search Bar matching HistoryScreen
              if (total > 0 || searching)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                    textInputAction: TextInputAction.search,
                    cursorColor: _ink,
                    decoration: InputDecoration(
                      hintText: 'Search guests or codes...',
                      hintStyle: const TextStyle(color: Color(0xFFB0B0B5)),
                      filled: true,
                      fillColor: _fill,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(12),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedSearch01,
                          size: 20,
                          color: _secondary,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: _ink, width: 1.5),
                      ),
                    ),
                  ),
                ),

              // Guest List or Empty State
              Expanded(
                child: total == 0
                    ? _EmptyGuestList(
                        onImport: _pickCsvFile,
                        onPaste: _pasteCsvSheet,
                      )
                    : ListView.separated(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        itemCount: entries.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final guest = entries[index];
                          return _GuestTile(
                            guest: guest,
                            onToggleCheckIn: () {
                              if (guest.isCheckedIn) {
                                guestRepo.undoCheckIn(guest.id);
                              } else {
                                guestRepo.manualCheckIn(guest.id);
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GuestTile extends StatelessWidget {
  const _GuestTile({
    required this.guest,
    required this.onToggleCheckIn,
  });

  final GuestEntry guest;
  final VoidCallback onToggleCheckIn;

  @override
  Widget build(BuildContext context) {
    final checked = guest.isCheckedIn;
    return Material(
      color: _fill,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onToggleCheckIn,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: checked ? _ink : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: checked ? _ink : _line,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: checked
                        ? HugeIcons.strokeRoundedTick02
                        : HugeIcons.strokeRoundedClock01,
                    size: 20,
                    color: checked ? Colors.white : _secondary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guest.name.isNotEmpty ? guest.name : guest.code,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                        decoration: checked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            guest.name.isNotEmpty
                                ? '${guest.code}${guest.extra.isNotEmpty ? ' · ${guest.extra}' : ''}'
                                : guest.extra,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _secondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (checked && guest.checkedInAt != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '· ${relativeDate(guest.checkedInAt!)}',
                            style: const TextStyle(
                              color: _green,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyGuestList extends StatelessWidget {
  const _EmptyGuestList({
    required this.onImport,
    required this.onPaste,
  });

  final VoidCallback onImport;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedUserGroup,
              size: 48,
              color: Color(0xFFB0B0B5),
            ),
            const SizedBox(height: 14),
            const Text(
              'No Guest List Yet',
              style: TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Import a CSV of guest names or ticket codes. When you scan their QR codes, Qruify will approve and check them in.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _secondary, fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: FilledButton.icon(
                onPressed: onImport,
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedFileImport,
                  size: 20,
                  color: Colors.white,
                ),
                label: const Text('Choose CSV File'),
                style: FilledButton.styleFrom(
                  backgroundColor: _ink,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: FilledButton.icon(
                onPressed: onPaste,
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedText,
                  size: 20,
                  color: _ink,
                ),
                label: const Text('Paste CSV Text'),
                style: FilledButton.styleFrom(
                  backgroundColor: _fill,
                  foregroundColor: _ink,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: _fill,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: HugeIcon(icon: icon, size: 22, color: _ink),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final List<List<dynamic>>? icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : _ink;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? _ink : _fill,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  HugeIcon(icon: icon!, size: 18, color: fg),
                  const SizedBox(width: 8),
                ],
                ExcludeSemantics(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
