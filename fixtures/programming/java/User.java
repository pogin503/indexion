package com.example.service;

/** Represents a user in the system. */
public record User(long id, String name, String email) {

    /** Returns a display string. */
    public String displayName() {
        return name + " <" + email + ">";
    }
}
