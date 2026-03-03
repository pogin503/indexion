//! Main entry point for the application

use std::collections::HashMap;
use std::io::{self, Write};

/// A simple user struct
#[derive(Debug, Clone)]
pub struct User {
    pub id: u64,
    pub name: String,
    pub email: Option<String>,
}

impl User {
    /// Create a new user
    pub fn new(id: u64, name: &str) -> Self {
        Self {
            id,
            name: name.to_string(),
            email: None,
        }
    }

    /// Set the user's email
    pub fn with_email(mut self, email: &str) -> Self {
        self.email = Some(email.to_string());
        self
    }
}

/// Calculate factorial using recursion
fn factorial(n: u64) -> u64 {
    match n {
        0 | 1 => 1,
        _ => n * factorial(n - 1),
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let mut users: HashMap<u64, User> = HashMap::new();

    // Create some users
    let user1 = User::new(1, "Alice")
        .with_email("alice@example.com");
    let user2 = User::new(2, "Bob");

    users.insert(user1.id, user1);
    users.insert(user2.id, user2);

    // Iterate and print
    for (id, user) in &users {
        println!("User {}: {:?}", id, user);
    }

    // Calculate factorial
    let n = 10;
    println!("{}! = {}", n, factorial(n));

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_factorial() {
        assert_eq!(factorial(0), 1);
        assert_eq!(factorial(5), 120);
    }
}
