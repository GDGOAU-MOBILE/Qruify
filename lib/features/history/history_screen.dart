import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../data/history_repository.dart';
import '../../services/app_services.dart';
import '../generator/qr_preview.dart';
import '../shared/confirm_sheet.dart';
import '../shared/type_icons.dart';

const _ink = Colors.black;
const _fill = Color(0xFFF2F2F7);
const _secondary = Color(0xFF6E6E73);
const _line = Color(0xFFE5E5EA);

/// Every code made so far, newest first. Search it, open one to share or copy
/// it again, or clear the lot.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _search = TextEditingController();
  String _query = '';
  Stream<List<HistoryEntry>>? _stream;
  String _streamQuery = '\u0000';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Stream<List<HistoryEntry>> _streamFor(BuildContext context) {
    if (_stream == null || _streamQuery != _query) {
      _streamQuery = _query;
      _stream = ServicesScope.of(context).history.watch(query: _query);
    }
    return _stream!;
  }

  Future<void> _confirmClear() async {
    final history = ServicesScope.of(context).history;
    final yes = await showConfirmSheet(
      context,
      title: 'Clear all history?',
      body: "Every saved code will be removed. This can't be undone.",
      action: 'Clear All History',
    );
    if (yes) await history.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: StreamBuilder<List<HistoryEntry>>(
          stream: _streamFor(context),
          builder: (context, snapshot) {
            final entries = snapshot.data ?? const <HistoryEntry>[];
            final loading = !snapshot.hasData;
            final searching = _query.trim().isNotEmpty;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      _Round(
                        icon: HugeIcons.strokeRoundedArrowLeft01,
                        label: 'Back',
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'History',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: _ink,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.8,
                              ),
                        ),
                      ),
                      if (entries.isNotEmpty && !searching)
                        _Round(
                          icon: HugeIcons.strokeRoundedDelete02,
                          label: 'Clear all',
                          onTap: _confirmClear,
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                    textInputAction: TextInputAction.search,
                    cursorColor: _ink,
                    decoration: InputDecoration(
                      hintText: 'Search',
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
                Expanded(
                  child: loading
                      ? const SizedBox.shrink()
                      : entries.isEmpty
                      ? _Empty(searching: searching)
                      : ListView.separated(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          itemCount: entries.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) => _EntryTile(
                            entry: entries[i],
                            onTap: () => _openDetail(entries[i]),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openDetail(HistoryEntry entry) {
    FocusManager.instance.primaryFocus?.unfocus();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) =>
          _DetailSheet(entry: entry, services: ServicesScope.of(context)),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, required this.onTap});

  final HistoryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _fill,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _line),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: ExcludeSemantics(
                      child: QrPreview(data: entry.content, style: entry.style),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        HugeIcon(
                          icon: iconForType(entry.type),
                          size: 16,
                          color: _secondary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${entry.type.label} · ${relativeDate(entry.createdAt)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _secondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
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

/// "Just now", "5 min ago", "Yesterday", or a short date.
String relativeDate(DateTime when, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final diff = n.difference(when);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(when.year, when.month, when.day);
  final days = today.difference(day).inDays;
  if (days == 0) return '${diff.inHours} h ago';
  if (days == 1) return 'Yesterday';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final base = '${when.day} ${months[when.month - 1]}';
  return when.year == n.year ? base : '$base ${when.year}';
}

class _Empty extends StatelessWidget {
  const _Empty({required this.searching});

  final bool searching;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: searching
                  ? HugeIcons.strokeRoundedSearch01
                  : HugeIcons.strokeRoundedQrCode,
              size: 44,
              color: const Color(0xFFB0B0B5),
            ),
            const SizedBox(height: 14),
            Text(
              searching ? 'Nothing matches' : 'No codes yet',
              style: const TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              searching
                  ? 'Try a different word.'
                  : 'Codes you make show up here.',
              style: const TextStyle(color: _secondary, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSheet extends StatefulWidget {
  const _DetailSheet({required this.entry, required this.services});

  final HistoryEntry entry;
  final AppServices services;

  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  final _shareKey = GlobalKey();
  bool _copied = false;
  bool _sharing = false;
  String? _problem;

  HistoryEntry get _e => widget.entry;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _e.content));
    if (!mounted) return;
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _share() async {
    final box = _shareKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    setState(() {
      _sharing = true;
      _problem = null;
    });
    try {
      final png = await widget.services.export.renderPng(_e.content, _e.style);
      await widget.services.export.sharePng(png, sharePositionOrigin: origin);
    } catch (_) {
      if (mounted) {
        setState(() => _problem = 'Could not share the code. Try again.');
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _delete() async {
    final nav = Navigator.of(context);
    await widget.services.history.delete(_e.id);
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: AspectRatio(
              aspectRatio: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _line),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(23),
                  child: Semantics(
                    label: 'QR code for ${_e.title}',
                    child: QrPreview(data: _e.content, style: _e.style),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _e.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_e.type.label} · ${relativeDate(_e.createdAt)}',
            style: const TextStyle(color: _secondary, fontSize: 15),
          ),
          if (_problem != null) ...[
            const SizedBox(height: 10),
            Text(_problem!, style: const TextStyle(color: Color(0xFFD70015))),
          ],
          const SizedBox(height: 20),
          SizedBox(
            key: _shareKey,
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: _sharing ? null : _share,
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedShare08,
                size: 20,
                color: Colors.white,
              ),
              label: const Text('Share'),
              style: FilledButton.styleFrom(
                backgroundColor: _ink,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFD1D1D6),
                disabledForegroundColor: Colors.white,
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _copy,
                    icon: HugeIcon(
                      icon: _copied
                          ? HugeIcons.strokeRoundedTick02
                          : HugeIcons.strokeRoundedCopy01,
                      size: 20,
                      color: _ink,
                    ),
                    label: Text(_copied ? 'Copied' : 'Copy'),
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
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _delete,
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedDelete02,
                      size: 20,
                      color: Color(0xFFD70015),
                    ),
                    label: const Text('Delete'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _fill,
                      foregroundColor: const Color(0xFFD70015),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Round extends StatelessWidget {
  const _Round({required this.icon, required this.label, required this.onTap});

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
