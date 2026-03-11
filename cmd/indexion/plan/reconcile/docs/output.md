## Output

The primary output is a `ReconcileReport`.

Rendered formats:

- `json`: full machine-readable report with config, summary, candidates, logical review queue, cache state, and used specs.
- `md`: compact review document for humans.
- `github-issue`: checklist-style issue body for manual follow-up.

Candidate statuses currently emitted are:

- `missing_doc`: no external document fragment matched a symbol, and no higher-level module documentation covered its source file.
- `stale_doc`: implementation appears newer than the mapped document fragment.
- `review_mapping`: only a weak heuristic match was found.
- `review_both`: documentation appears newer than the implementation or otherwise requires manual judgment.

Notable summary fields:

- `module_covered_symbols`: symbols that were not matched directly, but were suppressed from `missing_doc` because the surrounding module was covered by higher-level documentation.

Index state is persisted under the reconcile index directory:

- `manifest.json`: source fingerprint, review hash, and indexed record metadata.
- `report.json`: cached last report for cache hits.
- `records.db`: VCDB-backed candidate and logical review index.

`index.json` is treated as stale leftover output and is cleaned up during save.
