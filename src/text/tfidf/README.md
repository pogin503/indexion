# tfidf

## API

- **`cosine_similarity`** (Function) — Calculate cosine similarity between two TF-IDF vectors.
- **`build_tfidf_vector`** (Function) — Build a TF-IDF vector from tokens, document frequency, and total document count.
- **`cosine_distance`** (Function) — Calculate cosine distance between two TF-IDF vectors.
- **`all_pairs_above_threshold`** (Function) — Calculate all pairwise similarities above a threshold.
- **`build_document_frequency`** (Function) — Build document frequency map from multiple tokenized documents.
- **`TfidfBatch`** (Struct) — Precomputed TF-IDF vectors for batch similarity calculation.
- **`similarity`** (Function) — Calculate similarity between two documents by index.
- **`from_tokens`** (Function) — Create a TfidfBatch from pre-tokenized documents.
- **`build_term_frequency`** (Function) — Build term frequency map from a list of tokens.
- **`calculate_adjacent_tfidf_distance_from_tokenized`** (Function) — Calculate TF-IDF cosine distances between adjacent pre-tokenized documents.
- **`all_pairs_above_threshold_with_stats`** (Function) — Calculate all pairwise similarities above a threshold with diagnostics.
- **`calculate_tfidf_distance_from_tokens`** (Function) — Calculate TF-IDF cosine distance between two pre-tokenized documents.
- **`TfidfVector`** (Struct) — A sparse TF-IDF vector representation using term-weight mapping.
- **`get`** (Function) — Get the weight for a given term. Returns 0.0 if not found.
- **`sqrt`** (Function) — Calculate the square root using Newton's method.

And 40 more symbols.
