import 'package:flutter/material.dart';

const _red = Color(0xFFFF3B30); // iOS system red
const _card = Color(0xF7FFFFFF);
const _hairline = Color(0x4A3C3C43);

/// Asks before something that cannot be undone, in the style of an iOS action
/// sheet: two floating rounded cards, the destructive choice in red at the
/// top, and a separate Cancel card at the bottom.
///
/// Drag it down, or tap outside it, to cancel. Returns true only if the
/// person pressed [action].
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
}) async {
  final yes = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: const Color(0x66000000),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Card(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF6E6E73),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          body,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF6E6E73),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 0.5, thickness: 0.5, color: _hairline),
                  _Row(
                    label: action,
                    color: _red,
                    weight: FontWeight.w400,
                    onTap: () => Navigator.pop(context, true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _Card(
              child: _Row(
                label: 'Cancel',
                color: Colors.black,
                weight: FontWeight.w600,
                onTap: () => Navigator.pop(context, false),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  return yes == true;
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: ColoredBox(
        color: _card,
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.color,
    required this.weight,
    required this.onTap,
  });

  final String label;
  final Color color;
  final FontWeight weight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      highlightColor: const Color(0x14000000),
      splashFactory: NoSplash.splashFactory,
      child: SizedBox(
        height: 57,
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: color, fontSize: 20, fontWeight: weight),
          ),
        ),
      ),
    );
  }
}
