package com.example.tasks

import scala.collection.mutable

/** Status of a task. */
sealed trait TaskStatus
object TaskStatus {
  case object Pending extends TaskStatus
  case object Done extends TaskStatus
}

/**
 * A task with title and status.
 * @param id unique identifier
 * @param title short summary
 */
case class Task(id: Long, title: String, status: TaskStatus = TaskStatus.Pending) {
  /** Returns a formatted summary. */
  def summary: String = {
    val indicator = status match {
      case TaskStatus.Done => "✓"
      case _ => "○"
    }
    s"$indicator [$id] $title"
  }
}

/** In-memory task service. */
class TaskService {
  private val store = mutable.Map.empty[Long, Task]
  private var nextId = 1L

  /** Creates a new task. */
  def create(title: String): Task = {
    val task = Task(nextId, title)
    store(nextId) = task
    nextId += 1
    task
  }

  /** Marks a task as done. */
  def complete(id: Long): Option[Task] = {
    store.get(id).map { task =>
      val updated = task.copy(status = TaskStatus.Done)
      store(id) = updated
      updated
    }
  }

  /** Returns all pending tasks. */
  def pending: List[Task] =
    store.values.filter(_.status == TaskStatus.Pending).toList
}
