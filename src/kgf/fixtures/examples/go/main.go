// Package main provides the entry point
package main

import (
	"context"
	"fmt"
	"sync"
	"time"
)

// User represents a user in the system
type User struct {
	ID    int64
	Name  string
	Email string
}

// UserService handles user operations
type UserService interface {
	GetUser(ctx context.Context, id int64) (*User, error)
	CreateUser(ctx context.Context, user *User) error
}

// InMemoryUserService is an in-memory implementation
type InMemoryUserService struct {
	mu    sync.RWMutex
	users map[int64]*User
}

// NewInMemoryUserService creates a new service
func NewInMemoryUserService() *InMemoryUserService {
	return &InMemoryUserService{
		users: make(map[int64]*User),
	}
}

// GetUser retrieves a user by ID
func (s *InMemoryUserService) GetUser(ctx context.Context, id int64) (*User, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	user, ok := s.users[id]
	if !ok {
		return nil, fmt.Errorf("user not found: %d", id)
	}
	return user, nil
}

// CreateUser adds a new user
func (s *InMemoryUserService) CreateUser(ctx context.Context, user *User) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if _, exists := s.users[user.ID]; exists {
		return fmt.Errorf("user already exists: %d", user.ID)
	}
	s.users[user.ID] = user
	return nil
}

func main() {
	ctx := context.Background()
	svc := NewInMemoryUserService()

	// Create users concurrently
	var wg sync.WaitGroup
	for i := int64(1); i <= 5; i++ {
		wg.Add(1)
		go func(id int64) {
			defer wg.Done()
			user := &User{
				ID:    id,
				Name:  fmt.Sprintf("User%d", id),
				Email: fmt.Sprintf("user%d@example.com", id),
			}
			if err := svc.CreateUser(ctx, user); err != nil {
				fmt.Printf("Error: %v\n", err)
			}
		}(i)
	}
	wg.Wait()

	// Retrieve and print users
	for i := int64(1); i <= 5; i++ {
		if user, err := svc.GetUser(ctx, i); err == nil {
			fmt.Printf("Found: %+v\n", user)
		}
	}

	// Channel example
	ch := make(chan string, 3)
	ch <- "hello"
	ch <- "world"
	close(ch)

	for msg := range ch {
		fmt.Println(msg)
	}

	// Select with timeout
	select {
	case <-time.After(100 * time.Millisecond):
		fmt.Println("Timeout!")
	}
}
