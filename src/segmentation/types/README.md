# types

## API

- **`SegmentPoint`** (Struct) — A lightweight segment point without text content.
- **`SegmentationStrategy`** (Trait) — Common interface for segmentation strategies.
- **`WindowDivergence`** (Struct) — Result of window divergence calculation.
- **`to_text_segment`** (Function) — Convert a SegmentPoint to a TextSegment by extracting text from the original.
- **`extract_substring`** (Function) — Extract substring from text given character offsets.
- **`segment_points_to_text_segments`** (Function) — Convert an array of SegmentPoints to TextSegments.
- **`with_heading`** (Function) — Create a new TextSegment with heading text.
- **`TextSegment`** (Struct) — Full segment with extracted text content.
- **`SegmentType`** (Enum) — Classification of segment content.
- **`get_heading_text`** (Function) — Get the heading text if present.
- **`length`** (Function) — Get the length of the segment.
- **`get_positions`** (Function) — Get the window end positions.
- **`new`** (Function) — Create a new SegmentPoint.
- **`get_values`** (Function) — Get the divergence values.
- **`get_start`** (Function) — Get the start position.

And 12 more symbols.
