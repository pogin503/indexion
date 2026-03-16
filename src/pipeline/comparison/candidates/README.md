# candidates

Candidate pair generation for batch comparison.

## Overview

Provides two strategies for generating (i, j) pairs to compare:

- **Brute force** — all pairs, for small datasets
- **TF-IDF prefilter** — inverted index narrowing, for large datasets

Used by `tfidf.mbt`, `tree.mbt`, and `hybrid.mbt` in the parent comparison package.

## API

- `brute_force(n)` — Generate all (i, j) pairs where i < j
- `tfidf_prefilter(files, registry, threshold)` — TF-IDF inverted index candidate filtering
- `normalize_pairs(raw)` — Normalize (i, j, score) tuples to (i, j) with i < j
- `pair_key(i, j)` — Deduplication key for a pair
