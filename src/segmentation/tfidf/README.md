# tfidf

## API

- **`TfidfStrategy`** (Struct) — TF-IDF based segmentation strategy.
- **`segment`** (Function) — Segment text using TF-IDF strategy with default configuration.
- **`calculate_window_tfidf_divergence`** (Function) — Calculate TF-IDF divergence between adjacent sentence windows.
- **`segment_by_tfidf`** (Function) — Segment text using TF-IDF based semantic detection.
- **`with_config`** (Function) — Create a TfidfStrategy with custom configuration.
- **`new`** (Function) — Create a new TfidfConfig with default values.
- **`TfidfConfig`** (Struct) — Configuration for TF-IDF based segmentation.
- **`create`** (Function) — Create a TfidfConfig with custom values.
- **`default_min_chunk_size`** (Variable) — Default minimum chunk size.
- **`default_max_chunk_size`** (Variable) — Default maximum chunk size.
- **`get_min_chunk_size`** (Function) — Get the minimum chunk size.
- **`get_max_chunk_size`** (Function) — Get the maximum chunk size.
- **`default_target_chunk_size`** (Variable) — Default target chunk size.
- **`get_target_chunk_size`** (Function) — Get the target chunk size.
- **`default_tfidf_threshold`** (Variable) — Default TF-IDF threshold.

And 13 more symbols.
