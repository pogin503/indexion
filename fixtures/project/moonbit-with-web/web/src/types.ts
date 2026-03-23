/** Types shared between the MoonBit backend and TypeScript frontend. */

/** A task as returned by the API. */
export interface Task {
  id: number;
  title: string;
  description: string;
  done: boolean;
}

/** Request body for creating a task. */
export interface CreateTaskRequest {
  title: string;
  description?: string;
}

/** API response wrapper. */
export interface ApiResponse<T> {
  data: T;
  error?: string;
}
