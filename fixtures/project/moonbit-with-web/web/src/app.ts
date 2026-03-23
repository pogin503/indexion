/**
 * Main application — initializes the task list UI.
 */
import { listTasks, createTask } from './api';
import { Task } from './types';

/** Renders a task list to the console (placeholder for real UI). */
function renderTasks(tasks: Task[]): void {
  for (const task of tasks) {
    const status = task.done ? '✓' : '○';
    console.log(status + ' [' + task.id + '] ' + task.title);
  }
}

/** Entry point. */
async function main(): Promise<void> {
  await createTask({ title: 'Set up CI', description: 'Configure GitHub Actions' });
  await createTask({ title: 'Write tests' });
  const tasks = await listTasks();
  renderTasks(tasks);
}

export default main;
