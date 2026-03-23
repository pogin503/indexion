/** Common types for the user service. */

/** Unique identifier for a user. */
export type UserId = string;

/** Represents a user in the system. */
export interface User {
  id: UserId;
  name: string;
  email: string;
  role: UserRole;
}

/** Role assigned to a user. */
export enum UserRole {
  Admin = "admin",
  Editor = "editor",
  Viewer = "viewer",
}

/** Options for querying users. */
export interface QueryOptions {
  limit?: number;
  offset?: number;
  role?: UserRole;
}
