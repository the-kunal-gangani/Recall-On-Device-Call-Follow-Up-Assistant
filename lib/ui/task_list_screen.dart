import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall/core/model/task.dart';
import 'providers/task_list_provider.dart';

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskListProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D12),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D0D12),
          elevation: 0,
          title: const Text('Recall'),
          bottom: const TabBar(
            indicatorColor: Color(0xFF6C5CE7),
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Confirmed'),
              Tab(text: 'Done'),
            ],
          ),
        ),
        body: tasksAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
          ),
          error: (err, _) => Center(
            child: Text(
              'Something went wrong loading tasks',
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          data: (tasks) {
            final pending = tasks.where((t) => t.status == 'pending').toList();
            final confirmed = tasks
                .where((t) => t.status == 'confirmed')
                .toList();
            final done = tasks
                .where(
                  (t) => t.status == 'dismissed' || t.status == 'completed',
                )
                .toList();

            return TabBarView(
              children: [
                _TaskTab(tasks: pending, emptyLabel: 'No pending commitments'),
                _TaskTab(tasks: confirmed, emptyLabel: 'Nothing confirmed yet'),
                _TaskTab(tasks: done, emptyLabel: 'Nothing here yet'),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TaskTab extends ConsumerWidget {
  final List<Task> tasks;
  final String emptyLabel;

  const _TaskTab({required this.tasks, required this.emptyLabel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tasks.isEmpty) {
      return Center(
        child: Text(emptyLabel, style: const TextStyle(color: Colors.white38)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Dismissible(
          key: ValueKey(task.id),
          direction: task.status == 'pending'
              ? DismissDirection.horizontal
              : DismissDirection.none,
          background: _swipeBackground(
            color: const Color(0xFF2ECC71),
            icon: Icons.check,
            alignment: Alignment.centerLeft,
          ),
          secondaryBackground: _swipeBackground(
            color: const Color(0xFFE74C3C),
            icon: Icons.close,
            alignment: Alignment.centerRight,
          ),
          confirmDismiss: (direction) async {
            final newStatus = direction == DismissDirection.startToEnd
                ? 'confirmed'
                : 'dismissed';
            await ref
                .read(taskListProvider.notifier)
                .updateStatus(task.id, newStatus);
            return true;
          },
          child: _TaskCard(task: task),
        );
      },
    );
  }

  Widget _swipeBackground({
    required Color color,
    required IconData icon,
    required Alignment alignment,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      margin: const EdgeInsets.only(bottom: 12),
      child: Icon(icon, color: color),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;

  const _TaskCard({required this.task});

  Color get _statusColor {
    switch (task.status) {
      case 'confirmed':
        return const Color(0xFF2ECC71);
      case 'dismissed':
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFF6C5CE7);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF17171F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.description,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (task.person != null) ...[
                Icon(Icons.person_outline, size: 14, color: Colors.white38),
                const SizedBox(width: 4),
                Text(
                  task.person!,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(width: 12),
              ],
              if (task.deadlineMentioned != null) ...[
                Icon(Icons.schedule, size: 14, color: Colors.white38),
                const SizedBox(width: 4),
                Text(
                  task.deadlineMentioned!,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
