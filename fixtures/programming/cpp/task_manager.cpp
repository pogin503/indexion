/** Represents a task. */
class Task {
    int id;
    std::string title;
    bool done;
    int summary() { return id; }
};

/** Manages a list of tasks. */
class TaskManager {
    int next_id_;
public:
    int add(std::string title);
    int pending_count();
};
