import 'package:flutter/services.dart';

class ScreenSecurity {
  static const _channel = MethodChannel('com.recall/screen_security');

  static Future<void> enableSecureFlag() async {
    try {
      await _channel.invokeMethod('enableSecureFlag');
    } catch (_) {}
  }
}
