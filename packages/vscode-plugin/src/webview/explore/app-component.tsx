/**
 * @file Explore sidebar React component.
 *
 * Provides threshold slider, strategy selector, directory picker,
 * and results list with diff-open support.
 */

import React, { useCallback, useState } from "react";
import type { SimilarityPair, ComparisonStrategy } from "@indexion/api-client";
import type { ExploreToWebview, ExploreFromWebview } from "../../views/explore/messages.ts";
import { usePostMessage, useWebviewMessage } from "../bridge/context.tsx";

const STRATEGIES: ReadonlyArray<ComparisonStrategy> = ["tfidf", "hybrid", "apted", "tsed", "ncd"];

export const ExploreApp = (): React.JSX.Element => {
  const postMessage = usePostMessage<ExploreFromWebview>();
  const [threshold, setThreshold] = useState(0.7);
  const [strategy, setStrategy] = useState<ComparisonStrategy>("tfidf");
  const [targetDir, setTargetDir] = useState("");
  const [pairs, setPairs] = useState<ReadonlyArray<SimilarityPair>>([]);
  const [fileCount, setFileCount] = useState(0);
  const [searching, setSearching] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [serverReady, setServerReady] = useState(false);

  useWebviewMessage<ExploreToWebview>((message) => {
    if (message.type === "results") {
      setPairs(message.pairs);
      setFileCount(message.fileCount);
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
    if (message.type === "directoryPicked") {
      setTargetDir(message.path);
    }
    if (message.type === "serverStatus") {
      setServerReady(message.ready);
    }
    if (message.type === "config") {
      setThreshold(message.threshold);
      setStrategy(message.strategy);
    }
  });

  const handleRun = useCallback(() => {
    if (!targetDir) {
      return;
    }
    postMessage({ type: "run", threshold, strategy, targetDir });
  }, [postMessage, threshold, strategy, targetDir]);

  const handleOpenDiff = useCallback(
    (pair: SimilarityPair) => {
      postMessage({ type: "openDiff", file1: pair.file1, file2: pair.file2 });
    },
    [postMessage],
  );

  const handlePickDir = useCallback(() => {
    postMessage({ type: "pickDirectory" });
  }, [postMessage]);

  const basename = (path: string): string => {
    const parts = path.split("/");
    return parts[parts.length - 1] ?? path;
  };

  return (
    <div style={styles.container}>
      <div style={styles.controls}>
        <div style={styles.field}>
          <label style={styles.label}>Directory</label>
          <div style={styles.dirRow}>
            <input
              type="text"
              value={targetDir}
              onChange={(e) => setTargetDir(e.target.value)}
              style={styles.dirInput}
              placeholder="Select directory..."
              readOnly
            />
            <button type="button" onClick={handlePickDir} style={styles.smallButton}>
              ...
            </button>
          </div>
        </div>

        <div style={styles.field}>
          <label style={styles.label}>Threshold: {Math.round(threshold * 100)}%</label>
          <input
            type="range"
            min={0}
            max={100}
            value={Math.round(threshold * 100)}
            onChange={(e) => setThreshold(Number(e.target.value) / 100)}
            style={styles.slider}
          />
        </div>

        <div style={styles.field}>
          <label style={styles.label}>Strategy</label>
          <select
            value={strategy}
            onChange={(e) => setStrategy(e.target.value as ComparisonStrategy)}
            style={styles.select}
          >
            {STRATEGIES.map((s) => (
              <option key={s} value={s}>
                {s}
              </option>
            ))}
          </select>
        </div>

        <button
          type="button"
          onClick={handleRun}
          disabled={!serverReady || !targetDir || searching}
          style={styles.runButton}
        >
          {searching ? "Analyzing..." : "Run Explore"}
        </button>
      </div>

      {!serverReady && <div style={styles.status}>Server not ready...</div>}
      {error && <div style={styles.error}>{error}</div>}

      {pairs.length > 0 && (
        <div style={styles.resultCount}>
          {pairs.length} pairs in {fileCount} files
        </div>
      )}

      <div style={styles.results}>
        {pairs.map((pair, i) => (
          <button key={i} type="button" style={styles.resultItem} onClick={() => handleOpenDiff(pair)}>
            <div style={styles.resultHeader}>
              <span style={styles.score}>{Math.round(pair.similarity * 100)}%</span>
              <span style={styles.fileName}>{basename(pair.file1)}</span>
              <span style={styles.arrow}>&harr;</span>
              <span style={styles.fileName}>{basename(pair.file2)}</span>
            </div>
            <div style={styles.resultPaths}>{pair.file1}</div>
            <div style={styles.resultPaths}>{pair.file2}</div>
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
  controls: {
    padding: "8px",
    borderBottom: "1px solid var(--vscode-panel-border, #333)",
    display: "flex",
    flexDirection: "column",
    gap: "6px",
  },
  field: {
    display: "flex",
    flexDirection: "column",
    gap: "2px",
  },
  label: {
    fontSize: "11px",
    color: "var(--vscode-descriptionForeground, #888)",
    textTransform: "uppercase" as const,
    letterSpacing: "0.3px",
  },
  dirRow: {
    display: "flex",
    gap: "4px",
  },
  dirInput: {
    flex: 1,
    padding: "3px 6px",
    background: "var(--vscode-input-background, #3c3c3c)",
    color: "var(--vscode-input-foreground, #ccc)",
    border: "1px solid var(--vscode-input-border, #555)",
    borderRadius: "2px",
    fontSize: "12px",
    fontFamily: "var(--vscode-editor-font-family)",
  },
  smallButton: {
    padding: "3px 8px",
    background: "var(--vscode-button-secondaryBackground, #3a3d41)",
    color: "var(--vscode-button-secondaryForeground, #ccc)",
    border: "none",
    borderRadius: "2px",
    cursor: "pointer",
    fontSize: "12px",
  },
  slider: {
    width: "100%",
    accentColor: "var(--vscode-button-background, #007acc)",
  },
  select: {
    padding: "3px 6px",
    background: "var(--vscode-dropdown-background, #3c3c3c)",
    color: "var(--vscode-dropdown-foreground, #ccc)",
    border: "1px solid var(--vscode-dropdown-border, #555)",
    borderRadius: "2px",
    fontSize: "12px",
  },
  runButton: {
    padding: "6px 12px",
    background: "var(--vscode-button-background, #007acc)",
    color: "var(--vscode-button-foreground, #fff)",
    border: "none",
    borderRadius: "2px",
    cursor: "pointer",
    fontSize: "13px",
    fontWeight: 500,
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
  resultCount: {
    padding: "4px 8px",
    fontSize: "11px",
    color: "var(--vscode-descriptionForeground, #888)",
    borderBottom: "1px solid var(--vscode-panel-border, #333)",
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
  resultHeader: {
    display: "flex",
    alignItems: "center",
    gap: "4px",
    flexWrap: "wrap" as const,
  },
  score: {
    fontSize: "11px",
    padding: "1px 4px",
    borderRadius: "2px",
    background: "var(--vscode-badge-background, #4d4d4d)",
    color: "var(--vscode-badge-foreground, #fff)",
    flexShrink: 0,
  },
  fileName: {
    fontWeight: 500,
  },
  arrow: {
    color: "var(--vscode-descriptionForeground, #888)",
    fontSize: "11px",
  },
  resultPaths: {
    fontSize: "11px",
    color: "var(--vscode-descriptionForeground, #888)",
    overflow: "hidden",
    textOverflow: "ellipsis",
    whiteSpace: "nowrap" as const,
  },
};
