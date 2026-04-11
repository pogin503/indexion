# minhash

## API

- **`new`** (Function) — Create an LSH index configured for a target Jaccard threshold.
- **`select_band_params`** (Function) — Select (bands, rows_per_band) that best approximate the target threshold.
- **`universal_hash`** (Function) — Universal hash function family: h_i(x) = (a_i * x + b_i) mod p
- **`from_tokens`** (Function) — Create a MinHash signature from a set of tokens.
- **`candidate_pairs_above_threshold`** (Function) — Query for candidate pairs with MinHash Jaccard re-scoring.
- **`hash_band`** (Function) — Hash a band (a contiguous slice of the signature) to a single int.
- **`jaccard`** (Function) — Estimate Jaccard similarity from two MinHash signatures.
- **`candidate_pairs`** (Function) — Query for candidate pairs: all (i, j) where i < j that share
- **`insert`** (Function) — Insert a document's MinHash signature into the LSH index.
- **`MinHashSignature`** (Struct) — A MinHash signature: a fixed-length array of minimum hash values.
- **`fnv1a_hash`** (Function) — FNV-1a hash for strings, producing a non-negative 32-bit hash.
- **`LSHIndex`** (Struct) — LSH index for approximate nearest neighbor search.
- **`init_buckets`** (Function) — Initialize empty bucket maps for each band.
- **`get_values`** (Function) — Get the signature values for LSH banding.
- **`length`** (Function) — Get the number of documents in the index.
