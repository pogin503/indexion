"""Domain models for task management."""
from enum import Enum
from dataclasses import dataclass, field


class TaskStatus(Enum):
    """Status of a task."""
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    DONE = "done"


@dataclass
class Task:
    """
    A task with title, description, and status.

    Supports priority ordering — lower number means higher priority.
    """
    title: str
    description: str = ""
    priority: int = 5
    status: TaskStatus = field(default=TaskStatus.PENDING)

    def summary(self) -> str:
        """Returns a formatted one-line summary."""
        indicator = "✓" if self.status == TaskStatus.DONE else "○"
        return f"{indicator} [{self.priority}] {self.title}"

    def complete(self) -> None:
        """Marks the task as done."""
        self.status = TaskStatus.DONE
