/**
 * @file VSCode-style search input component.
 *
 * Reusable search bar following VSCode's native search pattern:
 * ┌─────────────────────────────┐
 * │ 🔍  Search query...    × ↵ │
 * └─────────────────────────────┘
 *
 * Features:
 * - Input with placeholder
 * - Clear button (×) when query is non-empty
 * - Enter to submit
 * - Disabled state
 * - Optional result count display
 */

import React, { useCallback, useRef } from "react";

export type SearchInputProps = {
  readonly value: string;
  readonly onChange: (value: string) => void;
  readonly onSubmit: (value: string) => void;
  readonly onClear?: () => void;
  readonly placeholder?: string;
  readonly disabled?: boolean;
  readonly resultCount?: number | null;
  readonly loading?: boolean;
};

export const SearchInput = ({
  value,
  onChange,
  onSubmit,
  onClear,
  placeholder = "Search...",
  disabled = false,
  resultCount,
  loading = false,
}: SearchInputProps): React.JSX.Element => {
  const inputRef = useRef<HTMLInputElement>(null);

  const handleSubmit = useCallback(
    (e: React.FormEvent) => {
      e.preventDefault();
      const trimmed = value.trim();
      if (trimmed) {
        onSubmit(trimmed);
      }
    },
    [value, onSubmit],
  );

  const handleClear = useCallback(() => {
    onChange("");
    onClear?.();
    inputRef.current?.focus();
  }, [onChange, onClear]);

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (e.key === "Escape") {
        handleClear();
      }
    },
    [handleClear],
  );

  return (
    <div style={styles.container}>
      <form onSubmit={handleSubmit} style={styles.form}>
        <div style={styles.inputWrapper}>
          <span style={styles.icon}>⌕</span>
          <input
            ref={inputRef}
            type="text"
            value={value}
            onChange={(e) => onChange(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder={placeholder}
            disabled={disabled}
            style={styles.input}
          />
          {value && (
            <button type="button" onClick={handleClear} style={styles.clearBtn} aria-label="Clear search">
              ×
            </button>
          )}
        </div>
      </form>
      {loading && <div style={styles.status}>Searching...</div>}
      {resultCount !== undefined && resultCount !== null && !loading && (
        <div style={styles.status}>{resultCount} results</div>
      )}
    </div>
  );
};

const styles: Record<string, React.CSSProperties> = {
  container: {
    borderBottom: "1px solid var(--vscode-panel-border, #333)",
  },
  form: {
    padding: "6px",
  },
  inputWrapper: {
    display: "flex",
    alignItems: "center",
    background: "var(--vscode-input-background, #3c3c3c)",
    border: "1px solid var(--vscode-input-border, #555)",
    borderRadius: "2px",
    overflow: "hidden",
  },
  icon: {
    padding: "0 4px 0 6px",
    color: "var(--vscode-descriptionForeground, #888)",
    fontSize: "13px",
    flexShrink: 0,
    userSelect: "none" as const,
  },
  input: {
    flex: 1,
    padding: "4px 2px",
    background: "transparent",
    color: "var(--vscode-input-foreground, #ccc)",
    border: "none",
    fontSize: "12px",
    outline: "none",
    fontFamily: "inherit",
    minWidth: 0,
  },
  clearBtn: {
    background: "none",
    border: "none",
    color: "var(--vscode-descriptionForeground, #888)",
    cursor: "pointer",
    fontSize: "14px",
    padding: "0 6px",
    lineHeight: 1,
    flexShrink: 0,
  },
  status: {
    padding: "2px 6px 4px",
    fontSize: "11px",
    color: "var(--vscode-descriptionForeground, #888)",
  },
};
