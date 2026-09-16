import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall/core/model/task.dart';
import '../../data/db/task_store.dart';

class TaskListNotifier extends AsyncNotifier<List<Task>> {
  @override
  Future<List<Task>> build() async {
    final rows = await TaskStore.getAll();
    return rows.map(Task.fromRow).toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final rows = await TaskStore.getAll();
      return rows.map(Task.fromRow).toList();
    });
  }

  Future<void> updateStatus(int id, String status) async {
    await TaskStore.updateStatus(id, status);
    await refresh();
  }

  Future<void> delete(int id) async {
    await TaskStore.delete(id);
    await refresh();
  }
}

final taskListProvider = AsyncNotifierProvider<TaskListNotifier, List<Task>>(
  TaskListNotifier.new,
);
