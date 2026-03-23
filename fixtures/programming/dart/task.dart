/// A task with title, description, and completion status.
class Task {
  final int id;
  final String title;
  final String description;
  final bool done;

  /// Creates a new task.
  const Task({
    required this.id,
    required this.title,
    this.description = '',
    this.done = false,
  });

  /// Returns a copy with the given fields replaced.
  Task copyWith({int? id, String? title, String? description, bool? done}) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      done: done ?? this.done,
    );
  }

  /// Formatted summary for display.
  String get summary {
    final status = done ? '✓' : '○';
    return '$status [$id] $title';
  }
}
