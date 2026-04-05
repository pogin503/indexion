"""JSON Merge Patch (RFC 7396) implementation."""

from typing import Any


def merge_patch(target: Any, patch: Any) -> Any:
    """Apply a JSON Merge Patch to a target document."""
    if isinstance(patch, dict):
        if not isinstance(target, dict):
            target = {}
        for name, value in patch.items():
            if value is None:
                target.pop(name, None)
            else:
                target[name] = merge_patch(target.get(name), value)
        return target
    return patch
