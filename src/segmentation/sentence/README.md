# sentence

## API

- **`split_sentences`** (Function) — Split text into sentences with default options (quote protection enabled).
- **`split_sentences_with_options`** (Function) — Split text into sentences with custom options.
- **`is_opening_quote`** (Function) — Check if a character is an opening quote (Japanese only for reliable protection).
- **`default_quote_safe_max_length`** (Variable) — Default maximum length protected from punctuation splitting inside quotes.
- **`update_quote_stack`** (Function) — Update the quote stack based on the current character.
- **`is_extended_sentence_end`** (Function) — Check if a character is an extended sentence terminator (including closing brackets).
- **`is_closing_quote`** (Function) — Check if a character is a closing quote (Japanese only for reliable protection).
- **`split_sentences_text_with_options`** (Function) — Split text into sentences with custom options and return only the text content.
- **`is_trailing_punctuation`** (Function) — Check if a character is trailing punctuation that can follow a terminator.
- **`is_inside_protected_quote`** (Function) — Check if currently inside a protected quote (under max length).
- **`is_sentence_end`** (Function) — Check if a character is a sentence-ending punctuation mark.
- **`split_sentences_text`** (Function) — Split text into sentences and return only the text content.
- **`count_sentences_with_options`** (Function) — Count the number of sentences in text with custom options.
- **`Sentence`** (Struct) — A sentence extracted from text with position information.
- **`QuoteStackEntry`** (Struct) — Entry on the quote stack for tracking nested quotes.

And 25 more symbols.
