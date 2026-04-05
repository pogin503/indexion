/**
 * Apply a JSON Merge Patch (RFC 7396) to a target document.
 */
export function mergePatch(target: unknown, patch: unknown): unknown {
  if (
    patch !== null &&
    typeof patch === "object" &&
    !Array.isArray(patch)
  ) {
    let result: Record<string, unknown>;
    if (
      target !== null &&
      typeof target === "object" &&
      !Array.isArray(target)
    ) {
      result = { ...(target as Record<string, unknown>) };
    } else {
      result = {};
    }
    for (const [name, value] of Object.entries(
      patch as Record<string, unknown>
    )) {
      if (value === null) {
        delete result[name];
      } else {
        result[name] = mergePatch(result[name], value);
      }
    }
    return result;
  }
  return patch;
}
