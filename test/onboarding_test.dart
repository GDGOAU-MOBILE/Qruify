import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qruify/features/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('text and a black pill button appear after the QR tilts', (
    tester,
  ) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(home: OnboardingScreen(onContinue: () => tapped++)),
    );
    expect(find.text('Continue'), findsOneWidget);
    expect(
      tester
          .widget<Opacity>(
            find.ancestor(
              of: find.text('Continue'),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      0,
    );

    await tester.pump(const Duration(milliseconds: 250)); // start delay
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(seconds: 1));

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    final style = button.style!;
    expect(style.backgroundColor!.resolve({}), Colors.black);
    expect(style.shape!.resolve({}), isA<StadiumBorder>());
    await tester.tap(find.text('Continue'));
    expect(tapped, 1);
  });
}
