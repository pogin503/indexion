import 'package:example/models/task.dart';

/// Service for managing tasks — coordinates between UI and storage.
class TaskService {
  final List<Task> _tasks = [];
  int _nextId = 1;

  /// Creates a new task and returns it.
  Task create(String title, {String description = ''}) {
    final task = Task(
      id: _nextId++,
      title: title,
      description: description,
    );
    _tasks.add(task);
    return task;
  }

  /// Marks a task as done by ID. Returns false if not found.
  bool complete(int id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index < 0) return false;
    _tasks[index] = _tasks[index].copyWith(done: true);
    return true;
  }

  /// Returns all pending tasks sorted by creation order.
  List<Task> get pending =>
      _tasks.where((t) => !t.done).toList();
}
