///|
/// A task with a title, description, and completion status.
pub struct Task {
  id : Int
  title : String
  description : String
  mut done : Bool
}

///|
/// Creates a new task.
pub fn Task::new(id : Int, title : String, description~ : String = "") -> Task {
  { id, title, description, done: false }
}

///|
/// Marks a task as completed.
pub fn Task::complete(self : Task) -> Unit {
  self.done = true
}

///|
/// Returns a formatted summary — includes status indicator.
pub fn Task::summary(self : Task) -> String {
  let status = if self.done { "✓" } else { "○" }
  "\{status} [\{self.id}] \{self.title}"
}
