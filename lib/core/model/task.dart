class Task {
  final int id;
  final String description;
  final String? deadlineMentioned;
  final String? person;
  final String status;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.description,
    this.deadlineMentioned,
    this.person,
    required this.status,
    required this.createdAt,
  });

  factory Task.fromRow(Map<String, Object?> row) {
    return Task(
      id: row['id'] as int,
      description: row['description'] as String,
      deadlineMentioned: row['deadline_mentioned'] as String?,
      person: row['person'] as String?,
      status: row['status'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
    );
  }
}
