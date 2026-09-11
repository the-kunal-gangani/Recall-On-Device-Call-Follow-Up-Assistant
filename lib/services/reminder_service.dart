import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../data/db/task_store.dart';

class ReminderService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _confirmChannelId = 'recall_confirm_channel';
  static const _reminderChannelId = 'recall_reminder_channel';

  static Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _handleNotificationAction,
    );

    const confirmChannel = AndroidNotificationChannel(
      _confirmChannelId,
      'Task Confirmations',
      description: 'Confirm commitments found in your calls',
      importance: Importance.high,
    );
    const reminderChannel = AndroidNotificationChannel(
      _reminderChannelId,
      'Reminders',
      description: 'Reminders for confirmed tasks',
      importance: Importance.high,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _plugin
        .resolvePlatformSpecificImplementation();
    await androidPlugin?.createNotificationChannel(confirmChannel);
    await androidPlugin?.createNotificationChannel(reminderChannel);
  }

  static Future<void> showConfirmPrompt(int taskId, String description) async {
    const androidDetails = AndroidNotificationDetails(
      _confirmChannelId,
      'Task Confirmations',
      importance: Importance.high,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction('confirm', 'Confirm & Remind'),
        AndroidNotificationAction('dismiss', 'Dismiss'),
      ],
    );

    await _plugin.show(
      id: taskId,
      title: 'Did you mean to do this?',
      body: description,
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: taskId.toString(),
    );
  }

  static Future<void> _handleNotificationAction(
    NotificationResponse response,
  ) async {
    final taskId = int.tryParse(response.payload ?? '');
    if (taskId == null) return;

    if (response.actionId == 'confirm') {
      await TaskStore.updateStatus(taskId, 'confirmed');
      await _scheduleReminder(taskId);
    } else if (response.actionId == 'dismiss') {
      await TaskStore.updateStatus(taskId, 'dismissed');
    }
  }

  static Future<void> _scheduleReminder(int taskId) async {
    final task = await TaskStore.getById(taskId);
    if (task == null) return;

    final scheduledTime = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(hours: 2));

    const androidDetails = AndroidNotificationDetails(
      _reminderChannelId,
      'Reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _plugin.zonedSchedule(
      id: taskId + 100000,
      title: 'Reminder',
      body: task['description'] as String,
      scheduledDate: scheduledTime,
      notificationDetails: const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
