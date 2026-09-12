import 'package:flutter/material.dart';
import 'package:recall/data/db/sqlcipher_init.dart';
import 'services/call_watcher_service.dart';
import 'core/permissions/storage_permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SqlCipherInit.ensureInitialized();

  await CallWatcherService.initialize();
  await ReminderService.initialize();

  final hasPermissions = await StoragePermissionHandler.hasAllPermissions();
  if (!hasPermissions) {
    await StoragePermissionHandler.requestAll();
  }

  await CallWatcherService.schedulePeriodicScan();

  runApp(const RecallApp());
}

class RecallApp extends StatelessWidget {
  const RecallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recall',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const _PlaceholderHome(),
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
