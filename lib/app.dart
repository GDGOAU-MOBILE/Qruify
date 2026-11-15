import 'package:flutter/material.dart';

import 'core/app_fonts.dart';
import 'features/generator/generator_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/splash/splash_screen.dart';
import 'services/app_services.dart';

class QruifyApp extends StatelessWidget {
  const QruifyApp({super.key, this.splashFieldLoader = SplashField.prepare});

  /// Builds the splash particles. Tests replace it.
  final SplashFieldLoader splashFieldLoader;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qruify',
      theme: ThemeData(
        fontFamily: AppFonts.ui,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: _AppRoot(splashFieldLoader: splashFieldLoader),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot({required this.splashFieldLoader});

  final SplashFieldLoader splashFieldLoader;

  @override
  State<_AppRoot> createState() => _AppRootState();
}

/// Splash, then onboarding on the first launch, then the generator.
enum _Stage { splash, onboarding, home }

class _AppRootState extends State<_AppRoot> {
  _Stage _stage = _Stage.splash;

  void _splashDone() {
    final done = ServicesScope.of(context).settings.onboardingDone;
    setState(() => _stage = done ? _Stage.home : _Stage.onboarding);
  }

  void _onboardingDone() {
    ServicesScope.of(context).settings.setOnboardingDone();
    setState(() => _stage = _Stage.home);
  }

  @override
  Widget build(BuildContext context) {
    // White backing: while screens cross-fade, the window behind them would
    // otherwise show through as a dark flash. Splash to onboarding is a hard
    // cut on purpose: both show the same QR code in the same place.
    final child = switch (_stage) {
      _Stage.splash => SplashScreen(
        key: const ValueKey('splash'),
        // First launch: the full burst into a QR code. Later: just the name.
        explode: !ServicesScope.of(context).settings.onboardingDone,
        fieldLoader: widget.splashFieldLoader,
        onFinished: _splashDone,
      ),
      _Stage.onboarding => OnboardingScreen(
        key: const ValueKey('onboarding'),
        onContinue: _onboardingDone,
      ),
      _Stage.home => const GeneratorScreen(key: ValueKey('home')),
    };
    return ColoredBox(
      color: Colors.white,
      child: AnimatedSwitcher(
        duration: _stage == _Stage.onboarding
            ? Duration.zero
            : const Duration(milliseconds: 450),
        child: child,
      ),
    );
  }
}
