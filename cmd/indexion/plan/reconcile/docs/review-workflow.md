## Review Workflow

`reconcile` separates mechanical detection from logical confirmation.

Mechanical pass:

1. Build symbol and fragment inventories.
2. Match them heuristically.
3. Compare git and mtime evidence.
4. Emit drift candidates and queue logical review tasks.

Logical pass:

- Each candidate carries `needs_logical_review`, `logical_review_key`, and evidence fields.
- Pending review tasks are stored in `records.db` and mirrored in the report.
- Re-running `reconcile` reuses pending tasks instead of opening duplicate work.

To close or update queued reviews, prepare a JSON file like:

```json
[
  {
    "review_key": "review:mechanical-digest",
    "status": "accepted",
    "verdict": "Update docs to match the current implementation."
  }
]
```

Then apply it:

```bash
indexion plan reconcile --review-results=.indexion/reconcile/reviews.json .
```

Accepted or rejected reviews stay indexed, so the same unchanged candidate is not requeued on every run.
