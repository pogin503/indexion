"""
Entry point — demonstrates the task management module.
"""
from pkg.models import Task, TaskStatus
from pkg.store import TaskStore


def main():
    """Creates sample tasks and displays them."""
    store = TaskStore()
    store.add(Task("Write docs", "Document the API endpoints"))
    store.add(Task("Fix bug #42", priority=2))

    for task in store.list_pending():
        print(task.summary())

    store.complete("Write docs")
    print(f"Completed: {store.count_by_status(TaskStatus.DONE)}")


if __name__ == "__main__":
    main()
