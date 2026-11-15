import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'dart:typed_data';

import 'package:qr_flutter/qr_flutter.dart' show QrCode, QrErrorCorrectLevel;

import '../../core/hex_color.dart';
import '../../core/qr_logo.dart';
import '../../core/qr_style.dart';
import '../../services/app_services.dart';
import '../../services/logo_picker.dart';
import '../generator/generator_controller.dart';
import '../generator/qr_preview.dart';

const _ink = Colors.black;
const _fill = Color(0xFFF2F2F7);
const _secondary = Color(0xFF6E6E73);

const _codeColors = [
  Color(0xFF000000),
  Color(0xFF1C1C1E),
  Color(0xFF0A2540),
  Color(0xFF0B3D2E),
  Color(0xFF7A0019),
  Color(0xFF3B1F7A),
];

const _backgroundColors = [
  Color(0xFFFFFFFF),
  Color(0xFFF2F2F7),
  Color(0xFFFFF7E6),
  Color(0xFFE8F1FF),
  Color(0xFFFFE8EE),
  Color(0xFFE6F6EC),
];

const _levelInfo = {
  QrErrorLevel.low: ('Low', 'Smallest code. Fine on a screen.'),
  QrErrorLevel.medium: ('Medium', 'Balanced. The default.'),
  QrErrorLevel.quartile: ('High', 'Survives scuffs and small marks.'),
  QrErrorLevel.high: ('Max', 'Most damage resistant. Bigger code.'),
};

/// Colors and error correction for the code. Every change applies at once,
/// shows in the preview, and is remembered for next time.
class CustomizationScreen extends StatefulWidget {
  const CustomizationScreen({super.key, required this.controller, this.picker});

  final GeneratorController controller;

  /// Chooses the logo picture. Defaults to the phone's photo picker.
  final LogoPicker? picker;

  @override
  State<CustomizationScreen> createState() => _CustomizationScreenState();
}

class _CustomizationScreenState extends State<CustomizationScreen> {
  GeneratorController get _c => widget.controller;

  late final _codeHex = TextEditingController(text: hexOf(_c.style.foreground));
  late final _backgroundHex = TextEditingController(
    text: hexOf(_c.style.background),
  );

  bool _pickingLogo = false;
  String? _logoProblem;

  Future<void> _chooseLogo() async {
    final picker = widget.picker ?? ServicesScope.of(context).logoPicker;
    setState(() {
      _pickingLogo = true;
      _logoProblem = null;
    });
    try {
      final raw = await picker.pick();
      if (raw == null) return; // backed out
      final png = await QrLogo.prepare(raw);
      final logo = QrLogo.fromPng(png);
      await logo.ready;
      await _c.setStyle(_c.style.copyWith(logo: logo));
    } catch (_) {
      if (mounted) {
        setState(
          () => _logoProblem = 'That picture could not be used. Try another.',
        );
      }
    } finally {
      if (mounted) setState(() => _pickingLogo = false);
    }
  }

  void _removeLogo() => _c.setStyle(_c.style.copyWith(removeLogo: true));

  /// Whether the code for the current content is big enough to carry a logo.
  /// Very short content makes the smallest QR size, which has no room.
  bool _logoFits() {
    final data = _c.qrData ?? 'https://qruify.app';
    final modules = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.H,
    ).moduleCount;
    return LogoPlan.forModules(modules) != null;
  }

  @override
  void dispose() {
    _codeHex.dispose();
    _backgroundHex.dispose();
    super.dispose();
  }

  void _setCode(Color color) {
    _codeHex.text = hexOf(color);
    _c.setStyle(_c.style.copyWith(foreground: color));
  }

  void _setBackground(Color color) {
    _backgroundHex.text = hexOf(color);
    _c.setStyle(_c.style.copyWith(background: color));
  }

  void _reset() {
    _codeHex.text = hexOf(QrStyle.standard.foreground);
    _backgroundHex.text = hexOf(QrStyle.standard.background);
    _c.setStyle(QrStyle.standard);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _c,
          builder: (context, _) {
            final style = _c.style;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
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
                      Expanded(
                        child: Text(
                          'Customize',
                          style: text.titleLarge?.copyWith(
                            color: _ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: style == QrStyle.standard ? null : _reset,
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    children: [
                      _preview(style),
                      if (!_c.styleIsScannable) _warning(),
                      const SizedBox(height: 24),
                      _heading('Code color'),
                      _swatches(
                        _codeColors,
                        selected: style.foreground,
                        onPick: _setCode,
                      ),
                      const SizedBox(height: 12),
                      _hexField(
                        _codeHex,
                        (c) => _c.setStyle(style.copyWith(foreground: c)),
                      ),
                      const SizedBox(height: 24),
                      _heading('Background'),
                      _swatches(
                        _backgroundColors,
                        selected: style.background,
                        onPick: _setBackground,
                      ),
                      const SizedBox(height: 12),
                      _hexField(
                        _backgroundHex,
                        (c) => _c.setStyle(style.copyWith(background: c)),
                      ),
                      const SizedBox(height: 24),
                      _heading('Logo'),
                      _logoSection(style),
                      const SizedBox(height: 24),
                      _heading('Error correction'),
                      _levels(style),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: _ink,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Done'),
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

  Widget _preview(QrStyle style) {
    // Show the real content when there is some, otherwise a sample.
    final data = _c.qrData ?? 'https://qruify.app';
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: AspectRatio(
          aspectRatio: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5E5EA)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(23),
              child: QrPreview(data: data, style: style),
            ),
          ),
        ),
      ),
    );
  }

  Widget _warning() {
    final style = _c.style;
    final reason = style.background.a < 1 || style.foreground.a < 1
        ? 'Colors must be solid.'
        : style.foreground.computeLuminance() >=
              style.background.computeLuminance()
        ? 'The code should be darker than the background.'
        : 'There is not enough contrast.';
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.info_outline, size: 18, color: Color(0xFFD70015)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'This may be hard to scan. $reason',
              style: const TextStyle(color: Color(0xFFD70015), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heading(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12, left: 2),
    child: Text(
      label,
      style: const TextStyle(
        color: _ink,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _swatches(
    List<Color> colors, {
    required Color selected,
    required ValueChanged<Color> onPick,
  }) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final color in colors)
          Semantics(
            button: true,
            selected: color == selected,
            label: '#${hexOf(color)}',
            child: GestureDetector(
              onTap: () => onPick(color),
              // A ring outside the color when selected, so it shows on any
              // color, white included.
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 50,
                height: 50,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color == selected ? _ink : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD1D1D6)),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _hexField(
    TextEditingController controller,
    ValueChanged<Color> onValid,
  ) {
    return TextField(
      controller: controller,
      onChanged: (v) {
        final color = parseHexColor(v);
        if (color != null) onValid(color);
      },
      maxLength: 7,
      autocorrect: false,
      enableSuggestions: false,
      textCapitalization: TextCapitalization.characters,
      cursorColor: _ink,
      style: const TextStyle(fontSize: 17, letterSpacing: 1),
      decoration: InputDecoration(
        counterText: '',
        prefixText: '#  ',
        prefixStyle: const TextStyle(color: _secondary, fontSize: 17),
        hintText: 'Custom color, like 1A73E8',
        hintStyle: const TextStyle(color: Color(0xFFB0B0B5), letterSpacing: 0),
        filled: true,
        fillColor: _fill,
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
    );
  }

  Widget _logoSection(QrStyle style) {
    final logo = style.logo;
    final fits = _logoFits();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (logo == null)
          Material(
            color: _fill,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _pickingLogo ? null : _chooseLogo,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedImageAdd01,
                      size: 26,
                      color: _ink,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Add a logo',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Shown in the middle of the code',
                            style: TextStyle(color: _secondary, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    if (_pickingLogo)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _ink,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          )
        else
          Row(
            children: [
              _LogoThumb(png: logo.png),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Logo added',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: _pickingLogo ? null : _chooseLogo,
                child: const Text('Change'),
              ),
              TextButton(onPressed: _removeLogo, child: const Text('Remove')),
            ],
          ),
        if (_logoProblem != null) _note(_logoProblem!, const Color(0xFFD70015)),
        if (logo != null && !fits)
          _note(
            'This code is too small to hold a logo, so it is left out for now. Add a little more to the link or text.',
            _secondary,
          ),
        if (logo != null && fits)
          _note(
            'The logo is sized and centered so the code still scans, and error correction is set to Max.',
            _secondary,
          ),
      ],
    );
  }

  Widget _note(String message, Color color) => Padding(
    padding: const EdgeInsets.only(top: 10, left: 2),
    child: Text(message, style: TextStyle(color: color, fontSize: 14)),
  );

  Widget _levels(QrStyle style) {
    // A logo hides part of the code, so the top level is forced.
    final hasLogo = style.logo != null;
    final shown = style.effectiveErrorLevel;
    final info = _levelInfo[shown]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final level in QrErrorLevel.values) ...[
              Expanded(
                child: _LevelPill(
                  label: _levelInfo[level]!.$1,
                  selected: shown == level,
                  onTap: hasLogo
                      ? null
                      : () => _c.setStyle(style.copyWith(errorLevel: level)),
                ),
              ),
              if (level != QrErrorLevel.values.last) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text(
            info.$2,
            style: const TextStyle(color: _secondary, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _LevelPill extends StatelessWidget {
  const _LevelPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      label: 'Error correction $label',
      child: Opacity(
        opacity: onTap == null && !selected ? 0.4 : 1,
        child: Material(
          color: selected ? _ink : _fill,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: ExcludeSemantics(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : _ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoThumb extends StatelessWidget {
  const _LogoThumb({required this.png});

  final Uint8List png;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.memory(png, width: 56, height: 56, fit: BoxFit.cover),
    );
  }
}
