/**
 * @file Search sidebar React component.
 *
 * Provides a search input with mode toggle (Code / Wiki) and
 * a scrollable results list. Communicates with the extension host
 * via the VSCode webview message API.
 */

import React, { useCallback, useState } from "react";
import type { SearchToWebview, SearchFromWebview, SearchResultItem, SearchMode } from "../../views/search/messages.ts";
import { usePostMessage, useWebviewMessage } from "../bridge/context.tsx";
import { SearchInput } from "../components/search-input.tsx";

export const SearchApp = (): React.JSX.Element => {
  const postMessage = usePostMessage<SearchFromWebview>();
  const [query, setQuery] = useState("");
  const [mode, setMode] = useState<SearchMode>("code");
  const [results, setResults] = useState<ReadonlyArray<SearchResultItem>>([]);
  const [searching, setSearching] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [serverReady, setServerReady] = useState(false);

  useWebviewMessage<SearchToWebview>((message) => {
    if (message.type === "results") {
      setResults(message.items);
      setSearching(false);
      setError(null);
    }
    if (message.type === "searching") {
      setSearching(true);
      setError(null);
    }
    if (message.type === "error") {
      setError(message.message);
      setSearching(false);
    }
    if (message.type === "serverStatus") {
      setServerReady(message.ready);
    }
  });

  const handleResultClick = useCallback(
    (item: SearchResultItem) => {
      if (item.filePath) {
        postMessage({ type: "openFile", filePath: item.filePath, line: item.line });
      }
    },
    [postMessage],
  );

  return (
    <div style={styles.container}>
      <div style={styles.modeToggle}>
        <button
          type="button"
          onClick={() => setMode("code")}
          style={mode === "code" ? styles.modeActive : styles.modeButton}
        >
          Code
        </button>
        <button
          type="button"
          onClick={() => setMode("wiki")}
          style={mode === "wiki" ? styles.modeActive : styles.modeButton}
        >
          Wiki
        </button>
      </div>

      <SearchInput
        value={query}
        onChange={setQuery}
        onSubmit={(q) => postMessage({ type: "search", mode, query: q })}
        onClear={() => setResults([])}
        placeholder={mode === "code" ? "Search by purpose..." : "Search wiki..."}
        disabled={!serverReady}
        loading={searching}
        resultCount={results.length > 0 ? results.length : null}
      />

      {!serverReady && !searching && <div style={styles.status}>Server not ready...</div>}
      {error && <div style={styles.error}>{error}</div>}

      <div style={styles.results}>
        {results.map((item, i) => (
          <button
            key={i}
            type="button"
            style={styles.resultItem}
            onClick={() => handleResultClick(item)}
            disabled={!item.filePath}
          >
            <div style={styles.resultLabel}>
              {item.score !== undefined && <span style={styles.score}>{Math.round(item.score * 100)}%</span>}
              {item.label}
            </div>
            <div style={styles.resultDescription}>{item.description}</div>
            {item.detail && <div style={styles.resultDetail}>{item.detail}</div>}
          </button>
        ))}
      </div>
    </div>
  );
};

const styles: Record<string, React.CSSProperties> = {
  container: {
    display: "flex",
    flexDirection: "column",
    height: "100%",
    fontFamily: "var(--vscode-font-family)",
    color: "var(--vscode-foreground)",
    fontSize: "13px",
  },
  modeToggle: {
    display: "flex",
    gap: "1px",
    borderRadius: "3px",
    overflow: "hidden",
    margin: "6px 6px 0",
  },
  modeButton: {
    flex: 1,
    padding: "4px 8px",
    border: "none",
    background: "var(--vscode-button-secondaryBackground, #3a3d41)",
    color: "var(--vscode-button-secondaryForeground, #ccc)",
    cursor: "pointer",
    fontSize: "12px",
  },
  modeActive: {
    flex: 1,
    padding: "4px 8px",
    border: "none",
    background: "var(--vscode-button-background, #007acc)",
    color: "var(--vscode-button-foreground, #fff)",
    cursor: "pointer",
    fontSize: "12px",
  },
  status: {
    padding: "12px 8px",
    textAlign: "center" as const,
    color: "var(--vscode-descriptionForeground, #888)",
    fontSize: "12px",
  },
  error: {
    padding: "8px",
    color: "var(--vscode-errorForeground, #f44)",
    fontSize: "12px",
  },
  results: {
    flex: 1,
    overflow: "auto",
  },
  resultItem: {
    display: "block",
    width: "100%",
    textAlign: "left" as const,
    padding: "6px 8px",
    border: "none",
    borderBottom: "1px solid var(--vscode-panel-border, #222)",
    background: "transparent",
    color: "inherit",
    cursor: "pointer",
    fontFamily: "inherit",
    fontSize: "inherit",
  },
  resultLabel: {
    fontWeight: 500,
    color: "var(--vscode-foreground)",
    display: "flex",
    alignItems: "center",
    gap: "6px",
  },
  score: {
    fontSize: "11px",
    padding: "1px 4px",
    borderRadius: "2px",
    background: "var(--vscode-badge-background, #4d4d4d)",
    color: "var(--vscode-badge-foreground, #fff)",
    flexShrink: 0,
  },
  resultDescription: {
    fontSize: "11px",
    color: "var(--vscode-descriptionForeground, #888)",
    overflow: "hidden",
    textOverflow: "ellipsis",
    whiteSpace: "nowrap" as const,
    marginTop: "2px",
  },
  resultDetail: {
    fontSize: "11px",
    color: "var(--vscode-descriptionForeground, #888)",
    marginTop: "2px",
    display: "-webkit-box",
    WebkitLineClamp: 2,
    WebkitBoxOrient: "vertical" as const,
    overflow: "hidden",
  },
};
