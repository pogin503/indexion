using System;
using System.Collections.Generic;
using System.Linq;

namespace Example.Services;

/// <summary>
/// Manages user accounts — supports lookup and creation.
/// </summary>
public class UserService
{
    private readonly Dictionary<int, User> _store = new();

    /// <summary>Adds a user to the store.</summary>
    public void Add(User user)
    {
        _store[user.Id] = user;
    }

    /// <summary>Finds a user by ID, or null if not found.</summary>
    public User? FindById(int id)
    {
        return _store.GetValueOrDefault(id);
    }

    /// <summary>Returns all users sorted by name.</summary>
    public IReadOnlyList<User> ListAll()
    {
        return _store.Values.OrderBy(u => u.Name).ToList();
    }
}

/// <summary>Represents a user in the system.</summary>
public record User(int Id, string Name, string Email);
