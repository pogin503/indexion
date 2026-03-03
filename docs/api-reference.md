# API Reference

## Structs

### ContentHash

Content hash (SHA-256 truncated to 32 hex characters). Used as content-addressed identifier for chunks.

**Module:** `src/kgf/cas/types/types.mbt`

### SymbolicRef

A symbolic reference to an external module (not yet resolved). Examples: - "npm:lodash" - external npm package - "@myorg/core:src/utils.ts" - workspace package module - "shared:src/helpers.ts" - unscoped workspace package

**Module:** `src/kgf/cas/types/types.mbt`

### ModuleChunk

A chunk represents a single module's contribution to the graph. Each source file produces one chunk containing: - The module node itself - All symbols declared in that module - All edges originating from that module - References to external modules (symbolic, resolved later)

**Module:** `src/kgf/cas/types/types.mbt`

### CASManifest

Root manifest for a KGF CAS store. This is the entry point for accessing the cached graph.

**Module:** `src/kgf/cas/types/types.mbt`

### IndexError

Error information for indexing failures.

**Module:** `src/kgf/cas/types/types.mbt`

### AssemblyResult

Result of graph assembly.

**Module:** `src/kgf/cas/assembler/assembler.mbt`

### MemoryChunkStore

In-memory chunk store implementation. Useful for testing and short-lived sessions where persistence isn't needed.

**Module:** `src/kgf/cas/store/store.mbt`

### KGFSpec

KGFSpec represents the complete KGF specification for a language. Contains tokens, rules, attributes, resolver configuration, semantics, and preprocessing options.

**Module:** `src/kgf/types/spec.mbt`

### FstTransition

FstTransition represents a single state transition in the FST.

**Module:** `src/kgf/types/preprocess.mbt`

### PreprocessFstSpec

PreprocessFstSpec represents a JSON-defined preprocess FST specification.

**Module:** `src/kgf/types/preprocess.mbt`

### RuleDef

RuleDef represents a grammar rule definition. Contains the rule name and its expression.

**Module:** `src/kgf/types/rule.mbt`

### AttrAction

AttrAction represents an attribute action in the grammar. Kind can be: "def", "ref", "call", "argref", "import", "reexport", "scope", "arg_begin", "arg_end", "call_end", etc.

**Module:** `src/kgf/types/rule.mbt`

### TokenDef

TokenDef represents a token definition in the KGF grammar. Contains the token name, regex pattern, skip flag, and optional flags.

**Module:** `src/kgf/types/token.mbt`

### Tok

Tok represents a lexed token with position information.

**Module:** `src/kgf/types/token.mbt`

### ResolverAlias

ResolverAlias represents a path alias for module resolution.

**Module:** `src/kgf/types/resolver.mbt`

### ResolverSpec

ResolverSpec represents the configuration for module resolution.

**Module:** `src/kgf/types/resolver.mbt`

### SemOnBlock

SemOnBlock represents a semantic on-block definition. Contains a rule name, optional when condition, then statements, and optional else statements.

**Module:** `src/kgf/types/semantics.mbt`

### MatchResult

Result of a pattern match attempt. Contains whether the match succeeded, the end position, and the matched text.

**Module:** `src/kgf/lexer/pattern_matcher.mbt`

### Lexer

Lexer transforms input text into tokens based on token definitions.

**Module:** `src/kgf/lexer/lexer.mbt`

### LexerBuilder

Builder for constructing a Lexer with token definitions.

**Module:** `src/kgf/lexer/lexer.mbt`

### CompiledCharClass

CompiledCharClass represents a compiled character class for matching.

**Module:** `src/kgf/preprocess/fst.mbt`

### CompiledFst

CompiledFst represents a compiled FST ready for execution.

**Module:** `src/kgf/preprocess/fst.mbt`

### ScopeEntry

ScopeEntry represents a single scope frame with value and type namespaces.

**Module:** `src/kgf/semantics/context.mbt`

### Env

Env represents the evaluation environment with PEG labels and local variables.

**Module:** `src/kgf/semantics/context.mbt`

### SemEvalCtx

SemEvalCtx represents the evaluation context for semantics processing. Note: file_exists is a function that checks if a file exists at the given path.

**Module:** `src/kgf/semantics/context.mbt`

### EvalResult

EvalResult represents the result of a PEG evaluation.

**Module:** `src/kgf/peg/eval.mbt`

### MemoKey

Memo key for memoization.

**Module:** `src/kgf/peg/eval.mbt`

### EvalContext

EvalContext holds the evaluation state.

**Module:** `src/kgf/peg/eval.mbt`

### PEG

PEG represents a compiled PEG grammar with parsed rule ASTs.

**Module:** `src/kgf/peg/peg.mbt`

### MockFileResolver

Mock file resolver for testing.

**Module:** `src/kgf/resolver/resolver_wbtest.mbt`

### ModuleNode

Module node representing a source file or module in the codebase.

**Module:** `src/core/graph/types.mbt`

### SymbolNode

Symbol node representing a named entity (function, type, variable, etc.).

**Module:** `src/core/graph/types.mbt`

### Edge

Edge representing a directed relationship between two nodes.

**Module:** `src/core/graph/types.mbt`

### CodeGraph

The main code graph structure containing modules, symbols, and edges.

**Module:** `src/core/graph/types.mbt`

### FindBoundariesOptions

Options for finding sentence boundaries.

**Module:** `src/segmentation/utils/types.mbt`

### QuoteStackEntry

Entry in the quote tracking stack.

**Module:** `src/segmentation/utils/types.mbt`

### SplitOptions

Options for sentence splitting.

**Module:** `src/segmentation/sentence/splitter.mbt`

### Sentence

A sentence extracted from text with position information.

**Module:** `src/segmentation/sentence/types.mbt`

### SegmentConfig

Configuration for segmentation.

**Module:** `src/segmentation/window/types.mbt`

### AdaptiveConfig

Configuration for adaptive segmentation. Adaptive mode dynamically determines threshold based on divergence distribution.

**Module:** `src/segmentation/window/types.mbt`

### WindowStrategy

Window-based divergence segmentation strategy. Implements SegmentationStrategy trait.

**Module:** `src/segmentation/window/types.mbt`

### PunctuationConfig

Configuration for punctuation-based chunking.

**Module:** `src/segmentation/punctuation/types.mbt`

### PunctuationStrategy

Punctuation-based segmentation strategy. Implements SegmentationStrategy trait.

**Module:** `src/segmentation/punctuation/types.mbt`

### SegmentPoint

A lightweight segment point without text content. Used for efficient processing when the client already has the original text.

**Module:** `src/segmentation/types.mbt`

### TextSegment

Full segment with extracted text content.

**Module:** `src/segmentation/types.mbt`

### WindowDivergence

Result of window divergence calculation. Shared by tfidf and window segmentation strategies.

**Module:** `src/segmentation/types.mbt`

### TfidfConfig

Configuration for TF-IDF based segmentation.

**Module:** `src/segmentation/tfidf/types.mbt`

### TfidfStrategy

TF-IDF based segmentation strategy. Implements SegmentationStrategy trait.

**Module:** `src/segmentation/tfidf/types.mbt`

### ComponentDoc

Documentation extracted from source file comments. Represents a component or module with its documentation.

**Module:** `src/docgen/types/types.mbt`

### TokenInfo

Information about a design token (CSS variable).

**Module:** `src/docgen/types/types.mbt`

### TokenGroup

A group of related tokens.

**Module:** `src/docgen/types/types.mbt`

### RenderOptions

Render options for documentation generation.

**Module:** `src/docgen/render/types.mbt`

### DocOutput

Complete documentation output.

**Module:** `src/docgen/render/types.mbt`

### AnalysisResult

Result of the complete analysis pipeline.

**Module:** `src/docgen/analyze/types.mbt`

### DocConfig

Documentation generation configuration.

**Module:** `src/docgen/build/types.mbt`

### ModuleDep

Module dependency information extracted from ModuleDependsOn edges.

**Module:** `src/docgen/query/types.mbt`

### CallInfo

Call relationship extracted from Calls edges.

**Module:** `src/docgen/query/types.mbt`

### TypeRelation

Type hierarchy relationship extracted from Extends/Implements edges.

**Module:** `src/docgen/query/types.mbt`

### SymbolRef

Symbol reference extracted from References edges.

**Module:** `src/docgen/query/types.mbt`

### SymbolDecl

Symbol declaration with documentation.

**Module:** `src/docgen/query/types.mbt`

### TfidfVector

A sparse TF-IDF vector representation using term-weight mapping.

**Module:** `src/text/tfidf/types.mbt`

## Enums

### IndexModuleResult

Result of indexing a single module.

**Module:** `src/kgf/cas/types/types.mbt`

### FstAction

FstAction represents an action to perform during FST state transition.

**Module:** `src/kgf/types/preprocess.mbt`

### ModulePathStyle

ModulePathStyle represents the style of module path separators.

**Module:** `src/kgf/types/resolver.mbt`

### SemExpr

SemExpr represents a semantic expression in the KGF DSL.

**Module:** `src/kgf/types/semantics.mbt`

### SemStmt

SemStmt represents a semantic statement in the KGF DSL.

**Module:** `src/kgf/types/semantics.mbt`

### Node

PEG AST Node types representing the parsed grammar expression.

**Module:** `src/kgf/peg/node.mbt`

### EdgeKind

Edge kinds representing relationships between nodes.

**Module:** `src/core/graph/types.mbt`

### OutputFormat

Output format selection.

**Module:** `src/docgen/render/types.mbt`

## Functions

### SymbolicRef::new

Create a new SymbolicRef.

**Module:** `src/kgf/cas/types/types.mbt`

### ModuleChunk::new

Create a new ModuleChunk.

**Module:** `src/kgf/cas/types/types.mbt`

### ModuleChunk::add_symbol

Add a symbol to the chunk.

**Module:** `src/kgf/cas/types/types.mbt`

### ModuleChunk::add_edge

Add an edge to the chunk.

**Module:** `src/kgf/cas/types/types.mbt`

### ModuleChunk::add_external_ref

Add an external reference to the chunk.

**Module:** `src/kgf/cas/types/types.mbt`

### ContentHash::to_string

Get the ContentHash value as a String.

**Module:** `src/kgf/cas/types/types.mbt`

### ContentHash::from_string

Create a ContentHash from a String (no validation).

**Module:** `src/kgf/cas/types/types.mbt`

### CASManifest::new

Create a new CASManifest.

**Module:** `src/kgf/cas/types/types.mbt`

### CASManifest::with_modules

Create a new CASManifest with updated modules.

**Module:** `src/kgf/cas/types/types.mbt`

### CASManifest::with_spec_hash

Create a new CASManifest with new spec hash (clears modules).

**Module:** `src/kgf/cas/types/types.mbt`

### assemble_graph

Assemble a complete CodeGraph from cached chunks.

**Module:** `src/kgf/cas/assembler/assembler.mbt`

### merge_chunk

Merge a chunk into the graph.

**Module:** `src/kgf/cas/assembler/assembler.mbt`

### assemble_partial_graph

Assemble graph for specific modules only.

**Module:** `src/kgf/cas/assembler/assembler.mbt`

### get_manifest_stats

Get summary statistics for the manifest.

**Module:** `src/kgf/cas/assembler/assembler.mbt`

### validate_manifest

Validate that all chunks referenced in manifest exist in store.

**Module:** `src/kgf/cas/assembler/assembler.mbt`

### AssemblyResult::empty

Create an empty assembly result.

**Module:** `src/kgf/cas/assembler/assembler.mbt`

### AssemblyResult::is_complete

Check if the assembly was successful (no missing chunks).

**Module:** `src/kgf/cas/assembler/assembler.mbt`

### AssemblyResult::all_resolved

Check if all references were resolved.

**Module:** `src/kgf/cas/assembler/assembler.mbt`

### rotr

Right rotate a 32-bit unsigned integer.

**Module:** `src/kgf/cas/hash/hash.mbt`

### sha256_block

SHA-256 compression function.

**Module:** `src/kgf/cas/hash/hash.mbt`

### string_to_bytes

Convert string to UTF-8 bytes.

**Module:** `src/kgf/cas/hash/hash.mbt`

### sha256

Pure MoonBit SHA-256 implementation.

**Module:** `src/kgf/cas/hash/hash.mbt`

### compute_hash

Compute SHA-256 hash of content, truncated to 32 hex characters.

**Module:** `src/kgf/cas/hash/hash.mbt`

### compute_spec_hash

Compute hash of a KGF spec for cache invalidation. When spec changes, all chunks need to be regenerated.

**Module:** `src/kgf/cas/hash/hash.mbt`

### compute_chunk_hash

Compute hash for a module chunk based on its contents. Used to generate the chunk's content-addressed ID.

**Module:** `src/kgf/cas/hash/hash.mbt`

### is_valid_hash

Validate that a string looks like a valid ContentHash (32 hex characters).

**Module:** `src/kgf/cas/hash/hash.mbt`

### as_content_hash

Create a ContentHash from a string (with validation). Returns None if the string is not a valid hash format.

**Module:** `src/kgf/cas/hash/hash.mbt`

### create_manifest

Create an empty manifest with the given spec hash.

**Module:** `src/kgf/cas/manifest/manifest.mbt`

### get_timestamp

Get current timestamp as ISO 8601 string. Note: This is a placeholder implementation for MoonBit. In production, this would use actual system time.

**Module:** `src/kgf/cas/manifest/manifest.mbt`

### update_manifest

Update manifest with a new module chunk. Returns a new manifest with the updated module mapping.

**Module:** `src/kgf/cas/manifest/manifest.mbt`

### remove_module

Remove a module from the manifest. Returns a new manifest without the specified module.

**Module:** `src/kgf/cas/manifest/manifest.mbt`

### is_chunk_valid

Check if a chunk for a module is still valid given the current source hash. A chunk is valid if: 1. The module exists in the manifest 2. The chunk exists in the store 3. The source hash matches 4. The spec hash matches

**Module:** `src/kgf/cas/manifest/manifest.mbt`

### get_chunk_hash

Get the chunk hash for a module if it exists.

**Module:** `src/kgf/cas/manifest/manifest.mbt`

### has_module

Check if a module exists in the manifest.

**Module:** `src/kgf/cas/manifest/manifest.mbt`

### get_module_ids

Get all module IDs in the manifest.

**Module:** `src/kgf/cas/manifest/manifest.mbt`

### get_chunk_hashes

Get all chunk hashes referenced in the manifest.

**Module:** `src/kgf/cas/manifest/manifest.mbt`

### module_count

Count the number of modules in the manifest.

**Module:** `src/kgf/cas/manifest/manifest.mbt`

### is_empty

Check if the manifest is empty.

**Module:** `src/kgf/cas/manifest/manifest.mbt`

### spec_matches

Check if the spec hash matches.

**Module:** `src/kgf/cas/manifest/manifest.mbt`

### update_spec_hash

Create a new manifest with updated spec hash. This effectively invalidates all cached chunks.

**Module:** `src/kgf/cas/manifest/manifest.mbt`

### merge

Merge another manifest into this one. Modules from the other manifest override this one.

**Module:** `src/kgf/cas/manifest/manifest.mbt`

### MemoryChunkStore::new

Create a new in-memory chunk store.

**Module:** `src/kgf/cas/store/store.mbt`

### MemoryChunkStore::get

Read a chunk by its hash.

**Module:** `src/kgf/cas/store/store.mbt`

### MemoryChunkStore::put

Write a chunk (stores using its hash).

**Module:** `src/kgf/cas/store/store.mbt`

### MemoryChunkStore::has

Check if a chunk exists.

**Module:** `src/kgf/cas/store/store.mbt`

### MemoryChunkStore::delete

Delete a chunk.

**Module:** `src/kgf/cas/store/store.mbt`

### MemoryChunkStore::list

List all chunk hashes.

**Module:** `src/kgf/cas/store/store.mbt`

### MemoryChunkStore::size

Get the number of chunks in the store.

**Module:** `src/kgf/cas/store/store.mbt`

### MemoryChunkStore::clear

Clear all chunks from the store.

**Module:** `src/kgf/cas/store/store.mbt`

### MemoryChunkStore::find_orphans

Find orphaned chunks (chunks not referenced in a set of known hashes).

**Module:** `src/kgf/cas/store/store.mbt`

### MemoryChunkStore::clean_orphans

Clean up orphaned chunks. Returns the number of chunks deleted.

**Module:** `src/kgf/cas/store/store.mbt`

### KGFSpec::new

Creates a new KGFSpec with the specified parameters.

**Module:** `src/kgf/types/spec.mbt`

### KGFSpec::get_language

Returns the language name.

**Module:** `src/kgf/types/spec.mbt`

### KGFSpec::get_tokens

Returns the tokens.

**Module:** `src/kgf/types/spec.mbt`

### KGFSpec::get_rules

Returns the rules.

**Module:** `src/kgf/types/spec.mbt`

### KGFSpec::get_rule

Returns a specific rule by name.

**Module:** `src/kgf/types/spec.mbt`

### KGFSpec::get_attrs

Returns the attributes.

**Module:** `src/kgf/types/spec.mbt`

### KGFSpec::get_attr

Returns a specific attribute actions by name.

**Module:** `src/kgf/types/spec.mbt`

### KGFSpec::get_resolver

Returns the resolver configuration.

**Module:** `src/kgf/types/spec.mbt`

### KGFSpec::get_semantics

Returns the semantics.

**Module:** `src/kgf/types/spec.mbt`

### KGFSpec::get_semantic

Returns specific semantic blocks by rule name.

**Module:** `src/kgf/types/spec.mbt`

### KGFSpec::get_preprocess

Returns the preprocess directives.

**Module:** `src/kgf/types/spec.mbt`

### KGFSpec::get_preprocess_fst

Returns the preprocess FST specifications.

**Module:** `src/kgf/types/spec.mbt`

### KGFSpec::get_start_rule

Returns the start rule name. Uses convention: "Module" > "Program" > "Doc" > "File" > first rule found.

**Module:** `src/kgf/types/spec.mbt`

### FstAction::emit_input

Creates an EmitInput action.

**Module:** `src/kgf/types/preprocess.mbt`

### FstAction::emit

Creates an Emit action with the specified value.

**Module:** `src/kgf/types/preprocess.mbt`

### FstAction::buf

Creates a Buf action.

**Module:** `src/kgf/types/preprocess.mbt`

### FstAction::flush

Creates a Flush action with the specified padding.

**Module:** `src/kgf/types/preprocess.mbt`

### FstTransition::new

Creates a new FstTransition.

**Module:** `src/kgf/types/preprocess.mbt`

### FstTransition::get_on

Returns the input class to match.

**Module:** `src/kgf/types/preprocess.mbt`

### FstTransition::get_to

Returns the target state.

**Module:** `src/kgf/types/preprocess.mbt`

### FstTransition::get_actions

Returns the actions to execute.

**Module:** `src/kgf/types/preprocess.mbt`

### PreprocessFstSpec::new

Creates a new PreprocessFstSpec.

**Module:** `src/kgf/types/preprocess.mbt`

### PreprocessFstSpec::get_name

Returns the FST name.

**Module:** `src/kgf/types/preprocess.mbt`

### PreprocessFstSpec::get_classes

Returns the character classes.

**Module:** `src/kgf/types/preprocess.mbt`

### PreprocessFstSpec::get_initial

Returns the initial state name.

**Module:** `src/kgf/types/preprocess.mbt`

### PreprocessFstSpec::get_states

Returns the states.

**Module:** `src/kgf/types/preprocess.mbt`

### RuleDef::new

Creates a new RuleDef with the specified parameters.

**Module:** `src/kgf/types/rule.mbt`

### RuleDef::get_name

Returns the name of the rule.

**Module:** `src/kgf/types/rule.mbt`

### RuleDef::get_expr

Returns the expression of the rule.

**Module:** `src/kgf/types/rule.mbt`

### AttrAction::new

Creates a new AttrAction with the specified parameters.

**Module:** `src/kgf/types/rule.mbt`

### AttrAction::get_kind

Returns the kind of the attribute action.

**Module:** `src/kgf/types/rule.mbt`

### AttrAction::get_params

Returns the params of the attribute action.

**Module:** `src/kgf/types/rule.mbt`

### AttrAction::get_param

Returns a specific parameter value by key.

**Module:** `src/kgf/types/rule.mbt`

### TokenDef::new

Creates a new TokenDef with the specified parameters.

**Module:** `src/kgf/types/token.mbt`

### TokenDef::get_name

Returns the name of the token.

**Module:** `src/kgf/types/token.mbt`

### TokenDef::get_pattern

Returns the pattern of the token.

**Module:** `src/kgf/types/token.mbt`

### TokenDef::is_skip

Returns whether this token should be skipped.

**Module:** `src/kgf/types/token.mbt`

### TokenDef::get_flags

Returns the flags of the token if any.

**Module:** `src/kgf/types/token.mbt`

### Tok::new

Creates a new Tok with the specified parameters.

**Module:** `src/kgf/types/token.mbt`

### Tok::get_kind

Returns the kind of the token.

**Module:** `src/kgf/types/token.mbt`

### Tok::get_text

Returns the text of the token.

**Module:** `src/kgf/types/token.mbt`

### Tok::get_value

Returns the value of the token (first capture group when present). Defaults to text if not set.

**Module:** `src/kgf/types/token.mbt`

### Tok::get_pos

Returns the position of the token in the source.

**Module:** `src/kgf/types/token.mbt`

### ModulePathStyle::from_string

Converts a string to ModulePathStyle.

**Module:** `src/kgf/types/resolver.mbt`

### ModulePathStyle::as_string

Converts ModulePathStyle to string representation.

**Module:** `src/kgf/types/resolver.mbt`

### ResolverAlias::new

Creates a new ResolverAlias with the specified parameters.

**Module:** `src/kgf/types/resolver.mbt`

### ResolverAlias::get_pattern

Returns the pattern of the alias.

**Module:** `src/kgf/types/resolver.mbt`

### ResolverAlias::get_replace

Returns the replacement of the alias.

**Module:** `src/kgf/types/resolver.mbt`

### ResolverSpec::new

Creates a new ResolverSpec with the specified parameters.

**Module:** `src/kgf/types/resolver.mbt`

### ResolverSpec::get_sources

Returns the sources directories.

**Module:** `src/kgf/types/resolver.mbt`

### ResolverSpec::get_relative_prefixes

Returns the relative prefixes.

**Module:** `src/kgf/types/resolver.mbt`

### ResolverSpec::get_exts

Returns the file extensions.

**Module:** `src/kgf/types/resolver.mbt`

### ResolverSpec::get_indexes

Returns the index file names.

**Module:** `src/kgf/types/resolver.mbt`

### ResolverSpec::get_bare_prefix

Returns the bare prefix.

**Module:** `src/kgf/types/resolver.mbt`

### ResolverSpec::get_module_path_style

Returns the module path style.

**Module:** `src/kgf/types/resolver.mbt`

### ResolverSpec::get_aliases

Returns the aliases.

**Module:** `src/kgf/types/resolver.mbt`

### ResolverSpec::get_ns_prefix

Returns the namespace prefix.

**Module:** `src/kgf/types/resolver.mbt`

### ResolverSpec::get_ns_segments

Returns the namespace segments count.

**Module:** `src/kgf/types/resolver.mbt`

### ResolverSpec::is_rust_mod_mode

Returns whether rust mod mode is enabled.

**Module:** `src/kgf/types/resolver.mbt`

### ResolverSpec::get_cargo_auto_from_roots

Returns the cargo auto from roots.

**Module:** `src/kgf/types/resolver.mbt`

### SemExpr::str

Creates a string expression.

**Module:** `src/kgf/types/semantics.mbt`

### SemExpr::num

Creates a number expression.

**Module:** `src/kgf/types/semantics.mbt`

### SemExpr::bool

Creates a boolean expression.

**Module:** `src/kgf/types/semantics.mbt`

### SemExpr::null

Creates a null expression.

**Module:** `src/kgf/types/semantics.mbt`

### SemExpr::variable

Creates a variable expression.

**Module:** `src/kgf/types/semantics.mbt`

### SemExpr::call

Creates a call expression.

**Module:** `src/kgf/types/semantics.mbt`

### SemExpr::func

Creates a function expression.

**Module:** `src/kgf/types/semantics.mbt`

### SemStmt::edge

Creates an edge statement.

**Module:** `src/kgf/types/semantics.mbt`

### SemStmt::bind

Creates a bind statement.

**Module:** `src/kgf/types/semantics.mbt`

### SemStmt::note

Creates a note statement.

**Module:** `src/kgf/types/semantics.mbt`

### SemStmt::let_

Creates a let statement.

**Module:** `src/kgf/types/semantics.mbt`

### SemStmt::for_

Creates a for statement.

**Module:** `src/kgf/types/semantics.mbt`

### SemStmt::mod_

Creates a module statement.

**Module:** `src/kgf/types/semantics.mbt`

### SemOnBlock::new

Creates a new SemOnBlock with the specified parameters.

**Module:** `src/kgf/types/semantics.mbt`

### SemOnBlock::get_rule

Returns the rule name.

**Module:** `src/kgf/types/semantics.mbt`

### SemOnBlock::get_when_cond

Returns the when condition.

**Module:** `src/kgf/types/semantics.mbt`

### SemOnBlock::get_then_stmts

Returns the then statements.

**Module:** `src/kgf/types/semantics.mbt`

### SemOnBlock::get_else_stmts

Returns the else statements.

**Module:** `src/kgf/types/semantics.mbt`

### MatchResult::success

Creates a successful match result.

**Module:** `src/kgf/lexer/pattern_matcher.mbt`

### MatchResult::failure

Creates a failed match result.

**Module:** `src/kgf/lexer/pattern_matcher.mbt`

### is_whitespace

Checks if a character is a whitespace character.

**Module:** `src/kgf/lexer/pattern_matcher.mbt`

### is_digit

Checks if a character is a digit.

**Module:** `src/kgf/lexer/pattern_matcher.mbt`

### is_word_char

Checks if a character is a word character (alphanumeric or underscore).

**Module:** `src/kgf/lexer/pattern_matcher.mbt`

### is_alpha

Checks if a character is an alphabetic character.

**Module:** `src/kgf/lexer/pattern_matcher.mbt`

### is_hex_digit

Checks if a character is a hex digit.

**Module:** `src/kgf/lexer/pattern_matcher.mbt`

### get_char_at

Gets a character from a string at the given index safely.

**Module:** `src/kgf/lexer/pattern_matcher.mbt`

### parse_char_class

Parses a character class like [a-z], [0-9], [^abc].

**Module:** `src/kgf/lexer/pattern_matcher.mbt`

### parse_pattern

Parses the pattern string into a list of quantified elements.

**Module:** `src/kgf/lexer/pattern_matcher.mbt`

### split_by_alternation

Splits a pattern by top-level alternation.

**Module:** `src/kgf/lexer/pattern_matcher.mbt`

### match_char

Matches a single character against a pattern element.

**Module:** `src/kgf/lexer/pattern_matcher.mbt`

### to_lower

Converts a character to lowercase.

**Module:** `src/kgf/lexer/pattern_matcher.mbt`

### match_quantified

Matches a quantified element against the input starting at pos. Returns the end position if matched, or None if no match.

**Module:** `src/kgf/lexer/pattern_matcher.mbt`

### match_simple

Matches a simple element (non-group) with quantifier.

**Module:** `src/kgf/lexer/pattern_matcher.mbt`

### match_group

Matches a group of elements.

**Module:** `src/kgf/lexer/pattern_matcher.mbt`

### match_group_once

**Module:** `src/kgf/lexer/pattern_matcher.mbt`

### match_alternation

Matches alternation (a|b|c pattern).

**Module:** `src/kgf/lexer/pattern_matcher.mbt`

### match_alt_once

**Module:** `src/kgf/lexer/pattern_matcher.mbt`

### match_pattern

Matches a pattern against the input starting at the given position. Returns the match result with the end position and matched text.

**Module:** `src/kgf/lexer/pattern_matcher.mbt`

### matches_at

Checks if a pattern matches at the start of the input at the given position. This is a convenience wrapper around match_pattern.

**Module:** `src/kgf/lexer/pattern_matcher.mbt`

### Lexer::new

Creates a new Lexer with the given token definitions. Token definitions are tried in order, so more specific patterns should come first.

**Module:** `src/kgf/lexer/lexer.mbt`

### Lexer::tokenize

Tokenizes the input string and returns an array of tokens. Skipped tokens (like whitespace) are not included in the result.

**Module:** `src/kgf/lexer/lexer.mbt`

### Lexer::try_match

Tries to match a token at the given position. Returns the matched token definition, end position, and matched text.

**Module:** `src/kgf/lexer/lexer.mbt`

### extract_value

Extracts the value from a token text. For quoted strings, strips the surrounding quotes.

**Module:** `src/kgf/lexer/lexer.mbt`

### lexer

Creates a lexer builder for fluent API usage.

**Module:** `src/kgf/lexer/lexer.mbt`

### LexerBuilder::new

Creates a new LexerBuilder.

**Module:** `src/kgf/lexer/lexer.mbt`

### LexerBuilder::token

Adds a token definition to the builder.

**Module:** `src/kgf/lexer/lexer.mbt`

### LexerBuilder::skip

Adds a skip token (like whitespace) to the builder.

**Module:** `src/kgf/lexer/lexer.mbt`

### LexerBuilder::build

Builds the lexer from the accumulated token definitions.

**Module:** `src/kgf/lexer/lexer.mbt`

### parse_resolver

Parses resolver block into normalized ResolverSpec. Supports YAML-like syntax with aliases.

**Module:** `src/kgf/spec/parse_resolver.mbt`

### parse_kv_line

Parses a key: value line.

**Module:** `src/kgf/spec/parse_resolver.mbt`

### parse_aliases_block

Parses the aliases block (indented list items).

**Module:** `src/kgf/spec/parse_resolver.mbt`

### is_indented

Checks if a line is indented (starts with space or tab).

**Module:** `src/kgf/spec/parse_resolver.mbt`

### is_double_indented

Checks if a line is double-indented (4 spaces or 2 tabs).

**Module:** `src/kgf/spec/parse_resolver.mbt`

### parse_single_alias

Parses a single alias entry (pattern/replace fields).

**Module:** `src/kgf/spec/parse_resolver.mbt`

### build_resolver_spec

Builds the ResolverSpec from parsed key-value pairs and aliases.

**Module:** `src/kgf/spec/parse_resolver.mbt`

### get_list

Gets a list value from the key-value map.

**Module:** `src/kgf/spec/parse_resolver.mbt`

### get_string

Gets a string value from the key-value map.

**Module:** `src/kgf/spec/parse_resolver.mbt`

### get_optional_string

Gets an optional string value from the key-value map.

**Module:** `src/kgf/spec/parse_resolver.mbt`

### get_int

Gets an integer value from the key-value map.

**Module:** `src/kgf/spec/parse_resolver.mbt`

### get_bool

Gets a boolean value from the key-value map.

**Module:** `src/kgf/spec/parse_resolver.mbt`

### default_module_path_style

Gets a default ModulePathStyle (slash).

**Module:** `src/kgf/spec/parse_resolver.mbt`

### get_module_path_style

Parses a string to ModulePathStyle.

**Module:** `src/kgf/spec/parse_resolver.mbt`

### parse_int_str

Parses a string to an integer.

**Module:** `src/kgf/spec/parse_resolver.mbt`

### parse_lex

Parses the lex section into token definitions with optional SKIP rules. Syntax:   SKIP /pattern/   TOKEN NAME /pattern/[flags]

**Module:** `src/kgf/spec/parse_lex.mbt`

### parse_skip_rule

Parses a SKIP rule: SKIP /pattern/

**Module:** `src/kgf/spec/parse_lex.mbt`

### parse_token_rule

Parses a TOKEN rule: TOKEN NAME /pattern/[flags]

**Module:** `src/kgf/spec/parse_lex.mbt`

### find_closing_slash

Finds the closing slash, handling escaped characters.

**Module:** `src/kgf/spec/parse_lex.mbt`

### skip_whitespace

Skips whitespace characters.

**Module:** `src/kgf/spec/parse_lex.mbt`

### read_identifier

Reads an identifier from the text.

**Module:** `src/kgf/spec/parse_lex.mbt`

### is_valid_flags

Checks if a string contains only valid regex flags.

**Module:** `src/kgf/spec/parse_lex.mbt`

### parse_preprocess_fst

Parses preprocess_fst section as JSON (single object or array). Returns None if the section is empty.

**Module:** `src/kgf/spec/parse_preprocess_fst.mbt`

### parse_single_fst_spec

Parses a single FST spec from JSON.

**Module:** `src/kgf/spec/parse_preprocess_fst.mbt`

### parse_fst_transition

Parses a single FST transition from JSON.

**Module:** `src/kgf/spec/parse_preprocess_fst.mbt`

### parse_fst_action

Parses a single FST action from JSON.

**Module:** `src/kgf/spec/parse_preprocess_fst.mbt`

### parse_attrs

Parses simple one-line attribute actions per rule into structured form. Syntax:   on RuleName: kind1 key1=val1; kind2; ...

**Module:** `src/kgf/spec/parse_attrs.mbt`

### parse_attr_line

Parses a single attribute line: on RuleName: kind1 key1=val1; kind2; ...

**Module:** `src/kgf/spec/parse_attrs.mbt`

### parse_action_list

Parses a list of actions separated by semicolons.

**Module:** `src/kgf/spec/parse_attrs.mbt`

### split_by_char

Splits text by a character.

**Module:** `src/kgf/spec/parse_attrs.mbt`

### parse_single_action

Parses a single action: kind key1=val1 key2=val2 ...

**Module:** `src/kgf/spec/parse_attrs.mbt`

### split_by_space

Splits text by whitespace.

**Module:** `src/kgf/spec/parse_attrs.mbt`

### parse_key_value

Parses a key=value pair.

**Module:** `src/kgf/spec/parse_attrs.mbt`

### section

Extracts a section body by heading marker `=== name`.

**Module:** `src/kgf/spec/parse_kgf.mbt`

### extract_language

Extracts language name from the first `language: xxx` line.

**Module:** `src/kgf/spec/parse_kgf.mbt`

### parse_kgf

Parses a full KGF document text into a structured spec.

**Module:** `src/kgf/spec/parse_kgf.mbt`

### parse_preprocess

Parses preprocess section into list of transducer names.

**Module:** `src/kgf/spec/parse_kgf.mbt`

### split_lines

Splits text into lines, handling both \n and \r\n line endings.

**Module:** `src/kgf/spec/utils.mbt`

### is_whitespace

Checks if a character is whitespace.

**Module:** `src/kgf/spec/utils.mbt`

### is_digit

Checks if a character is a digit.

**Module:** `src/kgf/spec/utils.mbt`

### is_ident_start

Checks if a character is an identifier start character.

**Module:** `src/kgf/spec/utils.mbt`

### is_ident_char

Checks if a character is an identifier character.

**Module:** `src/kgf/spec/utils.mbt`

### find_substring

Finds the index of a substring in a string. Returns -1 if not found.

**Module:** `src/kgf/spec/utils.mbt`

### find_char

Finds the index of a character in a string starting from a position. Returns -1 if not found.

**Module:** `src/kgf/spec/utils.mbt`

### starts_with

Checks if a string starts with a given prefix.

**Module:** `src/kgf/spec/utils.mbt`

### starts_with_at

Checks if a string starts with a given prefix at a specific position.

**Module:** `src/kgf/spec/utils.mbt`

### trim_str

Trims whitespace from both ends of a string.

**Module:** `src/kgf/spec/utils.mbt`

### parse_list

Splits a comma/whitespace list into string array.

**Module:** `src/kgf/spec/utils.mbt`

### substr

Gets a substring from start to end position.

**Module:** `src/kgf/spec/utils.mbt`

### substr_from

Gets a substring from start to the end of the string.

**Module:** `src/kgf/spec/utils.mbt`

### char_at

Gets a character at a position, returning Char.

**Module:** `src/kgf/spec/utils.mbt`

### parse_semantics

Parses semantics section into rule -> on-blocks mapping. Minimal parser using line scanning and balanced braces. Syntax:   on RuleName when condition {     statements   } else {     statements   }

**Module:** `src/kgf/spec/parse_semantics.mbt`

### parse_on_blocks

Parses all on-blocks from the source.

**Module:** `src/kgf/spec/parse_semantics.mbt`

### parse_single_on_block

Parses a single on-block starting at pos.

**Module:** `src/kgf/spec/parse_semantics.mbt`

### skip_ws

Skips whitespace characters.

**Module:** `src/kgf/spec/parse_semantics.mbt`

### read_ident_at

Reads an identifier at the given position.

**Module:** `src/kgf/spec/parse_semantics.mbt`

### read_brace_block

Reads a brace-delimited block, handling nested braces.

**Module:** `src/kgf/spec/parse_semantics.mbt`

### parse_block_stmts

Parses statements inside a block.

**Module:** `src/kgf/spec/parse_semantics.mbt`

### parse_stmt

Parses a single statement.

**Module:** `src/kgf/spec/parse_semantics.mbt`

### parse_edge_stmt

Parses: edge kind from <expr> to <expr> [attrs <expr>]

**Module:** `src/kgf/spec/parse_semantics.mbt`

### parse_bind_stmt

Parses: bind ns <expr> name <expr> to <expr>

**Module:** `src/kgf/spec/parse_semantics.mbt`

### parse_note_stmt

Parses: note <type> [payload <expr>]

**Module:** `src/kgf/spec/parse_semantics.mbt`

### parse_let_stmt

Parses: let <id> = <expr>

**Module:** `src/kgf/spec/parse_semantics.mbt`

### parse_module_stmt

Parses: module <id> [file <expr>]

**Module:** `src/kgf/spec/parse_semantics.mbt`

### find_keyword

Finds a keyword position, ensuring it's a separate word.

**Module:** `src/kgf/spec/parse_semantics.mbt`

### parse_expr

Parses an expression.

**Module:** `src/kgf/spec/parse_semantics.mbt`

### is_number

Checks if a string represents a number.

**Module:** `src/kgf/spec/parse_semantics.mbt`

### parse_number

Parses a number string to double.

**Module:** `src/kgf/spec/parse_semantics.mbt`

### is_identifier

Checks if a string is a valid identifier.

**Module:** `src/kgf/spec/parse_semantics.mbt`

### has_call_syntax

Checks if a string has function call syntax starting at offset.

**Module:** `src/kgf/spec/parse_semantics.mbt`

### parse_call_parts

Parses function call parts (name and args) starting at offset.

**Module:** `src/kgf/spec/parse_semantics.mbt`

### split_args

Splits argument list by commas, respecting nested parens and strings.

**Module:** `src/kgf/spec/parse_semantics.mbt`

### parse_rules

Parses rule lines into rule name to expression mapping. Preserves newlines between indented lines. Syntax:   Name -> expression           continued on multiple lines

**Module:** `src/kgf/spec/parse_rules.mbt`

### parse_rule_header

Tries to parse a rule header: Name -> expression

**Module:** `src/kgf/spec/parse_rules.mbt`

### join_rule_buffer

Joins buffer lines into a single expression, preserving newlines.

**Module:** `src/kgf/spec/parse_rules.mbt`

### apply_preprocess

Applies preprocessing steps to the input string. Supports: - `fst:name` to apply a named FST - `base64ToHex` to convert base64 to hex

**Module:** `src/kgf/preprocess/preprocess.mbt`

### apply_one

Applies a single preprocessing step.

**Module:** `src/kgf/preprocess/preprocess.mbt`

### starts_with

Checks if a string starts with a prefix.

**Module:** `src/kgf/preprocess/preprocess.mbt`

### substr_from

Gets a substring from start to the end of the string.

**Module:** `src/kgf/preprocess/preprocess.mbt`

### base64_to_hex

Converts a base64 string to hexadecimal.

**Module:** `src/kgf/preprocess/preprocess.mbt`

### is_base64_char

Checks if a character is a valid base64 character.

**Module:** `src/kgf/preprocess/preprocess.mbt`

### decode_base64

Decodes a base64 string to bytes.

**Module:** `src/kgf/preprocess/preprocess.mbt`

### base64_value

Gets the numeric value of a base64 character.

**Module:** `src/kgf/preprocess/preprocess.mbt`

### byte_to_hex

Converts a byte to uppercase hexadecimal string.

**Module:** `src/kgf/preprocess/preprocess.mbt`

### compile_fst

Compiles a PreprocessFstSpec into a CompiledFst.

**Module:** `src/kgf/preprocess/fst.mbt`

### compile_char_class

Compiles a character class pattern into a CompiledCharClass. Supports patterns like: [A-Za-z0-9+/=]

**Module:** `src/kgf/preprocess/fst.mbt`

### char_matches_class

Checks if a character matches a compiled character class.

**Module:** `src/kgf/preprocess/fst.mbt`

### classify_char

Classifies a character according to the FST's character classes. Returns the name of the matching class, or None if no match.

**Module:** `src/kgf/preprocess/fst.mbt`

### match_transition

Finds a matching transition for the given input class.

**Module:** `src/kgf/preprocess/fst.mbt`

### sextet

Converts a base64 character to its sextet value.

**Module:** `src/kgf/preprocess/fst.mbt`

### decode_quartet

Decodes a quartet of base64 sextets into bytes.

**Module:** `src/kgf/preprocess/fst.mbt`

### is_ws_byte

Checks if a byte is whitespace.

**Module:** `src/kgf/preprocess/fst.mbt`

### is_ctrl_byte

Checks if a byte is a control character.

**Module:** `src/kgf/preprocess/fst.mbt`

### classify_utf8

Classifies a byte array as UTF-8 text.

**Module:** `src/kgf/preprocess/fst.mbt`

### utf8_agg_to_string

Converts Utf8Agg to string label.

**Module:** `src/kgf/preprocess/fst.mbt`

### run_fst

Runs a compiled FST over the input string and returns the transformed output.

**Module:** `src/kgf/preprocess/fst.mbt`

### flush

**Module:** `src/kgf/preprocess/fst.mbt`

### apply_action

**Module:** `src/kgf/preprocess/fst.mbt`

### eval_semantics

Evaluates semantics on-blocks for a completed rule with captured labels. Processes each block's when condition and executes then or else statements accordingly.

**Module:** `src/kgf/semantics/eval_semantics.mbt`

### eval_rule_semantics

Evaluates semantics for a rule by name. Looks up the semantic blocks for the rule in the spec and evaluates them.

**Module:** `src/kgf/semantics/eval_semantics.mbt`

### is_truthy

Checks if a value is truthy according to KGF semantics. - null/undefined -> false - boolean -> itself - empty string -> false - empty array -> false - other -> true

**Module:** `src/kgf/semantics/eval_expr.mbt`

### json_to_string

Converts a Json value to a string.

**Module:** `src/kgf/semantics/eval_expr.mbt`

### json_to_number

Converts a Json value to a number.

**Module:** `src/kgf/semantics/eval_expr.mbt`

### eval_expr

Evaluates a semantic expression and returns a Json value.

**Module:** `src/kgf/semantics/eval_expr.mbt`

### eval_var

Evaluates a variable reference.

**Module:** `src/kgf/semantics/eval_expr.mbt`

### eval_call

Evaluates a special call expression ($resolve, $scope, etc.).

**Module:** `src/kgf/semantics/eval_expr.mbt`

### eval_func

Evaluates a function expression (concat, obj, etc.).

**Module:** `src/kgf/semantics/eval_expr.mbt`

### eval_func_obj

Evaluates the obj() function to create an object from key-value pairs.

**Module:** `src/kgf/semantics/eval_expr.mbt`

### eval_func_hex_to_int

Evaluates the hexToInt() function.

**Module:** `src/kgf/semantics/eval_expr.mbt`

### trim_string

Trims leading and trailing whitespace from a string.

**Module:** `src/kgf/semantics/eval_expr.mbt`

### is_whitespace

Checks if a character is whitespace.

**Module:** `src/kgf/semantics/eval_expr.mbt`

### is_valid_hex

Checks if a string is a valid hexadecimal number.

**Module:** `src/kgf/semantics/eval_expr.mbt`

### is_hex_char

Checks if a character is a valid hex digit.

**Module:** `src/kgf/semantics/eval_expr.mbt`

### parse_hex

Parses a hexadecimal string to an integer.

**Module:** `src/kgf/semantics/eval_expr.mbt`

### hex_char_value

Gets the numeric value of a hex character.

**Module:** `src/kgf/semantics/eval_expr.mbt`

### eval_func_slice

Evaluates the slice() function.

**Module:** `src/kgf/semantics/eval_expr.mbt`

### eval_func_strip_quotes

Evaluates the stripQuotes() function.

**Module:** `src/kgf/semantics/eval_expr.mbt`

### eval_func_first

Evaluates the first() function.

**Module:** `src/kgf/semantics/eval_expr.mbt`

### eval_func_last

Evaluates the last() function.

**Module:** `src/kgf/semantics/eval_expr.mbt`

### eval_stmt

Evaluates a semantic statement.

**Module:** `src/kgf/semantics/eval_stmt.mbt`

### eval_stmt_edge

Evaluates an edge statement.

**Module:** `src/kgf/semantics/eval_stmt.mbt`

### eval_stmt_bind

Evaluates a bind statement.

**Module:** `src/kgf/semantics/eval_stmt.mbt`

### eval_stmt_note

Evaluates a note statement.

**Module:** `src/kgf/semantics/eval_stmt.mbt`

### eval_stmt_let

Evaluates a let statement.

**Module:** `src/kgf/semantics/eval_stmt.mbt`

### eval_stmt_for

Evaluates a for statement.

**Module:** `src/kgf/semantics/eval_stmt.mbt`

### eval_stmt_module

Evaluates a module statement.

**Module:** `src/kgf/semantics/eval_stmt.mbt`

### create_test_ctx

Creates a test context with minimal setup.

**Module:** `src/kgf/semantics/semantics_wbtest.mbt`

### ScopeEntry::new

Creates a new empty ScopeEntry.

**Module:** `src/kgf/semantics/context.mbt`

### ScopeEntry::get_value

Gets a value from the value namespace.

**Module:** `src/kgf/semantics/context.mbt`

### ScopeEntry::get_type

Gets a value from the type namespace.

**Module:** `src/kgf/semantics/context.mbt`

### ScopeEntry::set_value

Sets a value in the value namespace.

**Module:** `src/kgf/semantics/context.mbt`

### ScopeEntry::set_type

Sets a value in the type namespace.

**Module:** `src/kgf/semantics/context.mbt`

### Env::new

Creates a new Env with the specified labels.

**Module:** `src/kgf/semantics/context.mbt`

### Env::get

Gets a value from locals or labels by name.

**Module:** `src/kgf/semantics/context.mbt`

### Env::set_local

Sets a local variable.

**Module:** `src/kgf/semantics/context.mbt`

### SemEvalCtx::new

Creates a new SemEvalCtx with the specified parameters.

**Module:** `src/kgf/semantics/context.mbt`

### SemEvalCtx::push_scope

Pushes a new scope onto the scope stack.

**Module:** `src/kgf/semantics/context.mbt`

### SemEvalCtx::pop_scope

Pops the top scope from the scope stack.

**Module:** `src/kgf/semantics/context.mbt`

### SemEvalCtx::current_scope

Gets the current (top) scope.

**Module:** `src/kgf/semantics/context.mbt`

### SemEvalCtx::lookup_scope

Looks up a name in the scope stack (searches from top to bottom).

**Module:** `src/kgf/semantics/context.mbt`

### SemEvalCtx::current_call_id

Gets the current call ID from the call stack.

**Module:** `src/kgf/semantics/context.mbt`

### SemEvalCtx::next_sym_id

Generates the next auto symbol ID.

**Module:** `src/kgf/semantics/context.mbt`

### SemEvalCtx::next_call_id

Generates the next auto call ID.

**Module:** `src/kgf/semantics/context.mbt`

### SemEvalCtx::add_event

Adds an event to the events list.

**Module:** `src/kgf/semantics/context.mbt`

### SemEvalCtx::collect_refs

Collects and removes all Ref events from the events list.

**Module:** `src/kgf/semantics/context.mbt`

### ParseState::new

Creates a new parse state from tokens.

**Module:** `src/kgf/peg/parse_expr.mbt`

### ParseState::has_more

Returns true if there are more tokens.

**Module:** `src/kgf/peg/parse_expr.mbt`

### ParseState::peek

Peeks at the current token without consuming it.

**Module:** `src/kgf/peg/parse_expr.mbt`

### ParseState::advance

Consumes the current token and advances.

**Module:** `src/kgf/peg/parse_expr.mbt`

### ParseState::eat_ident

Checks if current token matches and consumes it if so.

**Module:** `src/kgf/peg/parse_expr.mbt`

### ParseState::eat_lp

Checks if current token is LP and consumes it.

**Module:** `src/kgf/peg/parse_expr.mbt`

### ParseState::eat_rp

Checks if current token is RP and consumes it.

**Module:** `src/kgf/peg/parse_expr.mbt`

### ParseState::eat_lb

Checks if current token is LB and consumes it.

**Module:** `src/kgf/peg/parse_expr.mbt`

### ParseState::eat_rb

Checks if current token is RB and consumes it.

**Module:** `src/kgf/peg/parse_expr.mbt`

### ParseState::eat_star

Checks if current token is STAR and consumes it.

**Module:** `src/kgf/peg/parse_expr.mbt`

### ParseState::eat_plus

Checks if current token is PLUS and consumes it.

**Module:** `src/kgf/peg/parse_expr.mbt`

### ParseState::eat_q

Checks if current token is Q (?) and consumes it.

**Module:** `src/kgf/peg/parse_expr.mbt`

### ParseState::eat_bar

Checks if current token is BAR and consumes it.

**Module:** `src/kgf/peg/parse_expr.mbt`

### ParseState::eat_colon

Checks if current token is COLON and consumes it.

**Module:** `src/kgf/peg/parse_expr.mbt`

### ParseState::is_stop_token

Returns true if current token is a stop token (RP, RB, BAR).

**Module:** `src/kgf/peg/parse_expr.mbt`

### is_ident_start

Checks if a character is a valid identifier start.

**Module:** `src/kgf/peg/parse_expr.mbt`

### is_ident_char

Checks if a character is a valid identifier continuation.

**Module:** `src/kgf/peg/parse_expr.mbt`

### is_whitespace

Checks if a character is whitespace.

**Module:** `src/kgf/peg/parse_expr.mbt`

### remove_comment

Removes comments from a line (everything after #).

**Module:** `src/kgf/peg/parse_expr.mbt`

### preprocess

Preprocesses the input string: removes comments and empty lines.

**Module:** `src/kgf/peg/parse_expr.mbt`

### tokenize_expr

Tokenizes a PEG expression string into grammar tokens.

**Module:** `src/kgf/peg/parse_expr.mbt`

### parse_primary

Parses a primary expression (identifier, label, parenthesized group, or bracketed optional).

**Module:** `src/kgf/peg/parse_expr.mbt`

### parse_postfix

Parses a postfix expression (primary with optional *, +, or ?).

**Module:** `src/kgf/peg/parse_expr.mbt`

### parse_seq

Parses a sequence of expressions.

**Module:** `src/kgf/peg/parse_expr.mbt`

### parse_choice

Parses a choice expression (alternatives separated by |).

**Module:** `src/kgf/peg/parse_expr.mbt`

### parse_expr

Parses a PEG expression string into a Node AST.

**Module:** `src/kgf/peg/parse_expr.mbt`

### EvalResult::success

Creates a new successful EvalResult.

**Module:** `src/kgf/peg/eval.mbt`

### EvalResult::failure

Creates a new failed EvalResult.

**Module:** `src/kgf/peg/eval.mbt`

### EvalResult::is_ok

Returns true if the evaluation succeeded.

**Module:** `src/kgf/peg/eval.mbt`

### EvalResult::get_pos

Returns the position after evaluation.

**Module:** `src/kgf/peg/eval.mbt`

### EvalResult::get_labels

Returns the captured labels.

**Module:** `src/kgf/peg/eval.mbt`

### EvalResult::get_events

Returns the emitted events.

**Module:** `src/kgf/peg/eval.mbt`

### EvalResult::get_label

Gets a label value by name.

**Module:** `src/kgf/peg/eval.mbt`

### EvalContext::new

Creates a new evaluation context.

**Module:** `src/kgf/peg/eval.mbt`

### node_to_string

Converts a node to a string for memoization key.

**Module:** `src/kgf/peg/eval.mbt`

### make_memo_key

Creates a memo key from a node and position.

**Module:** `src/kgf/peg/eval.mbt`

### merge_labels

Merges two label maps, with the second taking precedence.

**Module:** `src/kgf/peg/eval.mbt`

### append_events

Appends events from one array to another.

**Module:** `src/kgf/peg/eval.mbt`

### eval_node

Evaluates a node at a given position.

**Module:** `src/kgf/peg/eval.mbt`

### eval_node_impl

Implementation of node evaluation.

**Module:** `src/kgf/peg/eval.mbt`

### eval_sym

Evaluates a symbol (token or rule reference).

**Module:** `src/kgf/peg/eval.mbt`

### eval_seq

Evaluates a sequence of nodes.

**Module:** `src/kgf/peg/eval.mbt`

### eval_choice

Evaluates a choice (first successful alternative).

**Module:** `src/kgf/peg/eval.mbt`

### eval_star

Evaluates a star (zero or more repetitions).

**Module:** `src/kgf/peg/eval.mbt`

### eval_plus

Evaluates a plus (one or more repetitions).

**Module:** `src/kgf/peg/eval.mbt`

### eval_optional

Evaluates an optional (zero or one).

**Module:** `src/kgf/peg/eval.mbt`

### eval_label

Evaluates a labeled expression.

**Module:** `src/kgf/peg/eval.mbt`

### run_parse

Runs a PEG parse from a start rule over tokens. Returns the final result with labels and events, or None on failure.

**Module:** `src/kgf/peg/eval.mbt`

### call_rule

**Module:** `src/kgf/peg/eval.mbt`

### PEG::new

Creates a new empty PEG.

**Module:** `src/kgf/peg/peg.mbt`

### PEG::get_tokens

Returns the token set.

**Module:** `src/kgf/peg/peg.mbt`

### PEG::is_token

Checks if a name is a token.

**Module:** `src/kgf/peg/peg.mbt`

### PEG::get_ast

Returns the AST map.

**Module:** `src/kgf/peg/peg.mbt`

### PEG::get_rule

Gets the AST node for a specific rule.

**Module:** `src/kgf/peg/peg.mbt`

### PEG::get_attrs

Returns the attributes map.

**Module:** `src/kgf/peg/peg.mbt`

### PEG::get_rule_attrs

Gets the attribute actions for a specific rule.

**Module:** `src/kgf/peg/peg.mbt`

### build_peg

Builds a PEG from a KGFSpec. Parses all rule expressions into AST nodes and collects token names.

**Module:** `src/kgf/peg/peg.mbt`

### simple_assignment_kgf

Integration tests for KGF: parse_kgf -> build_peg -> Lexer::new -> tokenize -> run_parse Tests the complete parsing pipeline from KGF specification to parsed results.  Simple assignment language spec for integration testing. Grammar: Program -> Statement*, Statement -> IDENT EQUALS NUMBER SEMI

**Module:** `src/kgf/peg/integration_wbtest.mbt`

### expression_kgf

Expression language spec with operators and precedence.

**Module:** `src/kgf/peg/integration_wbtest.mbt`

### labeled_kgf

Language spec with labeled captures.

**Module:** `src/kgf/peg/integration_wbtest.mbt`

### optional_kgf

Language spec with optional elements.

**Module:** `src/kgf/peg/integration_wbtest.mbt`

### choice_kgf

Language spec with choice alternatives.

**Module:** `src/kgf/peg/integration_wbtest.mbt`

### plus_kgf

Language spec with one-or-more repetition (plus).

**Module:** `src/kgf/peg/integration_wbtest.mbt`

### case_insensitive_kgf

Case-insensitive token matching test.

**Module:** `src/kgf/peg/integration_wbtest.mbt`

### nested_rules_kgf

Complex nested rule references.

**Module:** `src/kgf/peg/integration_wbtest.mbt`

### string_value_kgf

Test string token with value extraction.

**Module:** `src/kgf/peg/integration_wbtest.mbt`

### resolver_kgf

Test with resolver section parsing.

**Module:** `src/kgf/peg/integration_wbtest.mbt`

### attrs_kgf

Test with attrs section parsing.

**Module:** `src/kgf/peg/integration_wbtest.mbt`

### comments_kgf

Comment handling in KGF spec.

**Module:** `src/kgf/peg/integration_wbtest.mbt`

### multiline_rule_kgf

Multiline rule continuation.

**Module:** `src/kgf/peg/integration_wbtest.mbt`

### Node::is_empty

Returns true if this node is Empty.

**Module:** `src/kgf/peg/node.mbt`

### Node::is_sym

Returns true if this node is a Symbol.

**Module:** `src/kgf/peg/node.mbt`

### Node::get_sym

Gets the symbol name if this is a Sym node.

**Module:** `src/kgf/peg/node.mbt`

### Node::is_seq

Returns true if this node is a Sequence.

**Module:** `src/kgf/peg/node.mbt`

### Node::get_seq

Gets the sequence elements if this is a Seq node.

**Module:** `src/kgf/peg/node.mbt`

### Node::is_choice

Returns true if this node is a Choice.

**Module:** `src/kgf/peg/node.mbt`

### Node::get_choice

Gets the choice alternatives if this is a Choice node.

**Module:** `src/kgf/peg/node.mbt`

### Node::is_star

Returns true if this node is a Star (zero or more).

**Module:** `src/kgf/peg/node.mbt`

### Node::get_star

Gets the inner node if this is a Star node.

**Module:** `src/kgf/peg/node.mbt`

### Node::is_plus

Returns true if this node is a Plus (one or more).

**Module:** `src/kgf/peg/node.mbt`

### Node::get_plus

Gets the inner node if this is a Plus node.

**Module:** `src/kgf/peg/node.mbt`

### Node::is_optional

Returns true if this node is Optional (zero or one).

**Module:** `src/kgf/peg/node.mbt`

### Node::get_optional

Gets the inner node if this is an Optional node.

**Module:** `src/kgf/peg/node.mbt`

### Node::is_label

Returns true if this node is a Label.

**Module:** `src/kgf/peg/node.mbt`

### Node::get_label

Gets the label name and inner node if this is a Label node.

**Module:** `src/kgf/peg/node.mbt`

### module_to_path

Converts a module identifier to a filesystem path according to the style. - Dot style: "a.b.c" -> "a/b/c" - ColonColon style: "a::b::c" -> "a/b/c" - Slash style: "a/b/c" -> "a/b/c" (no change)

**Module:** `src/kgf/resolver/module_path.mbt`

### replace_all

Replaces all occurrences of a substring with another substring.

**Module:** `src/kgf/resolver/module_path.mbt`

### starts_with_at_arr

Checks if a char array starts with a pattern at a given position.

**Module:** `src/kgf/resolver/module_path.mbt`

### MockFileResolver::new

**Module:** `src/kgf/resolver/resolver_wbtest.mbt`

### get_dot_style

**Module:** `src/kgf/resolver/resolver_wbtest.mbt`

### get_colon_style

**Module:** `src/kgf/resolver/resolver_wbtest.mbt`

### get_slash_style

**Module:** `src/kgf/resolver/resolver_wbtest.mbt`

### resolve_module

Resolves a module specifier to a project-relative path or a logical id. - Applies resolver aliases. - Handles language-specific namespace prefixes. - Resolves relative prefixes against the importing file or project root.

**Module:** `src/kgf/resolver/resolver.mbt`

### substr_from_resolver

Returns substring from start position to end of string.

**Module:** `src/kgf/resolver/resolver.mbt`

### substr_resolver

Returns substring from start to end position (exclusive).

**Module:** `src/kgf/resolver/resolver.mbt`

### try_local

Tries to resolve a module path locally, checking extensions and index files.

**Module:** `src/kgf/resolver/resolver.mbt`

### normalize_relative_result

Normalizes a result path to be relative to project root.

**Module:** `src/kgf/resolver/resolver.mbt`

### replace_backslashes

Replaces backslashes with forward slashes.

**Module:** `src/kgf/resolver/resolver.mbt`

### has_relative_prefix

Checks if a module path has any of the relative prefixes.

**Module:** `src/kgf/resolver/resolver.mbt`

### get_module_head

Gets the head part of a module (before first . or :: or /).

**Module:** `src/kgf/resolver/resolver.mbt`

### contains_char

Checks if a string contains a specific character.

**Module:** `src/kgf/resolver/resolver.mbt`

### split_by_backslash

Splits a string by backslash.

**Module:** `src/kgf/resolver/resolver.mbt`

### join_with_backslash

Joins array elements with backslash up to a count.

**Module:** `src/kgf/resolver/resolver.mbt`

### find_char_pos

Finds the position of a character in a string.

**Module:** `src/kgf/resolver/resolver.mbt`

### min_int

Returns the minimum of two integers.

**Module:** `src/kgf/resolver/resolver.mbt`

### resolve_module_with_fn

Resolves a module specifier using a function to check file existence. This is a convenience wrapper around resolve_module that accepts a function instead of a trait reference.

**Module:** `src/kgf/resolver/resolver.mbt`

### apply_aliases

Applies alias rewrites to a module path. Aliases are applied in order. Each alias pattern is a simple string match. For complex regex patterns, only simple prefix matching is supported.

**Module:** `src/kgf/resolver/alias.mbt`

### apply_single_alias

Applies a single alias pattern to a module path. Supports simple prefix patterns and string replacement.

**Module:** `src/kgf/resolver/alias.mbt`

### substring_from

Returns substring from start position to end of string.

**Module:** `src/kgf/resolver/alias.mbt`

### substring_range

Returns substring from start to end position (exclusive).

**Module:** `src/kgf/resolver/alias.mbt`

### replace_first

Replaces the first occurrence of a pattern with a replacement.

**Module:** `src/kgf/resolver/alias.mbt`

### find_substring

Finds the position of a substring in a string. Returns -1 if not found.

**Module:** `src/kgf/resolver/alias.mbt`

### join_path

Joins path parts into a single path string. Parts are joined with "/" separator. Empty parts are filtered out.

**Module:** `src/kgf/resolver/path_utils.mbt`

### dirname

Returns the directory name of a path. For example, dirname("/a/b/c.txt") returns "/a/b"

**Module:** `src/kgf/resolver/path_utils.mbt`

### basename

Returns the base name of a path. For example, basename("/a/b/c.txt") returns "c.txt"

**Module:** `src/kgf/resolver/path_utils.mbt`

### normalize_path

Normalizes a path by removing redundant slashes and resolving . and ..

**Module:** `src/kgf/resolver/path_utils.mbt`

### relative_path

Computes the relative path from one path to another. Both paths should be absolute or both relative.

**Module:** `src/kgf/resolver/path_utils.mbt`

### is_absolute

Checks if a path is absolute (starts with /).

**Module:** `src/kgf/resolver/path_utils.mbt`

### find_last_char

Finds the last occurrence of a character in a string. Returns -1 if not found.

**Module:** `src/kgf/resolver/path_utils.mbt`

### substr

Returns substring from start to end position (exclusive).

**Module:** `src/kgf/resolver/path_utils.mbt`

### substr_from

Returns substring from start position to end of string.

**Module:** `src/kgf/resolver/path_utils.mbt`

### split_string

Splits a string by a delimiter character.

**Module:** `src/kgf/resolver/path_utils.mbt`

### join_array_strings

Joins an array of strings with a separator.

**Module:** `src/kgf/resolver/path_utils.mbt`

### CodeGraph::new

Create a new empty code graph.

**Module:** `src/core/graph/graph.mbt`

### CodeGraph::get_or_add_module

Get an existing module or add a new one. If the module exists and a file path is provided, updates the file if not already set.

**Module:** `src/core/graph/graph.mbt`

### CodeGraph::get_or_add_symbol

Get an existing symbol or add a new one. Symbol identity is determined by its ID.

**Module:** `src/core/graph/graph.mbt`

### CodeGraph::add_edge

Add an edge between two nodes.

**Module:** `src/core/graph/graph.mbt`

### CodeGraph::get_modules

Get all modules in the graph.

**Module:** `src/core/graph/graph.mbt`

### CodeGraph::get_symbols

Get all symbols in the graph.

**Module:** `src/core/graph/graph.mbt`

### CodeGraph::get_edges

Get all edges in the graph.

**Module:** `src/core/graph/graph.mbt`

### CodeGraph::get_module

Get a module by ID if it exists.

**Module:** `src/core/graph/graph.mbt`

### CodeGraph::get_symbol

Get a symbol by ID if it exists.

**Module:** `src/core/graph/graph.mbt`

### CodeGraph::module_count

Count the number of modules.

**Module:** `src/core/graph/graph.mbt`

### CodeGraph::symbol_count

Count the number of symbols.

**Module:** `src/core/graph/graph.mbt`

### CodeGraph::edge_count

Count the number of edges.

**Module:** `src/core/graph/graph.mbt`

### CodeGraph::edges_from

Find all edges from a given node.

**Module:** `src/core/graph/graph.mbt`

### CodeGraph::edges_to

Find all edges to a given node.

**Module:** `src/core/graph/graph.mbt`

### EdgeKind::to_string

Convert EdgeKind to its string representation.

**Module:** `src/core/graph/graph.mbt`

### EdgeKind::from_string

Parse a string into an EdgeKind.

**Module:** `src/core/graph/graph.mbt`

### CodeGraph::to_json_string

Convert CodeGraph to JSON string following KGF format. Format: {   "modules": { "id": { "file": "..." } },   "symbols": { "id": { "name": "...", "kind": "...", "ns": "...", "module": "..." } },   "edges": [{ "kind": "...", "from": "...", "to": "...", ...attrs }] }

**Module:** `src/core/graph/graph.mbt`

### CodeGraph::from_json_string

Parse JSON string to CodeGraph following KGF format.

**Module:** `src/core/graph/graph.mbt`

### char_to_utf8

Convert a character to UTF-8 bytes and append to buffer.

**Module:** `src/segmentation/utils/compression_distance.mbt`

### string_to_utf8

Convert string to UTF-8 bytes.

**Module:** `src/segmentation/utils/compression_distance.mbt`

### find_longest_match

Find the longest match in the search window for LZ77 compression. Returns (offset, length) where offset is the distance back in the buffer and length is the match length. Returns (0, 0) if no match found.

**Module:** `src/segmentation/utils/compression_distance.mbt`

### compress

Compress text using LZ77-style algorithm. This is a simplified implementation that captures text similarity effectively. The output format: - Literal byte: 0x00 followed by the byte - Back reference: 0x01 followed by 2-byte offset and 1-byte length

**Module:** `src/segmentation/utils/compression_distance.mbt`

### compressed_size

Get the compressed size of text in bytes.

**Module:** `src/segmentation/utils/compression_distance.mbt`

### ncd

Calculate Normalized Compression Distance between two texts. NCD(x, y) = (C(xy) - min(C(x), C(y))) / max(C(x), C(y))  Uses LZ77-style compression to measure text similarity. Similar texts compress better together (lower NCD), while different texts do not benefit from concatenation (higher NCD).  Returns NCD value between 0 (identical) and ~1 (completely different).

**Module:** `src/segmentation/utils/compression_distance.mbt`

### calculate_adjacent_ncd

Calculate NCD values for sliding window of adjacent texts. For texts [a, b, c, d], calculates: - ncd(a, b) - ncd(b, c) - ncd(c, d)  Returns array of NCD values (length = texts.length - 1).

**Module:** `src/segmentation/utils/compression_distance.mbt`

### find_local_maxima

Find local maxima indices where values exceed the threshold. A local maximum is a value that is greater than or equal to both its neighbors.  This is useful for finding potential segment boundaries in NCD/divergence values.

**Module:** `src/segmentation/utils/compression_distance.mbt`

### min_max_normalize

Normalize an array of values using Min-Max normalization. Returns values in range [0, 1]. If all values are the same, returns 0.5 for all.

**Module:** `src/segmentation/utils/compression_distance.mbt`

### tokenize_text_for_tfidf

Tokenize text for TF-IDF processing. Combines word tokens and character bigrams for mixed language support.

**Module:** `src/segmentation/utils/tfidf_distance.mbt`

### cosine_similarity

Calculate cosine similarity between two TF-IDF vectors. Returns 1.0 for identical vectors, 0.0 for orthogonal vectors.

**Module:** `src/segmentation/utils/tfidf_distance.mbt`

### cosine_distance

Calculate cosine distance between two TF-IDF vectors. Returns 0.0 for identical vectors, 1.0 for orthogonal vectors. cosine_distance = 1 - cosine_similarity

**Module:** `src/segmentation/utils/tfidf_distance.mbt`

### calculate_adjacent_tfidf_distance

Calculate TF-IDF cosine distances between adjacent texts. Returns an array of distances where distances[i] is the distance between texts[i] and texts[i+1].

**Module:** `src/segmentation/utils/tfidf_distance.mbt`

### build_tfidf_vector

Build a TF-IDF vector from tokens.

**Module:** `src/segmentation/utils/tfidf_distance.mbt`

### build_document_frequency

Build document frequency map from multiple tokenized documents.

**Module:** `src/segmentation/utils/tfidf_distance.mbt`

### build_term_frequency

Build term frequency map from a list of tokens.

**Module:** `src/segmentation/utils/tfidf_distance.mbt`

### is_sentence_terminator

Check if a character is a sentence terminator. Includes Japanese and English punctuation.

**Module:** `src/segmentation/utils/sentence_boundary.mbt`

### is_trailing_punctuation

Check if a character is trailing punctuation that follows a terminator. These characters should not cause a split after a terminator.

**Module:** `src/segmentation/utils/sentence_boundary.mbt`

### is_extended_terminator

Check if a character is an extended terminator (includes closing brackets).

**Module:** `src/segmentation/utils/sentence_boundary.mbt`

### get_closing_quote

Get the matching closing quote for an opening quote. Returns None if not an opening quote.

**Module:** `src/segmentation/utils/sentence_boundary.mbt`

### get_opening_quote

Get the matching opening quote for a closing quote. Returns None if not a closing quote.

**Module:** `src/segmentation/utils/sentence_boundary.mbt`

### update_quote_stack

Update the quote stack state for one character. Opening quote => push to stack. Matching closing quote => pop from stack.

**Module:** `src/segmentation/utils/sentence_boundary.mbt`

### build_quote_stack_until

Build quote stack state up to end_pos (exclusive).

**Module:** `src/segmentation/utils/sentence_boundary.mbt`

### is_inside_protected_quote

Check if currently inside a protected quote (under max length).

**Module:** `src/segmentation/utils/sentence_boundary.mbt`

### find_sentence_boundaries

Find sentence boundary positions in text. Returns array of end positions (exclusive) for each sentence.

**Module:** `src/segmentation/utils/sentence_boundary.mbt`

### find_sentence_boundaries_default

Find sentence boundaries with default options.

**Module:** `src/segmentation/utils/sentence_boundary.mbt`

### find_next_boundary

Find the next sentence boundary from a given position. Returns end position of the next sentence, or text.length() if none found.

**Module:** `src/segmentation/utils/sentence_boundary.mbt`

### find_next_boundary_default

Find the next sentence boundary with default options.

**Module:** `src/segmentation/utils/sentence_boundary.mbt`

### is_at_boundary

Check if a position is at a sentence boundary. Returns true if the position is immediately after trailing punctuation.

**Module:** `src/segmentation/utils/sentence_boundary.mbt`

### FindBoundariesOptions::new

Create new FindBoundariesOptions with default values.

**Module:** `src/segmentation/utils/types.mbt`

### FindBoundariesOptions::create

Create FindBoundariesOptions with all parameters specified.

**Module:** `src/segmentation/utils/types.mbt`

### FindBoundariesOptions::get_include_closing_brackets

Get include_closing_brackets option.

**Module:** `src/segmentation/utils/types.mbt`

### FindBoundariesOptions::get_respect_japanese_quotes

Get respect_japanese_quotes option.

**Module:** `src/segmentation/utils/types.mbt`

### FindBoundariesOptions::get_quote_safe_max_length

Get quote_safe_max_length option.

**Module:** `src/segmentation/utils/types.mbt`

### QuoteStackEntry::new

Create a new QuoteStackEntry.

**Module:** `src/segmentation/utils/types.mbt`

### QuoteStackEntry::get_open

Get the opening quote character.

**Module:** `src/segmentation/utils/types.mbt`

### QuoteStackEntry::get_start

Get the start position.

**Module:** `src/segmentation/utils/types.mbt`

### SplitOptions::default

Create default SplitOptions.

**Module:** `src/segmentation/sentence/splitter.mbt`

### is_sentence_end

Check if a character is a sentence-ending punctuation mark.

**Module:** `src/segmentation/sentence/splitter.mbt`

### is_extended_sentence_end

Check if a character is an extended sentence terminator (including closing brackets).

**Module:** `src/segmentation/sentence/splitter.mbt`

### is_trailing_punctuation

Check if a character is trailing punctuation that can follow a terminator.

**Module:** `src/segmentation/sentence/splitter.mbt`

### is_newline

Check if a character is a newline.

**Module:** `src/segmentation/sentence/splitter.mbt`

### is_whitespace

Check if a character is whitespace.

**Module:** `src/segmentation/sentence/splitter.mbt`

### is_opening_quote

Check if a character is an opening quote (Japanese only for reliable protection). Note: English ASCII quotes (" and ') are ambiguous (same char for open/close), so we only protect Japanese quotes for reliable behavior.

**Module:** `src/segmentation/sentence/splitter.mbt`

### is_closing_quote

Check if a character is a closing quote (Japanese only for reliable protection).

**Module:** `src/segmentation/sentence/splitter.mbt`

### get_opening_quote

Get the matching opening quote for a closing quote.

**Module:** `src/segmentation/sentence/splitter.mbt`

### update_quote_stack

Update the quote stack based on the current character. Opening quote => push to stack. Matching closing quote => pop from stack.

**Module:** `src/segmentation/sentence/splitter.mbt`

### is_inside_protected_quote

Check if currently inside a protected quote (under max length).

**Module:** `src/segmentation/sentence/splitter.mbt`

### split_sentences

Split text into sentences with default options (quote protection enabled).  Handles: - English sentence endings: `.` `!` `?` - Japanese sentence endings: `。` `！` `？` `．` - Newlines as sentence breaks - Consecutive punctuation marks - Quote protection: punctuation inside quotes does not split sentences

**Module:** `src/segmentation/sentence/splitter.mbt`

### split_sentences_with_options

Split text into sentences with custom options.  Handles: - English sentence endings: `.` `!` `?` - Japanese sentence endings: `。` `！` `？` `．` - Newlines as sentence breaks - Consecutive punctuation marks - Quote protection (configurable): punctuation inside quotes does not split sentences

**Module:** `src/segmentation/sentence/splitter.mbt`

### extract_substring

Extract a substring from a character array.

**Module:** `src/segmentation/sentence/splitter.mbt`

### trim_string

Trim whitespace from both ends of a string.

**Module:** `src/segmentation/sentence/splitter.mbt`

### split_sentences_text

Split text into sentences and return only the text content.

**Module:** `src/segmentation/sentence/splitter.mbt`

### split_sentences_text_with_options

Split text into sentences with custom options and return only the text content.

**Module:** `src/segmentation/sentence/splitter.mbt`

### count_sentences

Count the number of sentences in text.

**Module:** `src/segmentation/sentence/splitter.mbt`

### count_sentences_with_options

Count the number of sentences in text with custom options.

**Module:** `src/segmentation/sentence/splitter.mbt`

### Sentence::new

Create a new Sentence.

**Module:** `src/segmentation/sentence/types.mbt`

### Sentence::get_text

Get the text content of the sentence.

**Module:** `src/segmentation/sentence/types.mbt`

### Sentence::get_start

Get the start position.

**Module:** `src/segmentation/sentence/types.mbt`

### Sentence::get_end

Get the end position.

**Module:** `src/segmentation/sentence/types.mbt`

### Sentence::length

Get the length of the sentence text.

**Module:** `src/segmentation/sentence/types.mbt`

### SegmentConfig::new

Create a new SegmentConfig.

**Module:** `src/segmentation/window/types.mbt`

### SegmentConfig::get_target_chunk_size

Get the target chunk size.

**Module:** `src/segmentation/window/types.mbt`

### SegmentConfig::get_min_chunk_size

Get the minimum chunk size.

**Module:** `src/segmentation/window/types.mbt`

### SegmentConfig::get_max_chunk_size

Get the maximum chunk size.

**Module:** `src/segmentation/window/types.mbt`

### SegmentConfig::get_threshold

Get the threshold.

**Module:** `src/segmentation/window/types.mbt`

### SegmentConfig::get_window_size

Get the window size.

**Module:** `src/segmentation/window/types.mbt`

### AdaptiveConfig::new

Create a new AdaptiveConfig.

**Module:** `src/segmentation/window/types.mbt`

### AdaptiveConfig::get_percentile

Get the percentile value.

**Module:** `src/segmentation/window/types.mbt`

### AdaptiveConfig::get_minimum_threshold

Get the minimum threshold.

**Module:** `src/segmentation/window/types.mbt`

### AdaptiveConfig::get_target_chunk_size

Get the target chunk size.

**Module:** `src/segmentation/window/types.mbt`

### AdaptiveConfig::get_min_chunk_size

Get the minimum chunk size.

**Module:** `src/segmentation/window/types.mbt`

### AdaptiveConfig::get_max_chunk_size

Get the maximum chunk size.

**Module:** `src/segmentation/window/types.mbt`

### AdaptiveConfig::get_window_size

Get the window size.

**Module:** `src/segmentation/window/types.mbt`

### WindowStrategy::new

Create a new WindowStrategy with default configuration.

**Module:** `src/segmentation/window/types.mbt`

### WindowStrategy::with_config

Create a WindowStrategy with custom configuration.

**Module:** `src/segmentation/window/types.mbt`

### WindowStrategy::get_config

Get the configuration.

**Module:** `src/segmentation/window/types.mbt`

### default_segment_config

Default SegmentConfig.

**Module:** `src/segmentation/window/types.mbt`

### combine_sentences

Combine multiple sentences into a single text string. Takes sentences from start index with count sentences.

**Module:** `src/segmentation/window/divergence.mbt`

### get_window_end

Get the end position of the last sentence in a window.

**Module:** `src/segmentation/window/divergence.mbt`

### calculate_window_tfidf_divergence

Calculate TF-IDF divergence between adjacent sentence windows. Returns divergence values and their corresponding positions.

**Module:** `src/segmentation/window/divergence.mbt`

### min_max_normalize

Normalize an array of values using Min-Max normalization. Returns values in range [0, 1]. If all values are the same, returns 0.5 for all.  Note: This is a convenience re-export from segmentation/utils.

**Module:** `src/segmentation/window/divergence.mbt`

### find_local_maxima

Find local maxima indices where values exceed the threshold. A local maximum is a value that is greater than both its neighbors.  Note: This is a convenience re-export from segmentation/utils.

**Module:** `src/segmentation/window/divergence.mbt`

### default_config

Create a default SegmentConfig.

**Module:** `src/segmentation/window/segmenter.mbt`

### find_nearest_sentence_end

Find the nearest sentence boundary to a target position.

**Module:** `src/segmentation/window/segmenter.mbt`

### boundaries_to_segment_points

Convert boundary positions to @types.SegmentPoints.

**Module:** `src/segmentation/window/segmenter.mbt`

### apply_size_constraints

Apply size constraints to candidate boundary positions.

**Module:** `src/segmentation/window/segmenter.mbt`

### handle_few_sentences

Handle case when there are too few sentences for window analysis.

**Module:** `src/segmentation/window/segmenter.mbt`

### is_whitespace_only

Check if a string is whitespace only.

**Module:** `src/segmentation/window/segmenter.mbt`

### segment_by_divergence

Segment text using TF-IDF divergence between sentence windows. Returns an array of @types.SegmentPoints representing text boundaries.

**Module:** `src/segmentation/window/segmenter.mbt`

### segment

Segment text using default configuration.

**Module:** `src/segmentation/window/segmenter.mbt`

### default_adaptive_config

Create a default AdaptiveConfig.

**Module:** `src/segmentation/window/segmenter.mbt`

### calculate_adaptive_threshold

Calculate adaptive threshold from divergence values. Uses percentile of sorted values with a minimum floor.

**Module:** `src/segmentation/window/segmenter.mbt`

### subdivide_oversized_chunks

Subdivide oversized chunks recursively. Applies finer-grained segmentation to chunks exceeding max_chunk_size.

**Module:** `src/segmentation/window/segmenter.mbt`

### segment_adaptive

Segment text using adaptive threshold mode. Dynamically determines threshold based on divergence value distribution.

**Module:** `src/segmentation/window/segmenter.mbt`

### is_whitespace_only

Check if a string contains only whitespace.

**Module:** `src/segmentation/punctuation/punctuation.mbt`

### segment_by_punctuation

Segment text using punctuation-based chunking. Accumulates sentences into chunks of approximately target_chunk_size, splitting at sentence boundaries when possible.

**Module:** `src/segmentation/punctuation/punctuation.mbt`

### extract_substring

Extract substring from text given character offsets.

**Module:** `src/segmentation/punctuation/punctuation.mbt`

### segment

Segment text using punctuation strategy with default configuration.

**Module:** `src/segmentation/punctuation/punctuation.mbt`

### PunctuationConfig::new

Create a new PunctuationConfig with default values.

**Module:** `src/segmentation/punctuation/types.mbt`

### PunctuationConfig::create

Create a PunctuationConfig with custom values.

**Module:** `src/segmentation/punctuation/types.mbt`

### PunctuationConfig::get_target_chunk_size

Get the target chunk size.

**Module:** `src/segmentation/punctuation/types.mbt`

### PunctuationConfig::get_min_chunk_size

Get the minimum chunk size.

**Module:** `src/segmentation/punctuation/types.mbt`

### PunctuationConfig::get_max_chunk_size

Get the maximum chunk size.

**Module:** `src/segmentation/punctuation/types.mbt`

### PunctuationStrategy::new

Create a new PunctuationStrategy with default configuration.

**Module:** `src/segmentation/punctuation/types.mbt`

### PunctuationStrategy::with_config

Create a PunctuationStrategy with custom configuration.

**Module:** `src/segmentation/punctuation/types.mbt`

### PunctuationStrategy::get_config

Get the configuration.

**Module:** `src/segmentation/punctuation/types.mbt`

### SegmentPoint::new

Create a new SegmentPoint.

**Module:** `src/segmentation/types.mbt`

### SegmentPoint::get_start

Get the start position.

**Module:** `src/segmentation/types.mbt`

### SegmentPoint::get_end

Get the end position.

**Module:** `src/segmentation/types.mbt`

### SegmentPoint::get_type

Get the segment type.

**Module:** `src/segmentation/types.mbt`

### SegmentPoint::length

Get the length of the segment.

**Module:** `src/segmentation/types.mbt`

### TextSegment::new

Create a new TextSegment.

**Module:** `src/segmentation/types.mbt`

### TextSegment::with_heading

Create a new TextSegment with heading text.

**Module:** `src/segmentation/types.mbt`

### TextSegment::get_text

Get the text content.

**Module:** `src/segmentation/types.mbt`

### TextSegment::get_start

Get the start position.

**Module:** `src/segmentation/types.mbt`

### TextSegment::get_end

Get the end position.

**Module:** `src/segmentation/types.mbt`

### TextSegment::get_type

Get the segment type.

**Module:** `src/segmentation/types.mbt`

### TextSegment::get_heading_text

Get the heading text if present.

**Module:** `src/segmentation/types.mbt`

### TextSegment::length

Get the length of the segment.

**Module:** `src/segmentation/types.mbt`

### extract_substring

Extract substring from text given character offsets.

**Module:** `src/segmentation/types.mbt`

### SegmentPoint::to_text_segment

Convert a SegmentPoint to a TextSegment by extracting text from the original.

**Module:** `src/segmentation/types.mbt`

### segment_points_to_text_segments

Convert an array of SegmentPoints to TextSegments.

**Module:** `src/segmentation/types.mbt`

### WindowDivergence::new

Create a new WindowDivergence.

**Module:** `src/segmentation/types.mbt`

### WindowDivergence::get_values

Get the divergence values.

**Module:** `src/segmentation/types.mbt`

### WindowDivergence::get_positions

Get the window end positions.

**Module:** `src/segmentation/types.mbt`

### TfidfConfig::new

Create a new TfidfConfig with default values.

**Module:** `src/segmentation/tfidf/types.mbt`

### TfidfConfig::create

Create a TfidfConfig with custom values.

**Module:** `src/segmentation/tfidf/types.mbt`

### TfidfConfig::get_target_chunk_size

Get the target chunk size.

**Module:** `src/segmentation/tfidf/types.mbt`

### TfidfConfig::get_min_chunk_size

Get the minimum chunk size.

**Module:** `src/segmentation/tfidf/types.mbt`

### TfidfConfig::get_max_chunk_size

Get the maximum chunk size.

**Module:** `src/segmentation/tfidf/types.mbt`

### TfidfConfig::get_tfidf_threshold

Get the TF-IDF threshold.

**Module:** `src/segmentation/tfidf/types.mbt`

### TfidfConfig::get_window_size

Get the window size.

**Module:** `src/segmentation/tfidf/types.mbt`

### TfidfStrategy::new

Create a new TfidfStrategy with default configuration.

**Module:** `src/segmentation/tfidf/types.mbt`

### TfidfStrategy::with_config

Create a TfidfStrategy with custom configuration.

**Module:** `src/segmentation/tfidf/types.mbt`

### TfidfStrategy::get_config

Get the configuration.

**Module:** `src/segmentation/tfidf/types.mbt`

### is_whitespace_only

Check if a string contains only whitespace.

**Module:** `src/segmentation/tfidf/tfidf_segmenter.mbt`

### combine_sentences

Combine multiple sentences into a single text string.

**Module:** `src/segmentation/tfidf/tfidf_segmenter.mbt`

### get_window_end

Get the end position of the last sentence in a window.

**Module:** `src/segmentation/tfidf/tfidf_segmenter.mbt`

### min_max_normalize

Normalize an array of values using Min-Max normalization. Returns values in range [0, 1].

**Module:** `src/segmentation/tfidf/tfidf_segmenter.mbt`

### calculate_window_tfidf_divergence

Calculate TF-IDF divergence between adjacent sentence windows.

**Module:** `src/segmentation/tfidf/tfidf_segmenter.mbt`

### find_local_maxima

Find local maxima indices where values exceed the threshold.

**Module:** `src/segmentation/tfidf/tfidf_segmenter.mbt`

### find_nearest_sentence_end

Find the nearest sentence boundary to a target position.

**Module:** `src/segmentation/tfidf/tfidf_segmenter.mbt`

### apply_size_constraints

Apply size constraints to candidate boundary positions.

**Module:** `src/segmentation/tfidf/tfidf_segmenter.mbt`

### boundaries_to_segment_points

Convert boundary positions to SegmentPoints.

**Module:** `src/segmentation/tfidf/tfidf_segmenter.mbt`

### handle_few_sentences

Handle case when there are too few sentences for window analysis.

**Module:** `src/segmentation/tfidf/tfidf_segmenter.mbt`

### segment_by_tfidf

Segment text using TF-IDF based semantic detection.

**Module:** `src/segmentation/tfidf/tfidf_segmenter.mbt`

### segment

Segment text using TF-IDF strategy with default configuration.

**Module:** `src/segmentation/tfidf/tfidf_segmenter.mbt`

### ComponentDoc::new

Create a new ComponentDoc with required name.

**Module:** `src/docgen/types/types.mbt`

### ComponentDoc::make

Create a ComponentDoc with all fields.

**Module:** `src/docgen/types/types.mbt`

### ComponentDoc::get_name

Get the name.

**Module:** `src/docgen/types/types.mbt`

### ComponentDoc::get_file_tag

Get the file tag.

**Module:** `src/docgen/types/types.mbt`

### ComponentDoc::get_description

Get the description.

**Module:** `src/docgen/types/types.mbt`

### ComponentDoc::get_example

Get the example.

**Module:** `src/docgen/types/types.mbt`

### TokenInfo::new

Create a new TokenInfo.

**Module:** `src/docgen/types/types.mbt`

### TokenInfo::with_default

Create a TokenInfo with default value.

**Module:** `src/docgen/types/types.mbt`

### TokenInfo::get_name

Get the name.

**Module:** `src/docgen/types/types.mbt`

### TokenInfo::get_css_var

Get the CSS variable.

**Module:** `src/docgen/types/types.mbt`

### TokenInfo::get_description

Get the description.

**Module:** `src/docgen/types/types.mbt`

### TokenInfo::get_default_value

Get the default value.

**Module:** `src/docgen/types/types.mbt`

### TokenGroup::new

Create a new TokenGroup.

**Module:** `src/docgen/types/types.mbt`

### TokenGroup::with_tokens

Create a TokenGroup with tokens.

**Module:** `src/docgen/types/types.mbt`

### TokenGroup::get_name

Get the name.

**Module:** `src/docgen/types/types.mbt`

### TokenGroup::get_description

Get the description.

**Module:** `src/docgen/types/types.mbt`

### TokenGroup::get_tokens

Get the tokens.

**Module:** `src/docgen/types/types.mbt`

### TokenGroup::add_token

Add a token to the group.

**Module:** `src/docgen/types/types.mbt`

### generate_dep_diagram

Generate a module dependency diagram in Mermaid format. Output: graph LR with module dependencies as arrows.

**Module:** `src/docgen/diagram/mermaid.mbt`

### generate_call_diagram

Generate a call graph diagram in Mermaid format. Output: graph TD with function calls as arrows.

**Module:** `src/docgen/diagram/mermaid.mbt`

### generate_hierarchy_diagram

Generate a type hierarchy diagram in Mermaid classDiagram format.

**Module:** `src/docgen/diagram/mermaid.mbt`

### generate_overview_diagram

Generate a combined overview diagram showing modules and their key symbols.

**Module:** `src/docgen/diagram/mermaid.mbt`

### shorten_module_name

Shorten module name for display.

**Module:** `src/docgen/diagram/mermaid.mbt`

### shorten_symbol_name

Shorten symbol name for display.

**Module:** `src/docgen/diagram/mermaid.mbt`

### escape_mermaid

Escape special characters for Mermaid.

**Module:** `src/docgen/diagram/mermaid.mbt`

### sanitize_class_name

Sanitize class name for Mermaid classDiagram.

**Module:** `src/docgen/diagram/mermaid.mbt`

### split_by_char

Split string by character.

**Module:** `src/docgen/diagram/mermaid.mbt`

### split_by_str

Split string by substring.

**Module:** `src/docgen/diagram/mermaid.mbt`

### join_lines

Join array of strings with newline.

**Module:** `src/docgen/diagram/mermaid.mbt`

### render_json

Render complete documentation data as JSON.

**Module:** `src/docgen/render/json.mbt`

### render_graph_json

Render graph structure as JSON (simplified).

**Module:** `src/docgen/render/json.mbt`

### render_markdown

Render complete documentation to markdown.

**Module:** `src/docgen/render/markdown.mbt`

### render_api_reference

Render API reference section.

**Module:** `src/docgen/render/markdown.mbt`

### render_symbol

Render a single symbol.

**Module:** `src/docgen/render/markdown.mbt`

### render_cross_references

Render cross references table.

**Module:** `src/docgen/render/markdown.mbt`

### clean_doc

Clean documentation comment.

**Module:** `src/docgen/render/markdown.mbt`

### pluralize

Pluralize a kind name.

**Module:** `src/docgen/render/markdown.mbt`

### join_lines

Join lines with newline.

**Module:** `src/docgen/render/markdown.mbt`

### edge_kind

**Module:** `src/docgen/render/render_wbtest.mbt`

### find_string

**Module:** `src/docgen/render/render_wbtest.mbt`

### OutputFormat::markdown

Create Markdown output format.

**Module:** `src/docgen/render/types.mbt`

### OutputFormat::json

Create JSON output format.

**Module:** `src/docgen/render/types.mbt`

### RenderOptions::default

Create default render options.

**Module:** `src/docgen/render/types.mbt`

### RenderOptions::with_format

Create render options with format.

**Module:** `src/docgen/render/types.mbt`

### RenderOptions::new

Create render options with custom settings.

**Module:** `src/docgen/render/types.mbt`

### DocOutput::new

Create a new DocOutput.

**Module:** `src/docgen/render/types.mbt`

### DocOutput::with_json

Create DocOutput with JSON data only.

**Module:** `src/docgen/render/types.mbt`

### RenderOptions::get_format

**Module:** `src/docgen/render/types.mbt`

### RenderOptions::get_include_diagrams

**Module:** `src/docgen/render/types.mbt`

### RenderOptions::get_include_deps

**Module:** `src/docgen/render/types.mbt`

### RenderOptions::get_include_calls

**Module:** `src/docgen/render/types.mbt`

### RenderOptions::get_include_hierarchy

**Module:** `src/docgen/render/types.mbt`

### RenderOptions::get_include_refs

**Module:** `src/docgen/render/types.mbt`

### RenderOptions::get_max_diagram_nodes

**Module:** `src/docgen/render/types.mbt`

### DocOutput::get_api_reference

**Module:** `src/docgen/render/types.mbt`

### DocOutput::get_dependency_diagram

**Module:** `src/docgen/render/types.mbt`

### DocOutput::get_call_graph

**Module:** `src/docgen/render/types.mbt`

### DocOutput::get_type_hierarchy

**Module:** `src/docgen/render/types.mbt`

### DocOutput::get_cross_references

**Module:** `src/docgen/render/types.mbt`

### DocOutput::get_json_data

**Module:** `src/docgen/render/types.mbt`

### DocOutput::to_markdown

Convert DocOutput to complete markdown string.

**Module:** `src/docgen/render/types.mbt`

### join_sections

Join sections with double newline.

**Module:** `src/docgen/render/types.mbt`

### extract_extension

Extract file extension from path (without dot).

**Module:** `src/docgen/analyze/detect.mbt`

### detect_from_extension

Detect language from file extension.

**Module:** `src/docgen/analyze/detect.mbt`

### looks_like_typescript

Check if content looks like TypeScript/JavaScript.

**Module:** `src/docgen/analyze/detect.mbt`

### looks_like_python

Check if content looks like Python.

**Module:** `src/docgen/analyze/detect.mbt`

### looks_like_moonbit

Check if content looks like MoonBit.

**Module:** `src/docgen/analyze/detect.mbt`

### looks_like_go

Check if content looks like Go.

**Module:** `src/docgen/analyze/detect.mbt`

### looks_like_rust

Check if content looks like Rust.

**Module:** `src/docgen/analyze/detect.mbt`

### looks_like_html

Check if content looks like HTML.

**Module:** `src/docgen/analyze/detect.mbt`

### looks_like_css

Check if content looks like CSS.

**Module:** `src/docgen/analyze/detect.mbt`

### looks_like_markdown

Check if content looks like Markdown.

**Module:** `src/docgen/analyze/detect.mbt`

### looks_like_sql

Check if content looks like SQL.

**Module:** `src/docgen/analyze/detect.mbt`

### detect_from_content

Detect language from file content.

**Module:** `src/docgen/analyze/detect.mbt`

### detect_language

Detect file language using both extension and content analysis.

**Module:** `src/docgen/analyze/detect.mbt`

### analyze_file

Analyze a file and return FileInfo with spec selection.

**Module:** `src/docgen/analyze/detect.mbt`

### has_pattern

Check if string contains a pattern.

**Module:** `src/docgen/analyze/detect.mbt`

### find_substring

Find substring index.

**Module:** `src/docgen/analyze/detect.mbt`

### to_upper

Convert string to uppercase (ASCII only).

**Module:** `src/docgen/analyze/detect.mbt`

### DetectedLang::to_string

**Module:** `src/docgen/analyze/types.mbt`

### DetectedLang::doc_spec_name

Get the appropriate KGF spec name for documentation extraction.

**Module:** `src/docgen/analyze/types.mbt`

### FileInfo::new

**Module:** `src/docgen/analyze/types.mbt`

### FileInfo::get_path

**Module:** `src/docgen/analyze/types.mbt`

### FileInfo::get_lang

**Module:** `src/docgen/analyze/types.mbt`

### FileInfo::get_ext

**Module:** `src/docgen/analyze/types.mbt`

### FileInfo::get_spec_name

**Module:** `src/docgen/analyze/types.mbt`

### DocSymbol::new

**Module:** `src/docgen/analyze/types.mbt`

### DocSymbol::with_doc

**Module:** `src/docgen/analyze/types.mbt`

### DocSymbol::get_id

**Module:** `src/docgen/analyze/types.mbt`

### DocSymbol::get_name

**Module:** `src/docgen/analyze/types.mbt`

### DocSymbol::get_kind

**Module:** `src/docgen/analyze/types.mbt`

### DocSymbol::get_doc

**Module:** `src/docgen/analyze/types.mbt`

### DocSymbol::get_parent

**Module:** `src/docgen/analyze/types.mbt`

### DocSymbol::get_file

**Module:** `src/docgen/analyze/types.mbt`

### DocSymbol::get_children

**Module:** `src/docgen/analyze/types.mbt`

### DocSymbol::set_parent

**Module:** `src/docgen/analyze/types.mbt`

### DocSymbol::add_child

**Module:** `src/docgen/analyze/types.mbt`

### AnalysisResult::new

**Module:** `src/docgen/analyze/types.mbt`

### AnalysisResult::add_file

**Module:** `src/docgen/analyze/types.mbt`

### AnalysisResult::add_symbol

**Module:** `src/docgen/analyze/types.mbt`

### AnalysisResult::set_module_doc

**Module:** `src/docgen/analyze/types.mbt`

### AnalysisResult::get_files

**Module:** `src/docgen/analyze/types.mbt`

### AnalysisResult::get_graph

**Module:** `src/docgen/analyze/types.mbt`

### AnalysisResult::set_graph

**Module:** `src/docgen/analyze/types.mbt`

### AnalysisResult::get_symbols

**Module:** `src/docgen/analyze/types.mbt`

### AnalysisResult::get_module_docs

**Module:** `src/docgen/analyze/types.mbt`

### edge_kind

**Module:** `src/docgen/build/pipeline_wbtest.mbt`

### DocConfig::new

Create a new DocConfig.

**Module:** `src/docgen/build/types.mbt`

### DocConfig::get_files

**Module:** `src/docgen/build/types.mbt`

### DocConfig::get_specs

**Module:** `src/docgen/build/types.mbt`

### DocConfig::get_options

**Module:** `src/docgen/build/types.mbt`

### DocConfig::get_root_path

**Module:** `src/docgen/build/types.mbt`

### build

Build documentation from configuration. This is the main entry point for documentation generation.

**Module:** `src/docgen/build/pipeline.mbt`

### build_with_graph

Build documentation and return both the output and the merged graph.

**Module:** `src/docgen/build/pipeline.mbt`

### analyze_files

Analyze files with their corresponding KGF specs.

**Module:** `src/docgen/build/pipeline.mbt`

### analyze_with_spec

Analyze a single file with a KGF spec.

**Module:** `src/docgen/build/pipeline.mbt`

### merge_graphs

Merge multiple graphs into one.

**Module:** `src/docgen/build/pipeline.mbt`

### quick_build

Quick build from files without explicit spec loading. Uses spec name detection to select appropriate specs.

**Module:** `src/docgen/build/pipeline.mbt`

### build_markdown

Build and return markdown string.

**Module:** `src/docgen/build/pipeline.mbt`

### build_json

Build and return JSON string.

**Module:** `src/docgen/build/pipeline.mbt`

### group_by_file

Group symbols by file.

**Module:** `src/docgen/build/pipeline.mbt`

### group_by_kind

Group symbols by kind.

**Module:** `src/docgen/build/pipeline.mbt`

### generate_markdown

Generate markdown from analysis result. Legacy function for backward compatibility.

**Module:** `src/docgen/build/pipeline.mbt`

### extract_call_graph

Extract all call relationships from the graph.

**Module:** `src/docgen/query/calls.mbt`

### get_callees

Get functions called by a given symbol.

**Module:** `src/docgen/query/calls.mbt`

### get_callers

Get callers of a given function.

**Module:** `src/docgen/query/calls.mbt`

### get_call_chain

Get call chain starting from a function (transitive callees).

**Module:** `src/docgen/query/calls.mbt`

### extract_module_deps

Extract all module dependencies from the graph. Looks for ModuleDependsOn edges and extracts via/dep_kind from attrs.

**Module:** `src/docgen/query/deps.mbt`

### get_direct_deps

Get direct dependencies of a module.

**Module:** `src/docgen/query/deps.mbt`

### get_dependents

Get all modules that depend on the given module (reverse deps).

**Module:** `src/docgen/query/deps.mbt`

### get_transitive_deps

Build transitive closure of dependencies starting from a module. Returns all modules that the given module depends on, directly or indirectly.

**Module:** `src/docgen/query/deps.mbt`

### extract_references

Extract all symbol references from the graph.

**Module:** `src/docgen/query/refs.mbt`

### get_references_to

Get all places where a symbol is referenced.

**Module:** `src/docgen/query/refs.mbt`

### get_references_from

Get all symbols referenced from a given location.

**Module:** `src/docgen/query/refs.mbt`

### extract_declarations

Extract all symbol declarations from the graph. Looks for Declares edges and extracts doc/name/kind from attrs.

**Module:** `src/docgen/query/refs.mbt`

### get_module_declarations

Get declarations within a module.

**Module:** `src/docgen/query/refs.mbt`

### count_references

Get the number of references to each symbol. Returns a map of symbol_id -> reference_count.

**Module:** `src/docgen/query/refs.mbt`

### ModuleDep::new

Create a new ModuleDep.

**Module:** `src/docgen/query/types.mbt`

### CallInfo::new

Create a new CallInfo.

**Module:** `src/docgen/query/types.mbt`

### TypeRelation::new

Create a new TypeRelation.

**Module:** `src/docgen/query/types.mbt`

### SymbolRef::new

Create a new SymbolRef.

**Module:** `src/docgen/query/types.mbt`

### SymbolDecl::new

Create a new SymbolDecl.

**Module:** `src/docgen/query/types.mbt`

### ModuleDep::get_from

**Module:** `src/docgen/query/types.mbt`

### ModuleDep::get_to

**Module:** `src/docgen/query/types.mbt`

### ModuleDep::get_via

**Module:** `src/docgen/query/types.mbt`

### ModuleDep::get_dep_kind

**Module:** `src/docgen/query/types.mbt`

### CallInfo::get_caller

**Module:** `src/docgen/query/types.mbt`

### CallInfo::get_callee

**Module:** `src/docgen/query/types.mbt`

### CallInfo::get_file

**Module:** `src/docgen/query/types.mbt`

### TypeRelation::get_child

**Module:** `src/docgen/query/types.mbt`

### TypeRelation::get_parent

**Module:** `src/docgen/query/types.mbt`

### TypeRelation::get_relation

**Module:** `src/docgen/query/types.mbt`

### SymbolRef::get_symbol

**Module:** `src/docgen/query/types.mbt`

### SymbolRef::get_ref_site

**Module:** `src/docgen/query/types.mbt`

### SymbolRef::get_ref_kind

**Module:** `src/docgen/query/types.mbt`

### SymbolDecl::get_id

**Module:** `src/docgen/query/types.mbt`

### SymbolDecl::get_name

**Module:** `src/docgen/query/types.mbt`

### SymbolDecl::get_kind

**Module:** `src/docgen/query/types.mbt`

### SymbolDecl::get_module_id

**Module:** `src/docgen/query/types.mbt`

### SymbolDecl::get_doc

**Module:** `src/docgen/query/types.mbt`

### extract_type_hierarchy

Extract all type hierarchy relationships. Looks for Extends and Implements edges.

**Module:** `src/docgen/query/hierarchy.mbt`

### get_parents

Get parents (extended/implemented types) of a type.

**Module:** `src/docgen/query/hierarchy.mbt`

### get_children

Get children (implementing/extending types) of a type.

**Module:** `src/docgen/query/hierarchy.mbt`

### get_ancestors

Get all ancestors (transitive parents) of a type.

**Module:** `src/docgen/query/hierarchy.mbt`

### get_descendants

Get all descendants (transitive children) of a type.

**Module:** `src/docgen/query/hierarchy.mbt`

### edge_kind

**Module:** `src/docgen/query/query_wbtest.mbt`

### is_cjk_char

Check if a character is a CJK (Chinese/Japanese/Korean) character.

**Module:** `src/text/tokenizer/tokenizer.mbt`

### is_word_char

Check if a character is a letter or digit (for word tokenization).

**Module:** `src/text/tokenizer/tokenizer.mbt`

### to_lower

Convert a character to lowercase (ASCII only).

**Module:** `src/text/tokenizer/tokenizer.mbt`

### normalize_text

Normalize text for TF-IDF processing. Converts to lowercase and normalizes whitespace.

**Module:** `src/text/tokenizer/tokenizer.mbt`

### extract_word_tokens

Extract word tokens from text. Returns tokens of 2 or more characters.

**Module:** `src/text/tokenizer/tokenizer.mbt`

### extract_character_bigrams

Extract character bigrams from text for CJK processing. Removes whitespace before generating bigrams.

**Module:** `src/text/tokenizer/tokenizer.mbt`

### tokenize_for_tfidf

Tokenize text for TF-IDF vectorization. Combines word tokens and character bigrams for mixed language support.

**Module:** `src/text/tokenizer/tokenizer.mbt`

### build_term_frequency

Build term frequency map from a list of tokens. Returns a map from term to count.

**Module:** `src/text/tfidf/tfidf.mbt`

### build_document_frequency

Build document frequency map from multiple tokenized documents. Returns a map from term to the number of documents containing that term.

**Module:** `src/text/tfidf/tfidf.mbt`

### build_tfidf_vector

Build a TF-IDF vector from tokens, document frequency, and total document count. TF(term, doc) = count(term) / total_tokens IDF(term) = log((1 + total_docs) / (1 + df)) + 1

**Module:** `src/text/tfidf/tfidf.mbt`

### sqrt

Calculate the square root using Newton's method.

**Module:** `src/text/tfidf/tfidf.mbt`

### vector_norm

Calculate the L2 norm of a TF-IDF vector.

**Module:** `src/text/tfidf/tfidf.mbt`

### cosine_similarity

Calculate cosine similarity between two TF-IDF vectors. Returns 1.0 for identical vectors, 0.0 for orthogonal vectors. If both vectors are empty, returns 1.0. If only one vector is empty, returns 0.0.

**Module:** `src/text/tfidf/tfidf.mbt`

### cosine_distance

Calculate cosine distance between two TF-IDF vectors. Returns 0.0 for identical vectors, 1.0 for orthogonal vectors. cosine_distance = 1 - cosine_similarity

**Module:** `src/text/tfidf/tfidf.mbt`

### calculate_adjacent_tfidf_distance

Calculate TF-IDF cosine distances between adjacent texts. Returns an array of distances where distances[i] is the distance between texts[i] and texts[i+1].

**Module:** `src/text/tfidf/tfidf.mbt`

### TfidfVector::new

Create a new empty TfidfVector.

**Module:** `src/text/tfidf/types.mbt`

### TfidfVector::from_terms

Create a TfidfVector from an existing term map.

**Module:** `src/text/tfidf/types.mbt`

### TfidfVector::get

Get the weight for a given term. Returns 0.0 if not found.

**Module:** `src/text/tfidf/types.mbt`

### TfidfVector::set

Set the weight for a given term.

**Module:** `src/text/tfidf/types.mbt`

### TfidfVector::length

Get the number of terms in the vector.

**Module:** `src/text/tfidf/types.mbt`

### TfidfVector::is_empty

Check if the vector is empty.

**Module:** `src/text/tfidf/types.mbt`

### TfidfVector::iter

Get an iterator over the terms.

**Module:** `src/text/tfidf/types.mbt`
