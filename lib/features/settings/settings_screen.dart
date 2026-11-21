import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/app_services.dart';
import '../shared/confirm_sheet.dart';

const _ink = Colors.black;
const _fill = Color(0xFFF2F2F7);
const _secondary = Color(0xFF6E6E73);
const _danger = Color(0xFFD70015);

/// Kept in step with `version` in pubspec.yaml.
const appVersion = '1.0.0';

/// The official hosted privacy policy URL.
const privacyPolicyUrl =
    'https://ferousco-dev.github.io/qruify-privacy-policy/';

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

  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Privacy Policy',
                    style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                          color: _ink,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Close',
                  child: Material(
                    color: _fill,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(ctx).maybePop(),
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Center(
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedCancel01,
                            size: 18,
                            color: _ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _fill,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Qruify is private by design and works completely offline. There are no accounts, no ads, no trackers, and no analytics. All QR generation, camera scanning, guest list data, and history stay strictly on your device.',
                style: TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'What Qruify Handles',
              style: TextStyle(
                color: _ink,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• QR Content: Text, links, Wi-Fi details, and contacts you generate are processed locally on your device.\n'
              '• Camera Scanner: Camera frames are decoded in memory in real time to read QR barcodes. Images are never recorded, saved, or uploaded.\n'
              '• Guest Lists: Imported CSV files and check-in statuses are saved in your device\'s local database and never leave the phone.\n'
              '• History & Styles: Your saved codes and custom colors are kept exclusively in local device storage.',
              style: TextStyle(color: _secondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            const Text(
              'Device Permissions',
              style: TextStyle(
                color: _ink,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Camera access is requested solely for optical barcode scanning while using the in-app scanner. It is not used for any other purpose.',
              style: TextStyle(color: _secondary, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: () {
                  SharePlus.instance.share(
                    ShareParams(
                      text: privacyPolicyUrl,
                      subject: 'Qruify Privacy Policy',
                    ),
                  );
                },
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedShare08,
                  size: 20,
                  color: Colors.white,
                ),
                label: const Text('Share Privacy Policy Link'),
                style: FilledButton.styleFrom(
                  backgroundColor: _ink,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: privacyPolicyUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Privacy policy URL copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text(
                  'Copy Policy URL',
                  style: TextStyle(color: _secondary, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                _Row(
                  icon: HugeIcons.strokeRoundedShield01,
                  title: 'Privacy policy',
                  subtitle: 'Read our offline privacy statement',
                  onTap: () => _showPrivacyPolicy(context),
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
