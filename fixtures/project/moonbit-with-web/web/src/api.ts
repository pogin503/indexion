/**
 * API client — communicates with the MoonBit backend.
 */
import { Task, CreateTaskRequest, ApiResponse } from './types';

/** Base URL for the API endpoints. */
const API_BASE = '/api';

/**
 * Fetches all tasks from the backend.
 */
export async function listTasks(): Promise<Task[]> {
  const res = await fetch(API_BASE + '/tasks');
  const body: ApiResponse<Task[]> = await res.json();
  return body.data;
}

/**
 * Creates a new task via the API.
 */
export async function createTask(req: CreateTaskRequest): Promise<Task> {
  const res = await fetch(API_BASE + '/tasks', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(req),
  });
  const body: ApiResponse<Task> = await res.json();
  return body.data;
}
