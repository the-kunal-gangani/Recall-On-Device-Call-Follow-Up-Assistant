import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/src/services/predictive_back_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

class LockNotifier extends Notifier<bool> implements WidgetsBindingObserver {
  final _auth = LocalAuthentication();
  bool _authenticating = false;

  @override
  bool build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));
    attemptUnlock();
    return false;
  }

  Future<void> attemptUnlock() async {
    if (_authenticating) return;
    _authenticating = true;

    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) {
        state = true;
        _authenticating = false;
        return;
      }

      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Unlock Recall to view your call reminders',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      state = didAuthenticate;
      _authenticating = false;
    } catch (_) {
      state = false;
      _authenticating = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.paused) {
      state = false;
    } else if (lifecycleState == AppLifecycleState.resumed && !state) {
      attemptUnlock();
    }
  }

  @override
  void didChangeAccessibilityFeatures() {}
  @override
  void didChangeLocales(List<Locale>? locales) {}
  @override
  void didChangeMetrics() {}
  @override
  void didChangePlatformBrightness() {}
  @override
  void didChangeTextScaleFactor() {}
  @override
  void didHaveMemoryPressure() {}
  @override
  Future<bool> didPopRoute() async => false;
  @override
  Future<bool> didPushRoute(String route) async => false;
  @override
  Future<bool> didPushRouteInformation(
    RouteInformation routeInformation,
  ) async => false;
  @override
  Future<AppExitResponse> didRequestAppExit() async => AppExitResponse.exit;

  @override
  void didChangeViewFocus(ViewFocusEvent event) {
    // TODO: implement didChangeViewFocus
  }

  @override
  void handleCancelBackGesture() {
    // TODO: implement handleCancelBackGesture
  }

  @override
  void handleCommitBackGesture() {
    // TODO: implement handleCommitBackGesture
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    // TODO: implement handleStartBackGesture
    throw UnimplementedError();
  }

  @override
  void handleStatusBarTap() {
    // TODO: implement handleStatusBarTap
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    // TODO: implement handleUpdateBackGestureProgress
  }
}

final lockProvider = NotifierProvider<LockNotifier, bool>(LockNotifier.new);
