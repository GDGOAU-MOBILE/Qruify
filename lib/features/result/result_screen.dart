import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../data/history_repository.dart';
import '../../services/app_services.dart';
import '../generator/qr_preview.dart';
import '../shared/type_icons.dart';

const _ink = Colors.black;
const _fill = Color(0xFFF2F2F7);
const _secondary = Color(0xFF6E6E73);

/// The finished code: big, with what it holds, and the two things people do
/// next, share it or copy what it says.
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.entry});

  final HistoryEntry entry;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _shareKey = GlobalKey();
  bool _copied = false;
  bool _sharing = false;
  String? _problem;

  HistoryEntry get _entry => widget.entry;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _entry.content));
    if (!mounted) return;
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _share() async {
    final export = ServicesScope.of(context).export;
    // iPad needs to know where the share sheet should point.
    final box = _shareKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    setState(() {
      _sharing = true;
      _problem = null;
    });
    try {
      final png = await export.renderPng(_entry.content, _entry.style);
      await export.sharePng(png, sharePositionOrigin: origin);
    } catch (_) {
      if (mounted) {
        setState(() => _problem = 'Could not share the code. Try again.');
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowLeft01,
                      size: 24,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Your code',
                    style: text.titleLarge?.copyWith(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeOutCubic,
                        builder: (context, t, child) => Opacity(
                          opacity: t,
                          child: Transform.scale(
                            scale: 0.92 + 0.08 * t,
                            child: child,
                          ),
                        ),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: const Color(0xFFE5E5EA),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(27),
                              child: Semantics(
                                label: 'QR code for ${_entry.title}',
                                child: QrPreview(
                                  data: _entry.content,
                                  style: _entry.style,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      HugeIcon(
                        icon: iconForType(_entry.type),
                        size: 18,
                        color: _secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _entry.type.label,
                        style: const TextStyle(color: _secondary, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _entry.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.headlineSmall?.copyWith(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _entry.content,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    style: const TextStyle(color: _secondary, fontSize: 15),
                  ),
                  if (_problem != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _problem!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFD70015)),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                children: [
                  SizedBox(
                    key: _shareKey,
                    width: double.infinity,
                    height: 58,
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
                  SizedBox(
                    width: double.infinity,
                    height: 58,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
