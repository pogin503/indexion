# frozen_string_literal: true

require_relative 'task'

# Service for managing tasks — wraps an in-memory store.
class TaskService
  def initialize
    @tasks = {}
    @next_id = 1
  end

  # Adds a task with the given title and returns it.
  # @param title [String] the task title
  # @return [Task]
  def add(title)
    task = Task.new(id: @next_id, title: title)
    @tasks[@next_id] = task
    @next_id += 1
    task
  end

  # Marks a task as done by ID.
  # @param id [Integer]
  # @return [Boolean] true if found
  def complete(id)
    task = @tasks[id]
    return false unless task

    task.complete!
    true
  end

  # Returns all pending tasks.
  # @return [Array<Task>]
  def pending
    @tasks.values.reject(&:done?)
  end
end
