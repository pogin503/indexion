# identity — names as first-class citizens

This package treats **names** as data worth reasoning about, not as
side effects of slugification or display rendering. A name is a
promise to point at something; reconcile-style tooling here measures
how well that promise has been kept.

## Why this package exists

Across indexion, names appear in many shapes:

- file names ("01-outline.md")
- heading titles ("Setting Notes", "南京 ・奇望街")
- page ids in a wiki manifest ("character-dorian-gray")
- function and module identifiers in code

In every case the name and the thing it names are **two different
artefacts** that drift apart over time. The writer renames a file
but the body still discusses an older subject. A heading is
"Setting Notes" but the body is about a single character. A function
is called `parse_kgf` but its body now does resolution as well.

Tools that conflate the two — by, say, deriving a slug from the
title and using it as the file id — bake the drift in. This
package treats names as identifiers we care about per se.

## Public surface

```
Name             { id, display }              — the data type
NamedEntity      { name, content, origin }    — content with a name
NameDivergence   { score, action, rationale } — reconcile-style report
NameAction       Keep | Rename | Split | Hollow

derive_id(text, path_hint, registry)         → kebab-case identifier
derive_display(text)                         → human label
derive_name(text, path_hint, registry)       → Name { id, display }
identifier_kinds_for(registry, path_hint)    → spec-driven content kinds
score_name_divergence(entity, registry)      → NameDivergence

IdentityAuditConfig                         — code identity scan settings
IdentityAuditReport                         — file/folder/symbol audit report
audit_code_identity(config)                 → IdentityAuditReport
```

## How it stays SoT-honest

- All tokenisation goes through `@kgf_tokenize.tokenize_file`.
- "What counts as a content token" comes from the spec's
  `identifier_kinds` declaration via `identifier_kinds_for`.
- No character-class or codepoint-range hardcoding lives in this
  package. The only fixed Unicode behaviour is the ASCII-range
  case folding in `lower_ascii`, which is a spec-defined invariant
  of Unicode itself, not a story-specific heuristic.

## Why this is not a slug helper

URL slugs (`@common.slugify`) and HTML anchors (`@common.make_anchor`)
have well-defined formats with no notion of source-of-truth or
content drift. They are pure string transforms. This package is
about the *relationship* between names and content; sluggification
is one possible serialised form of an `Id`, not the subject of the
package.

## Consumers

- `src/story/wiki/planner.mbt` — derives page ids from heading titles
  via `derive_id`
- `src/story/divergence.mbt` — reads `identifier_kinds_for` to filter
  content tokens for BM25 (replacing a hand-coded language list)
- `cmd/indexion/story/names/` — `indexion story names` reports name ↔
  content drift across spec headings
- `cmd/indexion/identity/` — `indexion identity audit` reports file,
  folder, and symbol name ↔ content drift for codebases

## Code Identity Audit

`audit_code_identity` builds a code graph for the target paths, derives
file/folder/symbol summaries from graph declarations, docs, module notes, and
path scope terms, then compares those summaries with the names they claim to
identify.

File basenames are evaluated with their immediate parent scope, so conventional
entrypoints such as `cli.mbt` are checked as package-level names rather than
context-free nouns. Declaration-heavy files whose graph is mostly types,
structs, enums, or interfaces are reported as insufficient content instead of a
rename/split candidate; they often need more behavioral evidence before a naming
decision is meaningful.

```bash
indexion identity audit src/
indexion identity audit --format=json --output=.indexion/cache/identity/report.json .
```
