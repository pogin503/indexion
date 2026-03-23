/** Utility functions for validation and formatting. */

/**
 * Validates an email address.
 */
export function validateEmail(email: string): boolean {
  return email.includes("@");
}

/**
 * Formats a user's display name.
 */
export function formatDisplayName(name: string, role: string): string {
  return name + " (" + role + ")";
}

/** Default page size for queries. */
export const DEFAULT_PAGE_SIZE: number = 20;
