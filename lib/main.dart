import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall/data/db/sqlcipher_init.dart';
import 'package:recall/ui/setup_screen.dart';
import 'services/call_watcher_service.dart';
import 'services/reminder_service.dart';
import 'services/extraction_service.dart';
import 'core/permissions/storage_permission_handler.dart';
import 'core/security/screen_security_provider.dart';
import 'core/setup/setup_status_provider.dart';
import 'ui/lock_screen.dart';
import 'ui/task_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SqlCipherInit.ensureInitialized();

  await CallWatcherService.initialize();
  await ReminderService.initialize();

  try {
    await ExtractionService.initialize();
  } catch (_) {}

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
    final setupComplete = ref.watch(setupStatusProvider);

    return MaterialApp(
      title: 'Recall',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: setupComplete.when(
        loading: () => const Scaffold(
          backgroundColor: Color(0xFF0D0D12),
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
          ),
        ),
        error: (_, _) => const SetupScreen(),
        data: (complete) => complete
            ? const LockScreen(child: TaskListScreen())
            : const SetupScreen(),
      ),
    );
  }
}
