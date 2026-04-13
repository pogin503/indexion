/**
 * @file Explore sidebar — uses @vscode-elements/elements.
 *
 * Threshold slider, strategy selector, directory picker,
 * and results displayed in <vscode-tree>.
 */

import React, { useCallback } from "react";
import type { SimilarityPair, ComparisonStrategy } from "@indexion/api-client";
import type { ExploreToWebview, ExploreFromWebview } from "../../views/explore/messages.ts";
import { usePostMessage, useWebviewReducer } from "../bridge/context.tsx";
import { StatusMsg } from "../components/status-msg.tsx";
import layout from "../components/sidebar-layout.module.css";
import styles from "./app.module.css";

const STRATEGIES: ReadonlyArray<ComparisonStrategy> = ["tfidf", "hybrid", "apted", "tsed", "ncd"];

// ─── State & reducer ────────────────────────────────────

type ExploreState = {
  readonly threshold: number;
  readonly strategy: ComparisonStrategy;
  readonly targetDir: string;
  readonly pairs: ReadonlyArray<SimilarityPair>;
  readonly fileCount: number;
  readonly searching: boolean;
  readonly error: string | null;
  readonly serverReady: boolean;
};

const initialState: ExploreState = {
  threshold: 0.7,
  strategy: "tfidf",
  targetDir: "",
  pairs: [],
  fileCount: 0,
  searching: false,
  error: null,
  serverReady: false,
};

type ExploreAction =
  | ExploreToWebview
  | { readonly type: "setThreshold"; readonly value: number }
  | { readonly type: "setStrategy"; readonly value: ComparisonStrategy };

const exploreReducer = (state: ExploreState, action: ExploreAction): ExploreState => {
  switch (action.type) {
    case "results":
      return { ...state, pairs: action.pairs, fileCount: action.fileCount, searching: false, error: null };
    case "searching":
      return { ...state, searching: true, error: null };
    case "error":
      return { ...state, error: action.message, searching: false };
    case "directoryPicked":
      return { ...state, targetDir: action.path };
    case "serverStatus":
      return { ...state, serverReady: action.ready };
    case "config":
      return { ...state, threshold: action.threshold, strategy: action.strategy };
    case "setThreshold":
      return { ...state, threshold: action.value };
    case "setStrategy":
      return { ...state, strategy: action.value };
    default:
      return state;
  }
};

// ─── Component ──────────────────────────────────────────

export const ExploreApp = (): React.JSX.Element => {
  const postMessage = usePostMessage<ExploreFromWebview>();
  const [state, dispatch] = useWebviewReducer(exploreReducer, initialState);
  const { threshold, strategy, targetDir, pairs, fileCount, searching, error, serverReady } = state;

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
    <div className={layout.sidebarRoot}>
      <div className={layout.sidebarControls}>
        <div className={layout.toolbarRow}>
          <vscode-textfield placeholder="Select directory..." value={targetDir} readonly className={styles.dirInput} />
          <vscode-button onClick={handlePickDir} className={styles.dirPickButton}>
            ...
          </vscode-button>
        </div>

        <div className={layout.toolbarRowCenter}>
          <vscode-label className={styles.thresholdLabel}>Threshold: {Math.round(threshold * 100)}%</vscode-label>
          <input
            type="range"
            min={0}
            max={100}
            value={Math.round(threshold * 100)}
            onChange={(e) => dispatch({ type: "setThreshold", value: Number(e.target.value) / 100 })}
            className={styles.thresholdSlider}
          />
        </div>

        <vscode-single-select
          value={strategy}
          onChange={(e: React.FormEvent) =>
            dispatch({ type: "setStrategy", value: (e.target as HTMLSelectElement).value as ComparisonStrategy })
          }
        >
          {STRATEGIES.map((s) => (
            <vscode-option key={s} value={s}>
              {s}
            </vscode-option>
          ))}
        </vscode-single-select>

        <vscode-button onClick={handleRun} disabled={!serverReady || !targetDir || searching || undefined}>
          {searching ? "Analyzing..." : "Run Explore"}
        </vscode-button>
      </div>

      {!serverReady && <StatusMsg>Server not ready</StatusMsg>}
      {error && <StatusMsg error>{error}</StatusMsg>}
      {pairs.length > 0 && (
        <div className={layout.resultSummary}>
          {pairs.length} pairs in {fileCount} files
        </div>
      )}

      {pairs.length > 0 && (
        <vscode-tree className={layout.scrollableTree}>
          {pairs.map((pair, i) => (
            <vscode-tree-item key={i} onClick={() => handleOpenDiff(pair)}>
              <vscode-icon slot="icon-leaf" name="diff" />
              {basename(pair.file1)} ↔ {basename(pair.file2)}
              <vscode-badge slot="decoration">{Math.round(pair.similarity * 100)}%</vscode-badge>
              <span slot="description">{pair.file1}</span>
            </vscode-tree-item>
          ))}
        </vscode-tree>
      )}
    </div>
  );
};
