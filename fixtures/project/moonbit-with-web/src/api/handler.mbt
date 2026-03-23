///|
/// API handler for task operations.
/// Bridges the core task model with HTTP endpoints.

///|
/// In-memory store for tasks.
let tasks : Array[@core.Task] = []

///|
/// Adds a new task and returns its ID.
pub fn add_task(title : String, description : String) -> Int {
  let id = tasks.length() + 1
  let task = @core.Task::new(id, title, description~)
  tasks.push(task)
  id
}

///|
/// Retrieves all tasks as formatted summaries.
pub fn list_tasks() -> Array[String] {
  let result : Array[String] = []
  for task in tasks {
    result.push(task.summary())
  }
  result
}
