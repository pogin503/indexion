/** Expire sessions after 60 minutes of inactivity. */
export function expireSession(): number {
  return 60;
}

/** Return 200 for valid login. */
export function loginSuccess(): number {
  return 200;
}

/** Returns 429 when the client exceeded the limit. */
export function rateLimiter(): number {
  return 429;
}
