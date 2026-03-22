# window

## API

- **`min_max_normalize`** (Function) — Normalize an array of values using Min-Max normalization.
- **`find_local_maxima`** (Function) — Find local maxima indices where values exceed the threshold.
- **`segment_hybrid_adaptive`** (Function) — Segment text using NCD+TF-IDF hybrid adaptive mode.
- **`segment_by_divergence`** (Function) — Segment text using TF-IDF divergence between sentence windows.
- **`HybridAdaptiveConfig`** (Struct) — Configuration for NCD+TF-IDF hybrid adaptive segmentation.
- **`calculate_window_tfidf_divergence`** (Function) — Calculate TF-IDF divergence between adjacent sentence windows.
- **`AdaptiveConfig`** (Struct) — Configuration for adaptive segmentation.
- **`segment_adaptive`** (Function) — Segment text using adaptive threshold mode.
- **`subdivide_oversized_chunks`** (Function) — Subdivide oversized chunks recursively.
- **`calculate_adaptive_threshold`** (Function) — Calculate adaptive threshold from divergence values.
- **`WindowStrategy`** (Struct) — Window-based divergence segmentation strategy.
- **`subdivide_oversized_chunks_hybrid`** (Function) — Subdivide oversized chunks using hybrid NCD+TF-IDF divergence.
- **`with_default_weights`** (Function) — Create a HybridAdaptiveConfig with default weights (0.5/0.5).
- **`with_config`** (Function) — Create a WindowStrategy with custom configuration.
- **`segment`** (Function) — Segment text using default configuration.

And 39 more symbols.
