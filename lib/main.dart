import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall/data/db/sqlcipher_init.dart';
import 'package:recall/ui/lock_screen.dart';
import 'services/call_watcher_service.dart';
import 'services/reminder_service.dart';
import 'core/permissions/storage_permission_handler.dart';
import 'core/security/screen_security_provider.dart';
import 'services/extraction_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SqlCipherInit.ensureInitialized();

  await CallWatcherService.initialize();
  await ReminderService.initialize();
  try {
    await ExtractionService.initialize();
  } catch (_) {
    // Model missing/corrupted — surfaced via notification from QueueProcessor
    // on first actual extraction attempt instead of blocking app startup.
  }

  final hasPermissions = await StoragePermissionHandler.hasAllPermissions();
  if (!hasPermissions) {
    await StoragePermissionHandler.requestAll();
  }

  await CallWatcherService.schedulePeriodicScan();

  runApp(const ProviderScope(child: RecallApp()));
}

class RecallApp extends ConsumerWidget {
  const RecallApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(screenSecurityProvider);

    return MaterialApp(
      title: 'Recall',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const LockScreen(child: _PlaceholderHome()),
    );
  }
}

class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Recall')));
  }
}
