/**
 * @file Search input composite — shared between Search panel and Wiki filter.
 *
 * Renders an input framed with a leading icon and an optional toggle group
 * on the right. Optionally renders a clear (✕) button when the query is
 * non-empty, so the filter mental model stays consistent across panels.
 */

import React, { useCallback } from "react";
import styles from "./search-box.module.css";

export type SearchBoxToggle<TId extends string> = {
  readonly id: TId;
  readonly icon: string;
  readonly title: string;
  readonly active: boolean;
};

type SearchBoxProps<TId extends string> = {
  readonly value: string;
  readonly onChange: (value: string) => void;
  readonly onSubmit?: () => void;
  readonly onCancel?: () => void;
  readonly placeholder: string;
  readonly disabled?: boolean;
  readonly leadingIcon?: string;
  readonly toggles?: ReadonlyArray<SearchBoxToggle<TId>>;
  readonly onToggle?: (id: TId) => void;
  /** Show a clear (✕) button inside the box when query is non-empty. */
  readonly clearable?: boolean;
  readonly autoFocus?: boolean;
};

export const SearchBox = <TId extends string>({
  value,
  onChange,
  onSubmit,
  onCancel,
  placeholder,
  disabled,
  leadingIcon = "search",
  toggles,
  onToggle,
  clearable = false,
  autoFocus = false,
}: SearchBoxProps<TId>): React.JSX.Element => {
  const handleInput = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      onChange(e.target.value);
    },
    [onChange],
  );

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent<HTMLInputElement>) => {
      if (e.key === "Enter" && onSubmit) {
        onSubmit();
      } else if (e.key === "Escape" && onCancel) {
        onCancel();
      }
    },
    [onSubmit, onCancel],
  );

  const showClear = clearable && value.length > 0;

  return (
    <div className={styles.searchBox}>
      <span className={styles.searchBoxIcon}>
        <vscode-icon name={leadingIcon} size={16} />
      </span>
      <input
        type="text"
        className={styles.searchInput}
        placeholder={placeholder}
        value={value}
        disabled={disabled}
        autoFocus={autoFocus}
        onChange={handleInput}
        onKeyDown={handleKeyDown}
      />
      {showClear && (
        <button type="button" className={styles.clearButton} title="Clear" onClick={() => onChange("")}>
          <vscode-icon name="close" size={14} />
        </button>
      )}
      {toggles && toggles.length > 0 && (
        <div className={styles.modeToggles}>
          {toggles.map((t) => (
            <button
              key={t.id}
              type="button"
              title={t.title}
              className={`${styles.modeToggle} ${t.active ? styles.modeToggleActive : ""}`}
              onClick={() => onToggle?.(t.id)}
            >
              <vscode-icon name={t.icon} size={14} />
            </button>
          ))}
        </div>
      )}
    </div>
  );
};
