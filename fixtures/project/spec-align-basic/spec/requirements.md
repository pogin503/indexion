## Requirement 1: Session Timeout
The system SHALL expire sessions after 15 minutes of inactivity.

### Scenario: Session expires
- GIVEN an authenticated session
- WHEN 15 minutes pass without activity
- THEN the session is invalidated

## Requirement 2: Login Success
The system SHALL return `200` for valid login.

### Scenario: Successful login
- GIVEN a valid username and password
- WHEN the login form is submitted
- THEN the response status is `200`

## Requirement 3: OAuth Support
As a user, I want to sign in with Google OAuth.
