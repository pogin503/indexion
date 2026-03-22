# types

## API

- **`SimilarityStrategy`** (Trait) — Common interface for text similarity strategies.
- **`create`** (Function) — Create a HybridConfig with custom weights.
- **`new`** (Function) — Create a default HybridConfig with equal weights (0.5, 0.5).
- **`SimilarityResult`** (Struct) — Result of similarity calculation between two items.
- **`HybridConfig`** (Struct) — Configuration for the hybrid NCD + TF-IDF strategy.
- **`from_similarity`** (Function) — Create a SimilarityResult from similarity.
- **`from_distance`** (Function) — Create a SimilarityResult from distance.
- **`get_similarity`** (Function) — Get the similarity value.
- **`get_distance`** (Function) — Get the distance value.
- **`get_tfidf_weight`** (Function) — Get the TF-IDF weight.

And 6 more symbols.
