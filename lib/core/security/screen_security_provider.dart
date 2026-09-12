import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screen_security.dart';

final screenSecurityProvider = FutureProvider<void>((ref) async {
  await ScreenSecurity.enableSecureFlag();
});
