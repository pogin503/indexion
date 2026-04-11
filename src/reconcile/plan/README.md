# plan

## API

- **`VocabularyDivergence`** (Struct) — Vocabulary-level divergence between a source module and its documentation.
- **`build_fragment_inverted_index`** (Function) — Build inverted index: token → [fragment array index].
- **`ReconcileAggregateSuggestion`** (Struct) — Grouped suggestion aggregating multiple candidates at module or project scope.
- **`ReconcileCandidate`** (Struct) — A candidate representing a code symbol that may need documentation updates.
- **`FreshAnalysisState`** (Struct) — State from a full (non-cached) analysis, needed for CLI cache persistence.
- **`DocAnchor`** (Struct) — Anchor referencing a documentation fragment within a reconcile candidate.
- **`ReconcileReport`** (Struct) — Full reconcile report output including candidates, reviews, and summary.
- **`IndexedRecordEntry`** (Struct) — An entry in the index database tracking a record's digest and vector ID.
- **`ReconcileManifest`** (Struct) — Persistent manifest tracking indexed records, reviews, and fingerprints.
- **`ReconcileReportConfig`** (Struct) — Snapshot of configuration settings stored within the reconcile report.
- **`CodeUnit`** (Struct) — A code symbol extracted from the dependency graph for reconciliation.
- **`ModuleFileGroup`** (Struct) — A group of source files and documentation files within a directory.
- **`LogicalReviewTask`** (Struct) — A queued task for human logical review of a reconcile candidate.
- **`empty`** (Function) — Create an empty manifest with default version and zero counters.
- **`default`** (Function) — Create a default reconcile configuration with sensible defaults.
- **`CacheState`** (Struct) — Cache hit/miss state and fingerprint info for incremental runs.
- **`match_fragment_with_terms`** (Function) — Optimized match using pre-computed lowered text and unit terms.
- **`AnalysisResult`** (Enum) — Core analysis result — discriminated by whether cache was hit.
- **`CodeAnchor`** (Struct) — Anchor referencing a code symbol within a reconcile candidate.
- **`LogicalReviewEntry`** (Struct) — Persisted state of a logical review decision in the manifest.
- **`ReconcileConfig`** (Struct) — CLI and file-backed configuration for the reconcile command.
- **`MappingEvidence`** (Struct) — Evidence supporting the code-to-doc mapping for a candidate.
- **`DocFragment`** (Struct) — A fragment of documentation extracted from a document file.
- **`ReviewDecisionInput`** (Struct) — User-supplied review decision for a logical review task.
- **`ReconcileSummary`** (Struct) — Aggregate statistics summarizing the reconcile report.
- **`allocate_vector_id`** (Function) — Allocate the next vector ID from the manifest counter.
- **`UnitMatchTerms`** (Struct) — Pre-computed lowered search terms for a code unit.
- **`TokenizedModuleGroup`** (Struct) — Tokenized module group for vocabulary comparison.
- **`unit_match_terms`** (Function) — Build pre-computed match terms for a code unit.
- **`maybe_use_cache`** (Function) — 


- **`is_all_digits`** (Function) — 


- **`contains_string`** (Function) — 


- **`sort_strings`** (Function) — 


- **`status_priority`** (Function) — 


- **`records_db_path`** (Function) — 


- **`current_epoch_seconds`** (Function) — 


- **`compute_review_state_hash`** (Function) — 


- **`build_exact_token_index`** (Function) — 


- **`load_record_db`** (Function) — 


- **`normalize_review_status`** (Function) — 


- **`timestamp_digest_part`** (Function) — 


- **`candidate_digest`** (Function) — 


- **`review_key_for_digest`** (Function) — 


- **`candidate_record_attrs`** (Function) — 


- **`logical_review_attrs`** (Function) — 


- **`ensure_record_slot`** (Function) — 


- **`keep_record_keys`** (Function) — 


- **`load_review_decisions`** (Function) — 


- **`reconcile_path`** (Function) — 


- **`manifest_path`** (Function) — 


- **`report_cache_path`** (Function) — 


- **`stale_index_path`** (Function) — 


- **`load_manifest`** (Function) — 


- **`save_manifest`** (Function) — 


- **`build_code_anchor`** (Function) — 


- **`load_cached_report`** (Function) — 


- **`extract_toml_fragments`** (Function) — 


- **`sort_aggregate_suggestions`** (Function) — 


- **`save_cached_report`** (Function) — 


- **`report`** (Function) — 


- **`project_doc_paths`** (Function) — 


- **`build_doc_anchor`** (Function) — 


- **`AggregateBucket`** (Struct) — 


- **`FragmentMatchSignals`** (Struct) — 


- **`cleanup_stale_index`** (Function) — 


- **`is_ascii_upper`** (Function) — 


- **`is_ascii_lower`** (Function) — 


- **`is_ascii_digit`** (Function) — 


- **`is_token_separator`** (Function) — 


- **`is_token_char`** (Function) — 


- **`is_specific_token`** (Function) — 


- **`add_specific_token`** (Function) — 


- **`make_hash`** (Function) — 


- **`normalize_feature_token_text`** (Function) — 


- **`add_surface_term`** (Function) — 


- **`file_stem`** (Function) — 


- **`add_path_anchor_terms`** (Function) — 


- **`configured_doc_roots`** (Function) — 


- **`coverage_anchor_term`** (Function) — 


- **`build_config_hash`** (Function) — 


- **`build_source_fingerprint`** (Function) — 


- **`extract_plaintext_fragments`** (Function) — 


- **`time_relation`** (Function) — 


- **`classify_match_result`** (Function) — 


- **`candidate_id`** (Function) — 


- **`discovery_roots`** (Function) — 


- **`limit_candidates`** (Function) — 


- **`build_summary`** (Function) — 


- **`push_unique`** (Function) — 


- **`aggregate_bucket`** (Function) — 


- **`aggregate_key`** (Function) — 


- **`project_group_path`** (Function) — 


- **`add_candidate_to_bucket`** (Function) — 


- **`build_aggregate_suggestions`** (Function) — 


- **`collapse_aggregate_only_candidates`** (Function) — 


- **`is_blank_line`** (Function) — 


- **`normalize_spaces`** (Function) — 


- **`max_distance`** (Function) — 


- **`count_unique_tokens`** (Function) — 


- **`extract_document_fragments`** (Function) — 


- **`make_fragment`** (Function) — 


- **`markdown_heading_text`** (Function) — 


- **`extract_markdown_fragments`** (Function) — 


- **`CandidateBuildResult`** (Struct) — 


- **`collect_code_file_states`** (Function) — 
- **`match_units_batch`** (Function) — 
- **`ModuleSignals`** (Struct) — 
- **`document_path_scope`** (Function) — 
- **`run_analysis`** (Function) — 
- **`report_config`** (Function) — 
- **`IndexSyncResult`** (Struct) — 
- **`timestamp_for_path`** (Function) — 
- **`lower_string`** (Function) — 
- **`persisted_report`** (Function) —
