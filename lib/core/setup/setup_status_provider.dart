import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _modelsDownloadedKey = 'model_downloaded';

final setupStatusProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_modelsDownloadedKey) ?? false;
});

class SetupStatus {
  static Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_modelsDownloadedKey, true);
  }
}
