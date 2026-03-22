# semantics

## API

- **`SemEvalCtx`** (Struct) — SemEvalCtx represents the evaluation context for semantics processing.
- **`eval_rule_semantics`** (Function) — Evaluates semantics for a rule by name.
- **`eval_rule_attrs`** (Function) — Evaluates attrs for a rule by name.
- **`Env`** (Struct) — Env represents the evaluation environment with PEG labels and local variables.
- **`eval_func_obj`** (Function) — Evaluates the obj() function to create an object from key-value pairs.
- **`lookup_scope`** (Function) — Looks up a name in the scope stack (searches from top to bottom).
- **`eval_call`** (Function) — Evaluates a special call expression ($resolve, $scope, etc.).
- **`is_relative_path`** (Function) — Checks if a path is relative (starts with ./ or ../ or /).
- **`collect_refs`** (Function) — Collects and removes all Ref events from the events list.
- **`eval_func`** (Function) — Evaluates a function expression (concat, obj, etc.).
- **`trim_string`** (Function) — Trims leading and trailing whitespace from a string.
- **`is_valid_hex`** (Function) — Checks if a string is a valid hexadecimal number.
- **`current_call_id`** (Function) — Gets the current call ID from the call stack.
- **`is_hex_char`** (Function) — Checks if a character is a valid hex digit.
- **`get`** (Function) — Gets a value from locals or labels by name.

And 62 more symbols.
