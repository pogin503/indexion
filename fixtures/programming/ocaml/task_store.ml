(** Task management module — functional approach with immutable data. *)

(** Status of a task. *)
type status = Pending | Done

(** A task with ID, title, and status. *)
type task = {
  id : int;
  title : string;
  status : status;
}

(** In-memory task store. *)
type store = {
  tasks : task list;
  next_id : int;
}

(** Creates an empty store. *)
let empty : store = { tasks = []; next_id = 1 }

(** Adds a task with the given title. *)
let add_task title store =
  let task = { id = store.next_id; title; status = Pending } in
  let new_store = { tasks = task :: store.tasks; next_id = store.next_id + 1 } in
  (task, new_store)

(** Marks a task as done by ID. *)
let complete_task id store =
  let update t = if t.id = id then { t with status = Done } else t in
  { store with tasks = List.map update store.tasks }

(** Returns all pending tasks. *)
let pending_tasks store =
  List.filter (fun t -> t.status = Pending) store.tasks
