# align

## API

- **`extract_alnum`** (Function) — Extract word characters from a string, stripping punctuation and symbols.
- **`identifier_match_score`** (Function) — Score based on direct identifier matching between spec inline code refs
- **`extract_inline_code_refs`** (Function) — Extract backtick-enclosed identifiers from criteria text.
- **`decimal_to_hex`** (Function) — 


- **`literal_present`** (Function) — 


- **`load_snapshot`** (Function) — 


- **`has_cache_artifacts`** (Function) — 


- **`purge_cache_file`** (Function) — 


- **`purge_corrupt_snapshot_cache`** (Function) — 


- **`append_history_entry`** (Function) — 


- **`save_snapshot`** (Function) — 


- **`json_string_field`** (Function) — 


- **`json_int_field`** (Function) — 


- **`parse_int_or_zero`** (Function) — 


- **`json_string_array_field`** (Function) — 


- **`default`** (Function) — 


- **`AlignCommitInfo`** (Struct) — 


- **`AlignHistoryEntry`** (Struct) — 


- **`RequirementNode`** (Struct) — 


- **`ScenarioNode`** (Struct) — 


- **`ImplementationNode`** (Struct) — 


- **`TraceEdge`** (Struct) — 


- **`AlignDiffItem`** (Struct) — 


- **`AlignSummary`** (Struct) — 


- **`cache_file_path`** (Function) — 


- **`AlignSnapshot`** (Struct) — 


- **`AlignCacheManifest`** (Struct) — 


- **`AlignTraceStore`** (Struct) — 


- **`AlignDiffStore`** (Struct) — 


- **`AlignHistoryStore`** (Struct) — 


- **`AlignDiffReport`** (Struct) — 


- **`AlignTraceReport`** (Struct) — 


- **`AlignSuggestion`** (Struct) — 


- **`AlignSuggestReport`** (Struct) — 


- **`AlignStatusReport`** (Struct) — 


- **`ncd_similarity`** (Function) — 


- **`trim`** (Function) — 


- **`lower_ascii`** (Function) — 


- **`config_hash`** (Function) — 


- **`file_exists`** (Function) — 


- **`path_is_dir`** (Function) — 


- **`tracking_root`** (Function) — 


- **`requirement_excerpt`** (Function) — 


- **`implementation_excerpt`** (Function) — 


- **`safe_line`** (Function) — 


- **`append_implementation_node`** (Function) — 


- **`requirement_text`** (Function) — 


- **`merge_unique_strings`** (Function) — 


- **`requirement_section_refs`** (Function) — 


- **`requirement_literals`** (Function) — 


- **`requirement_table_pairs`** (Function) — 


- **`is_section_ref_char`** (Function) — 


- **`normalize_section_ref`** (Function) — 


- **`is_section_ref_token`** (Function) — 


- **`tokenize_section_words`** (Function) — 


- **`collect_section_refs`** (Function) — 


- **`is_parent_section_ref`** (Function) — 


- **`section_reference_score`** (Function) — 


- **`find_previous_edge`** (Function) — 


- **`literals_from_text`** (Function) — 


- **`read_json_file`** (Function) — 


- **`literal_overlap_score`** (Function) — 


- **`decode_table_pair`** (Function) — 


- **`identifier_tokens`** (Function) — 


- **`identifier_candidates_from_line`** (Function) — 


- **`pair_present_in_text`** (Function) — 


- **`table_pair_overlap_score`** (Function) — 


- **`implementation_evidence_text`** (Function) — 


- **`implementation_text`** (Function) — 


- **`normalize_identifier_words`** (Function) — 


- **`load_history_entries`** (Function) — 


- **`resolve_cache_dir`** (Function) — 


- **`write_json_file`** (Function) — 


- **`clamp_similarity`** (Function) — 


- **`tfidf_similarity`** (Function) — 


- **`find_substring`** (Function) — 


- **`adaptive_match_threshold`** (Function) — 


- **`build_trace_edges`** (Function) — 


- **`best_edge_for_requirement`** (Function) — 


- **`candidate_edges_for_requirement`** (Function) — 


- **`implementation_by_id`** (Function) — 


- **`matched_implementations_for_requirement`** (Function) — 


- **`aggregate_requirement_evidence_text`** (Function) — 


- **`missing_literal_count`** (Function) — 


- **`missing_pair_count`** (Function) — 


- **`preferred_requirement_match`** (Function) — 


- **`suggestion_dedupe_key`** (Function) — 


- **`file_hash_changed`** (Function) — 


- **`diff_item_for_requirement`** (Function) — 


- **`implementation_group_keys`** (Function) — 


- **`build_diff_items`** (Function) — 


- **`build_summary`** (Function) — 


- **`build_diff_report`** (Function) — 


- **`build_trace_report`** (Function) — 


- **`single_numeric`** (Function) — 


- **`filter_snapshot_for_incremental`** (Function) — 


- **`replace_first`** (Function) — 


- **`resolve_input_path`** (Function) — 


- **`should_fail`** (Function) — 


- **`build_suggest_report`** (Function) — 


- **`file_is_changed`** (Function) — 


- **`make_numeric_patch`** (Function) — 


- **`build_suggestions`** (Function) — 


- **`path_within_dir`** (Function) — 


- **`build_status_report`** (Function) — 


- **`git_changed_files`** (Function) — 
- **`current_commit_info`** (Function) — 
- **`git_repo_root`** (Function) — 
- **`SpecAlignConfig`** (Struct) — 
- **`current_epoch_seconds`** (Function) — 
- **`suggest_report_async`** (Function) — 
- **`trace_report_async`** (Function) — 
- **`diff_report_async`** (Function) — 
- **`watch_probe_async`** (Function) — 
- **`snapshot_for_config_async`** (Function) — 
- **`build_snapshot`** (Function) — 
- **`status_report_async`** (Function) —
