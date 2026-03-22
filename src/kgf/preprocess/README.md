# preprocess

## API

- **`classify_char`** (Function) — Classifies a character according to the FST's character classes.
- **`compile_char_class`** (Function) — Compiles a character class pattern into a CompiledCharClass.
- **`run_fst`** (Function) — Runs a compiled FST over the input string and returns the transformed output.
- **`CompiledFst`** (Struct) — CompiledFst represents a compiled FST ready for execution.
- **`char_matches_class`** (Function) — Checks if a character matches a compiled character class.
- **`match_transition`** (Function) — Finds a matching transition for the given input class.
- **`is_base64_char`** (Function) — Checks if a character is a valid base64 character.
- **`byte_to_hex`** (Function) — Converts a byte to uppercase hexadecimal string.
- **`sextet`** (Function) — Converts a base64 character to its sextet value.
- **`decode_quartet`** (Function) — Decodes a quartet of base64 sextets into bytes.
- **`base64_value`** (Function) — Gets the numeric value of a base64 character.
- **`base64_to_hex`** (Function) — Converts a base64 string to hexadecimal.
- **`is_ctrl_byte`** (Function) — Checks if a byte is a control character.
- **`Utf8Agg`** (Enum) — UTF-8 aggregate classification result.
- **`classify_utf8`** (Function) — Classifies a byte array as UTF-8 text.

And 33 more symbols.
