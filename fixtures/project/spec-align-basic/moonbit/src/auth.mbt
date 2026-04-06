/// Expire sessions after 60 minutes of inactivity.
pub fn expire_session() -> Int {
  60
}

/// Return 200 for valid login.
pub fn login_success() -> Int {
  200
}

/// Returns 429 when the client exceeded the limit.
pub fn rate_limiter() -> Int {
  429
}
