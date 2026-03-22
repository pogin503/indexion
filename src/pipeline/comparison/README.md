# comparison

## API

- **`select_apted_mode`** (Function) — 0=TF-IDF only, 1=brute_force APTED, 2=prefilter APTED, 3=strict prefilter
- **`FileEntry`** (Struct) — A file entry with display name and content for batch comparison.
- **`compare_hybrid`** (Function) — Hybrid comparison with automatic strategy selection.
- **`compare`** (Function) — Run batch comparison with the specified strategy.
- **`filter_cross_directory`** (Function) — Filter matches to only cross-directory pairs.
- **`compare_tfidf`** (Function) — Run batch comparison using TF-IDF strategy.
- **`compare_apted`** (Function) — Run batch comparison using APTED strategy.
- **`compare_tsed`** (Function) — Run batch comparison using TSED strategy.
- **`create`** (Function) — Create a BatchConfig with custom values.
- **`BatchResult`** (Struct) — Batch comparison result with statistics.
- **`SimilarityMatch`** (Struct) — A similarity match between two files.
- **`BatchConfig`** (Struct) — Batch comparison configuration.
- **`get_matches`** (Function) — Get matches from result.

And 27 more symbols.
