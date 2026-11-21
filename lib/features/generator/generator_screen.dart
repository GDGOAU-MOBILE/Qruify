import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/qr_payload.dart';
import '../../core/qr_type.dart';
import '../../services/app_services.dart';
import '../customization/customization_screen.dart';
import '../history/history_screen.dart';
import '../scanner/scanner_screen.dart';
import '../settings/settings_screen.dart';
import '../../data/history_repository.dart';
import 'generator_controller.dart';
import '../shared/type_icons.dart';
import 'qr_preview.dart';

const _ink = Colors.black;
const _fieldFill = Color(0xFFF2F2F7);
const _secondary = Color(0xFF6E6E73);
const _error = Color(0xFFD70015);

/// Pick what the code holds, fill it in, watch the code appear, and generate.
class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  GeneratorController? _controller;
  final Map<GeneratorField, TextEditingController> _texts = {};
  bool _showPassword = false;
  bool _busy = false;

  /// Set once Generate is pressed. The same screen then shows the finished
  /// code in place: no new page, the controls just change.
  HistoryEntry? _result;
  final _shareKey = GlobalKey();
  bool _copied = false;
  bool _sharing = false;
  String? _problem;

  GeneratorController get _c => _controller!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= ServicesScope.of(context).newGeneratorController();
  }

  @override
  void dispose() {
    for (final t in _texts.values) {
      t.dispose();
    }
    _controller?.dispose();
    super.dispose();
  }

  TextEditingController _textFor(GeneratorField f) =>
      _texts.putIfAbsent(f, () => TextEditingController(text: _c.valueOf(f)));

  Future<void> _generate() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _busy = true);
    try {
      final entry = await _c.generate();
      if (!mounted) return;
      setState(() {
        _result = entry;
        _problem = null;
        _copied = false;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _backToEditing() => setState(() => _result = null);

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _result!.content));
    if (!mounted) return;
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _share() async {
    final entry = _result!;
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
      final png = await export.renderPng(entry.content, entry.style);
      await export.sharePng(png, sharePositionOrigin: origin);
    } catch (_) {
      if (mounted) {
        setState(() => _problem = 'Could not share the code. Try again.');
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _open(Widget screen) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _result == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToEditing();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _c,
            builder: (context, _) => Column(
              children: [
                Expanded(
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      _swap(
                        showSecond: _result != null,
                        first: _header(context),
                        second: _resultHeader(context),
                      ),
                      const SizedBox(height: 20),
                      _swap(
                        showSecond: _result != null,
                        first: _typeChips(),
                        second: const SizedBox(width: double.infinity),
                      ),
                      if (_result == null) const SizedBox(height: 20),
                      _preview(),
                      const SizedBox(height: 24),
                      _swap(
                        showSecond: _result != null,
                        first: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [..._fields(), _errorText()],
                        ),
                        second: _resultDetails(context),
                      ),
                    ],
                  ),
                ),
                _generateBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _fade = Duration(milliseconds: 320);

  /// Cross-fades between two layouts of different height, in place.
  Widget _swap({
    required bool showSecond,
    required Widget first,
    required Widget second,
  }) {
    return AnimatedCrossFade(
      duration: _fade,
      sizeCurve: Curves.easeOutCubic,
      firstCurve: Curves.easeOut,
      secondCurve: Curves.easeOut,
      alignment: Alignment.topCenter,
      crossFadeState: showSecond
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      firstChild: first,
      secondChild: second,
      layoutBuilder: (top, topKey, bottom, bottomKey) => Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(key: bottomKey, left: 0, right: 0, top: 0, child: bottom),
          Positioned(key: topKey, child: top),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Create',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
        ),
        _RoundIcon(
          icon: HugeIcons.strokeRoundedPaintBoard,
          label: 'Customize',
          onTap: () => _open(CustomizationScreen(controller: _c)),
        ),
        const SizedBox(width: 8),
        _RoundIcon(
          icon: HugeIcons.strokeRoundedClock01,
          label: 'History',
          onTap: () => _open(const HistoryScreen()),
        ),
        const SizedBox(width: 8),
        _RoundIcon(
          icon: HugeIcons.strokeRoundedSettings02,
          label: 'Settings',
          onTap: () => _open(const SettingsScreen()),
        ),
      ],
    );
  }

  Widget _resultHeader(BuildContext context) {
    return Row(
      children: [
        _RoundIcon(
          icon: HugeIcons.strokeRoundedArrowLeft01,
          label: 'Back',
          onTap: _backToEditing,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Your code',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ),
        _RoundIcon(
          icon: HugeIcons.strokeRoundedShare08,
          label: 'Export',
          onTap: _sharing ? () {} : _share,
        ),
      ],
    );
  }

  Widget _resultDetails(BuildContext context) {
    final entry = _result;
    if (entry == null) return const SizedBox(width: double.infinity);
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: iconForType(entry.type),
              size: 18,
              color: _secondary,
            ),
            const SizedBox(width: 8),
            Text(
              entry.type.label,
              style: const TextStyle(color: _secondary, fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          entry.title,
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
        Text(
          entry.content,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _secondary, fontSize: 15),
        ),
        if (_problem != null) ...[
          const SizedBox(height: 12),
          Text(
            _problem!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _error),
          ),
        ],
      ],
    );
  }

  /// Smart (one input, the type is detected) or Wi-Fi (needs a password and a
  /// security type, so it has its own form).
  Widget _typeChips() {
    return Row(
      children: [
        _Chip(
          icon: HugeIcons.strokeRoundedAiMagic,
          label: 'Smart',
          selected: _c.isAuto,
          onTap: _c.useAutoDetect,
        ),
        const SizedBox(width: 8),
        _Chip(
          icon: HugeIcons.strokeRoundedWifi01,
          label: 'Wi-Fi',
          selected: !_c.isAuto,
          onTap: () => _c.setType(QrType.wifi),
        ),
      ],
    );
  }

  Widget _preview() {
    final data = _result?.content ?? _c.qrData;
    final style = _result?.style ?? _c.style;
    return Center(
      child: ConstrainedBox(
        // Smaller while the keyboard is up, so the field and its status line
        // stay in view.
        constraints: BoxConstraints(
          maxWidth: MediaQuery.viewInsetsOf(context).bottom > 0 ? 170 : 300,
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: data == null ? _fieldFill : style.background,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE5E5EA)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(27),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: data == null
                    ? Center(
                        key: const ValueKey('empty'),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedQrCode,
                              size: 44,
                              color: Color(0xFFB0B0B5),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Your code appears here',
                              style: TextStyle(color: _secondary),
                            ),
                          ],
                        ),
                      )
                    : SizedBox.expand(
                        key: ValueKey(data),
                        child: QrPreview(data: data, style: style),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _fields() => _c.isAuto ? _smartFields() : _wifiFields();

  /// One input. Paste or type a link, email, phone number or any text.
  List<Widget> _smartFields() {
    final detected = _c.hasInput ? _c.type : null;
    return [
      _input(
        GeneratorField.smart,
        'Paste or type anything',
        hint: 'Link, email, phone number or text',
        keyboard: TextInputType.multiline,
        maxLines: 5,
      ),
      const SizedBox(height: 12),
      AnimatedSize(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.topLeft,
        child: detected == null
            ? const SizedBox(width: double.infinity)
            : Row(
                children: [
                  HugeIcon(
                    icon: iconForType(detected),
                    size: 18,
                    color: _secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Detected: ${detected.label}',
                    style: const TextStyle(color: _secondary, fontSize: 14),
                  ),
                ],
              ),
      ),
    ];
  }

  List<Widget> _wifiFields() {
    Widget gap() => const SizedBox(height: 16);
    return [
      _input(GeneratorField.wifiSsid, 'Network name'),
      gap(),
      _label('Security'),
      Row(
        children: [
          for (final s in WifiSecurity.values) ...[
            _Chip(
              label: switch (s) {
                WifiSecurity.wpa => 'WPA',
                WifiSecurity.wep => 'WEP',
                WifiSecurity.none => 'None',
              },
              selected: _c.wifiSecurity == s,
              onTap: () => _c.setWifiSecurity(s),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      if (_c.wifiSecurity != WifiSecurity.none) ...[
        gap(),
        _input(
          GeneratorField.wifiPassword,
          'Password',
          obscure: !_showPassword,
          suffix: IconButton(
            tooltip: _showPassword ? 'Hide password' : 'Show password',
            onPressed: () => setState(() => _showPassword = !_showPassword),
            icon: HugeIcon(
              icon: _showPassword
                  ? HugeIcons.strokeRoundedViewOff
                  : HugeIcons.strokeRoundedEye,
              size: 20,
              color: _secondary,
            ),
          ),
        ),
      ],
      gap(),
      Row(
        children: [
          const Expanded(
            child: Text('Hidden network', style: TextStyle(fontSize: 16)),
          ),
          Switch(
            value: _c.wifiHidden,
            onChanged: _c.setWifiHidden,
            activeThumbColor: Colors.white,
            activeTrackColor: _ink,
          ),
        ],
      ),
    ];
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(
      text,
      style: const TextStyle(
        color: _secondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _input(
    GeneratorField field,
    String label, {
    String? hint,
    TextInputType? keyboard,
    int maxLines = 1,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextField(
          controller: _textFor(field),
          onChanged: (v) => _c.setValue(field, v),
          keyboardType: keyboard,
          minLines: 1,
          maxLines: obscure ? 1 : maxLines,
          obscureText: obscure,
          autocorrect: false,
          enableSuggestions: false,
          cursorColor: _ink,
          style: const TextStyle(fontSize: 17),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFB0B0B5)),
            filled: true,
            fillColor: _fieldFill,
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
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
      ],
    );
  }

  Widget _errorText() {
    final error = _c.hasInput ? _c.validationError : null;
    final warn = !_c.styleIsScannable
        ? 'These colors may be hard to scan. Pick a darker code on a lighter background.'
        : null;
    final message = error ?? warn;
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 4),
      child: Text(
        message,
        style: TextStyle(
          color: error != null ? _error : _secondary,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _scanFab() {
    return Semantics(
      button: true,
      label: 'Scan QR code',
      child: Material(
        key: const Key('scan_button'),
        color: _ink,
        shape: const CircleBorder(),
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _open(const ScannerScreen()),
          child: const SizedBox(
            width: 56,
            height: 56,
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedCamera01,
                size: 24,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _generateBar() {
    final done = _result != null;
    final enabled = done ? !_sharing : _c.isValid && !_busy;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!done)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _scanFab(),
              ),
            ),
          SizedBox(
            key: _shareKey,
            width: double.infinity,
            height: 58,
            child: FilledButton(
              onPressed: enabled ? (done ? _share : _generate) : null,
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: done
                    ? const Row(
                        key: ValueKey('share'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedShare08,
                            size: 20,
                            color: Colors.white,
                          ),
                          SizedBox(width: 10),
                          Text('Share'),
                        ],
                      )
                    : const Text('Generate', key: ValueKey('generate')),
              ),
            ),
          ),
          AnimatedSize(
            duration: _fade,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: done
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SizedBox(
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
                          backgroundColor: _fieldFill,
                          foregroundColor: _ink,
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
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
        color: _fieldFill,
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
        color: selected ? _ink : _fieldFill,
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
