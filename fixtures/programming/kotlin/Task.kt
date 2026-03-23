package com.example.tasks

/** Status of a task. */
enum class TaskStatus {
    PENDING,
    IN_PROGRESS,
    DONE,
}

/**
 * A task with title, description, and status.
 *
 * @property id Unique identifier (0 means unsaved)
 * @property title Short summary
 */
data class Task(
    val id: Long = 0,
    val title: String,
    val description: String = "",
    val status: TaskStatus = TaskStatus.PENDING,
) {
    /** Marks the task as completed. */
    fun complete(): Task = copy(status = TaskStatus.DONE)
}
