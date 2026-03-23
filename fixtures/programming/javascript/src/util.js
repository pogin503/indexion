/**
 * Utility functions for formatting and validation.
 */

/**
 * Formats a Unix timestamp as HH:MM:SS.
 * @param {number} ms - Timestamp in milliseconds
 * @returns {string} Formatted time string
 */
export function formatTimestamp(ms) {
  const d = new Date(ms);
  const h = String(d.getHours()).padStart(2, '0');
  const m = String(d.getMinutes()).padStart(2, '0');
  const s = String(d.getSeconds()).padStart(2, '0');
  return `${h}:${m}:${s}`;
}

/** Default maximum number of listeners per event. */
export const MAX_LISTENERS = 10;
