<?php

namespace App\Repository;

use App\Model\User;

/**
 * Repository for user persistence — wraps database access.
 */
class UserRepository
{
    /** @var array<int, User> */
    private array $store = [];

    /**
     * Saves a user to the store.
     */
    public function save(User $user): void
    {
        $this->store[$user->id] = $user;
    }

    /** Finds a user by ID. */
    public function findById(int $id): ?User
    {
        return $this->store[$id] ?? null;
    }

    /** Returns all stored users. */
    public function findAll(): array
    {
        return array_values($this->store);
    }
}
