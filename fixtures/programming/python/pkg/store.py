"""In-memory task storage."""
from typing import List
from .models import Task, TaskStatus


class TaskStore:
    """Stores tasks in memory with lookup by title."""

    def __init__(self):
        self._tasks: dict[str, Task] = {}

    def add(self, task: Task) -> None:
        """Adds a task to the store."""
        self._tasks[task.title] = task

    def get(self, title: str) -> Task | None:
        """Retrieves a task by title."""
        return self._tasks.get(title)

    def complete(self, title: str) -> bool:
        """Marks a task as done. Returns False if not found."""
        task = self._tasks.get(title)
        if task is None:
            return False
        task.complete()
        return True

    def list_pending(self) -> List[Task]:
        """Returns all pending tasks sorted by priority."""
        return sorted(
            [t for t in self._tasks.values() if t.status == TaskStatus.PENDING],
            key=lambda t: t.priority,
        )

    def count_by_status(self, status: TaskStatus) -> int:
        """Counts tasks with the given status."""
        return sum(1 for t in self._tasks.values() if t.status == status)
