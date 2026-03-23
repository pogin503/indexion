--- Task manager module — manages tasks in memory.
-- @module task_manager

local TaskManager = {}
TaskManager.__index = TaskManager

--- Creates a new task manager.
-- @return TaskManager instance
function TaskManager.new()
    local self = setmetatable({}, TaskManager)
    self.tasks = {}
    self.next_id = 1
    return self
end

--- Adds a task with the given title.
-- @param title string
-- @return task table
function TaskManager:add(title)
    local task = {
        id = self.next_id,
        title = title,
        done = false,
    }
    self.tasks[self.next_id] = task
    self.next_id = self.next_id + 1
    return task
end

--[[ Marks a task as done by ID.
     Returns true if found, false otherwise. ]]
function TaskManager:complete(id)
    local task = self.tasks[id]
    if not task then return false end
    task.done = true
    return true
end

--- Returns all pending tasks.
-- @return table list of tasks
function TaskManager:pending()
    local result = {}
    for _, task in pairs(self.tasks) do
        if not task.done then
            table.insert(result, task)
        end
    end
    return result
end

return TaskManager
