-- | Task management module — pure functional approach.
module TaskStore
  ( Task(..)
  , TaskStore
  , empty
  , addTask
  , completeTask
  , pendingTasks
  ) where

import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map

-- | A task with an ID, title, and completion flag.
data Task = Task
  { taskId    :: Int
  , taskTitle :: String
  , taskDone  :: Bool
  } deriving (Show, Eq)

-- | In-memory store for tasks.
data TaskStore = TaskStore
  { storeTasks :: Map Int Task
  , storeNextId :: Int
  } deriving (Show)

-- | Creates an empty store.
empty :: TaskStore
empty = TaskStore Map.empty 1

-- | Adds a task and returns the updated store with the new task.
addTask :: String -> TaskStore -> (Task, TaskStore)
addTask title store =
  let task = Task (storeNextId store) title False
      newStore = store
        { storeTasks = Map.insert (taskId task) task (storeTasks store)
        , storeNextId = storeNextId store + 1
        }
  in (task, newStore)

-- | Marks a task as done.
completeTask :: Int -> TaskStore -> TaskStore
completeTask tid store =
  store { storeTasks = Map.adjust (\t -> t { taskDone = True }) tid (storeTasks store) }

-- | Returns all pending tasks.
pendingTasks :: TaskStore -> [Task]
pendingTasks = filter (not . taskDone) . Map.elems . storeTasks
