import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/qr_detector.dart';
import '../../data/database.dart';
import '../../data/guest_repository.dart';
import '../../services/app_services.dart';
import '../history/history_screen.dart' show relativeDate;
import '../shared/type_icons.dart';
import 'guest_list_sheet.dart';

const _ink = Colors.black;
const _fill = Color(0xFFF2F2F7);
const _secondary = Color(0xFF6E6E73);
const _line = Color(0xFFE5E5EA);
const _green = Color(0xFF34C759);
const _amber = Color(0xFFFF9500);
const _danger = Color(0xFFD70015);

/// Scans QR codes using the device camera.
///
/// Supports two modes:
/// 1. Guest Approval Mode: If a guest list has been imported, matches scanned
///    codes to verify and check people in.
/// 2. General Scan Mode: Reads the QR code and shows what is inside.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late final MobileScannerController _scannerController;
  bool _torchOn = false;
  CheckInResult? _lastApproval;
  Timer? _approvalAutoDismiss;
  bool _handlingScan = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _approvalAutoDismiss?.cancel();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    try {
      await _scannerController.toggleTorch();
      setState(() => _torchOn = !_torchOn);
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    try {
      await _scannerController.switchCamera();
    } catch (_) {}
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_handlingScan) return;
    final barcode = capture.barcodes.firstOrNull;
    final raw = barcode?.rawValue?.trim();
    if (raw == null || raw.isEmpty) return;

    _handlingScan = true;
    final guestRepo = ServicesScope.of(context).guests;
    final stats = await guestRepo.getStats();

    if (stats.total > 0) {
      // Approval Mode: Check against imported guest list
      HapticFeedback.mediumImpact();
      final result = await guestRepo.checkIn(raw);
      if (!mounted) return;

      _approvalAutoDismiss?.cancel();
      setState(() {
        _lastApproval = result;
      });

      // Auto-dismiss after 3.5 seconds to allow continuous scanning
      _approvalAutoDismiss = Timer(const Duration(milliseconds: 3500), () {
        if (mounted) {
          setState(() {
            _lastApproval = null;
            _handlingScan = false;
          });
        }
      });
    } else {
      // Normal Scan Mode: Show standard scan sheet
      HapticFeedback.lightImpact();
      if (!mounted) return;
      await _showGeneralScanSheet(raw);
      _handlingScan = false;
    }
  }

  Future<void> _showGeneralScanSheet(String content) {
    final type = QrDetector.detect(content);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _GeneralScanSheet(content: content, type: type),
    );
  }

  void _dismissApprovalCard() {
    _approvalAutoDismiss?.cancel();
    setState(() {
      _lastApproval = null;
      _handlingScan = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final guestRepo = ServicesScope.of(context).guests;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          Positioned.fill(
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
              errorBuilder: (context, error) {
                final isMissingPlugin =
                    error.toString().contains('MissingPluginException');
                return _PermissionDeniedView(
                  isMissingPlugin: isMissingPlugin,
                  onBack: () => Navigator.of(context).maybePop(),
                );
              },
            ),
          ),

          // Viewfinder Target Reticle
          Positioned.fill(
            child: StreamBuilder<List<GuestEntry>>(
              stream: guestRepo.watch(),
              builder: (context, snapshot) {
                final hasGuests = (snapshot.data ?? const []).isNotEmpty;
                return _ViewfinderOverlay(
                  hasGuests: hasGuests,
                  hasResult: _lastApproval != null,
                );
              },
            ),
          ),

          // Top Action Controls
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: StreamBuilder<List<GuestEntry>>(
                  stream: guestRepo.watch(),
                  builder: (context, snapshot) {
                    final entries = snapshot.data ?? const <GuestEntry>[];
                    final total = entries.length;
                    final checkedIn = entries.where((e) => e.isCheckedIn).length;

                    return Row(
                      children: [
                        _GlassCircleButton(
                          icon: HugeIcons.strokeRoundedArrowLeft01,
                          tooltip: 'Back',
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(width: 10),
                        // Guest list badge pill
                        Expanded(
                          child: GestureDetector(
                            onTap: () => GuestListSheet.show(context),
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedUserGroup,
                                    size: 18,
                                    color: total > 0 ? _green : Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    total > 0
                                        ? '$checkedIn / $total Checked In'
                                        : 'Guest List',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _GlassCircleButton(
                          icon: _torchOn
                              ? HugeIcons.strokeRoundedFlash
                              : HugeIcons.strokeRoundedFlashOff,
                          tooltip: 'Torch',
                          onTap: _toggleTorch,
                        ),
                        const SizedBox(width: 8),
                        _GlassCircleButton(
                          icon: HugeIcons.strokeRoundedCameraRotated01,
                          tooltip: 'Flip Camera',
                          onTap: _switchCamera,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),

          // In-Camera Approval Feedback Card
          if (_lastApproval != null)
            Positioned(
              left: 20,
              right: 20,
              bottom: 40,
              child: _ApprovalFeedbackCard(
                result: _lastApproval!,
                onNext: _dismissApprovalCard,
              ),
            ),
        ],
      ),
    );
  }
}

/// Frosted translucent circular button for camera overlays.
class _GlassCircleButton extends StatelessWidget {
  const _GlassCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Center(
            child: HugeIcon(icon: icon, size: 22, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Viewfinder overlay with scan framing reticle and prompt.
class _ViewfinderOverlay extends StatelessWidget {
  const _ViewfinderOverlay({
    required this.hasGuests,
    required this.hasResult,
  });

  final bool hasGuests;
  final bool hasResult;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Frame Box
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.8),
                width: 2.5,
              ),
            ),
          ),
          // Hint text underneath
          if (!hasResult)
            Positioned(
              bottom: 120,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  hasGuests
                      ? 'Point at guest QR code to approve'
                      : 'Point camera at any QR code',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Interactive banner displayed when a guest code is scanned and evaluated.
class _ApprovalFeedbackCard extends StatelessWidget {
  const _ApprovalFeedbackCard({
    required this.result,
    required this.onNext,
  });

  final CheckInResult result;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final (Color bannerColor, String title, List<List<dynamic>> icon) =
        switch (result.type) {
      CheckInResultType.approved => (
          _green,
          'APPROVED',
          HugeIcons.strokeRoundedTick02,
        ),
      CheckInResultType.alreadyCheckedIn => (
          _amber,
          'ALREADY CHECKED IN',
          HugeIcons.strokeRoundedAlert02,
        ),
      CheckInResultType.notFound => (
          _danger,
          'NOT ON GUEST LIST',
          HugeIcons.strokeRoundedCancel01,
        ),
    };

    final guest = result.guest;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _line, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: bannerColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: icon,
                      size: 24,
                      color: bannerColor,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: bannerColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        guest != null && guest.name.isNotEmpty
                            ? guest.name
                            : result.scannedCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (guest != null &&
                guest.name.isNotEmpty &&
                guest.code != guest.name) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _fill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Code: ${guest.code}${guest.extra.isNotEmpty ? ' · ${guest.extra}' : ''}',
                  style: const TextStyle(color: _secondary, fontSize: 13),
                ),
              ),
            ],
            if (result.type == CheckInResultType.alreadyCheckedIn &&
                guest?.checkedInAt != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'First checked in: ${relativeDate(guest!.checkedInAt!)}',
                  style: const TextStyle(
                    color: _amber,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: _ink,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Scan Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fallback screen when camera permission is not granted or plugin needs restart.
class _PermissionDeniedView extends StatelessWidget {
  const _PermissionDeniedView({
    required this.onBack,
    this.isMissingPlugin = false,
  });

  final VoidCallback onBack;
  final bool isMissingPlugin;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _fill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _line),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: isMissingPlugin
                        ? HugeIcons.strokeRoundedAlertCircle
                        : HugeIcons.strokeRoundedCameraOff01,
                    size: 32,
                    color: _secondary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isMissingPlugin ? 'App Restart Needed' : 'Camera Access Needed',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isMissingPlugin
                    ? 'A new native camera plugin was added to Qruify. Please stop the app and rebuild with "flutter run".'
                    : 'Qruify scans QR codes completely offline on your device. Please allow camera access in Settings.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _secondary, fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton(
                  onPressed: onBack,
                  style: FilledButton.styleFrom(
                    backgroundColor: _ink,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Go Back'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// General scan results sheet matching _DetailSheet in HistoryScreen.
class _GeneralScanSheet extends StatefulWidget {
  const _GeneralScanSheet({required this.content, required this.type});

  final String content;
  final dynamic type;

  @override
  State<_GeneralScanSheet> createState() => _GeneralScanSheetState();
}

class _GeneralScanSheetState extends State<_GeneralScanSheet> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.content));
    if (!mounted) return;
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _share() {
    SharePlus.instance.share(ShareParams(text: widget.content));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: iconForType(widget.type),
                size: 18,
                color: _secondary,
              ),
              const SizedBox(width: 8),
              Text(
                widget.type.label,
                style: const TextStyle(
                  color: _secondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _fill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _line),
            ),
            child: SelectableText(
              widget.content,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: FilledButton.icon(
              onPressed: _share,
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedShare08,
                size: 20,
                color: Colors.white,
              ),
              label: const Text('Share'),
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
    );
  }
}
