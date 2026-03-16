# tree_extract

File-to-tree conversion for structural comparison.

## Overview

Converts source files to `TreeNode` representations for APTED/TSED comparison.
Uses KGF to detect language, tokenize, and extract function-level ASTs.
Falls back to simple whitespace tokenization when KGF is unavailable.

## API

- `extract(display_name, content, registry)` — Extract tree representations from a source file
