import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../services/app_services.dart';
import '../shared/confirm_sheet.dart';

const _ink = Colors.black;
const _fill = Color(0xFFF2F2F7);
const _secondary = Color(0xFF6E6E73);
const _danger = Color(0xFFD70015);

/// Kept in step with `version` in pubspec.yaml.
const appVersion = '1.0.0';

/// A few housekeeping actions and a plain statement of what the app does
/// with your data.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _note;

  void _say(String message) => setState(() => _note = message);

  Future<bool> _confirm(String title, String body, String action) =>
      showConfirmSheet(context, title: title, body: body, action: action);

  Future<void> _clearHistory() async {
    final services = ServicesScope.of(context);
    final ok = await _confirm(
      'Clear all history?',
      "Every saved code will be removed. This can't be undone.",
      'Clear All History',
    );
    if (!ok) return;
    await services.history.clear();
    if (mounted) _say('History cleared.');
  }

  Future<void> _resetStyle() async {
    final services = ServicesScope.of(context);
    final ok = await _confirm(
      'Reset the saved style?',
      'Colors, error correction and logo go back to standard the next time you open the app.',
      'Reset Style',
    );
    if (!ok) return;
    await services.settings.clearStyle();
    if (mounted) {
      _say('Style reset. It applies the next time you open the app.');
    }
  }

  Future<void> _showIntro() async {
    await ServicesScope.of(context).settings.resetOnboarding();
    if (mounted) {
      _say('The welcome screen will show the next time you open the app.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              children: [
                Semantics(
                  button: true,
                  label: 'Back',
                  child: Material(
                    color: _fill,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedArrowLeft01,
                            size: 22,
                            color: _ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _Group(
              children: [
                _Row(
                  icon: HugeIcons.strokeRoundedClock01,
                  title: 'Clear history',
                  subtitle: 'Remove every saved code',
                  danger: true,
                  onTap: _clearHistory,
                ),
                _Row(
                  icon: HugeIcons.strokeRoundedPaintBoard,
                  title: 'Reset saved style',
                  subtitle: 'Back to black on white, no logo',
                  onTap: _resetStyle,
                ),
                _Row(
                  icon: HugeIcons.strokeRoundedPlayCircle,
                  title: 'Show the welcome screen again',
                  subtitle: 'Next time you open the app',
                  onTap: _showIntro,
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topLeft,
              child: _note == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 14, left: 4),
                      child: Text(
                        _note!,
                        style: const TextStyle(color: _secondary, fontSize: 14),
                      ),
                    ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _fill,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Private by design',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Qruify works offline. Your codes, logos and history stay on this device. There is no account and nothing is sent anywhere.',
                    style: TextStyle(
                      color: _secondary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Qruify $appVersion',
                style: TextStyle(color: _secondary, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: ColoredBox(
        color: _fill,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                const Divider(height: 1, indent: 60, color: Color(0xFFE5E5EA)),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? _danger : _ink;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            HugeIcon(icon: icon, size: 24, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: _secondary, fontSize: 14),
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
