package com.example.service;

import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.Optional;

/**
 * Service for managing users — supports CRUD operations.
 */
public class UserService {
    private final Map<Long, User> store = new HashMap<>();

    /**
     * Adds a user to the store.
     * @param user the user to add
     */
    public void addUser(User user) {
        store.put(user.getId(), user);
    }

    /** Retrieves a user by ID. */
    public Optional<User> getUser(long id) {
        return Optional.ofNullable(store.get(id));
    }

    /** Lists all users. */
    public List<User> listUsers() {
        return List.copyOf(store.values());
    }
}
