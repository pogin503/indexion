#= Task management module — uses Julia structs and multiple dispatch. =#

module TaskStore

export Task, TaskCollection, add!, complete!, pending

"""
    Task(id, title; done=false)

A task with an ID, title, and completion status.
"""
struct Task
    id::Int
    title::String
    done::Bool
    Task(id, title; done=false) = new(id, title, done)
end

"""
    TaskCollection()

Mutable collection of tasks with auto-incrementing IDs.
"""
mutable struct TaskCollection
    tasks::Vector{Task}
    next_id::Int
    TaskCollection() = new(Task[], 1)
end

"""Add a task with the given title."""
function add!(col::TaskCollection, title::String)::Task
    task = Task(col.next_id, title)
    push!(col.tasks, task)
    col.next_id += 1
    return task
end

"""Mark a task as done by ID."""
function complete!(col::TaskCollection, id::Int)::Bool
    idx = findfirst(t -> t.id == id, col.tasks)
    idx === nothing && return false
    col.tasks[idx] = Task(id, col.tasks[idx].title; done=true)
    return true
end

"""Return all pending tasks."""
pending(col::TaskCollection) = filter(t -> !t.done, col.tasks)

end # module
