/**
 * @file Unified search sidebar — supports search, explore, grep, and digest modes.
 *
 * Layout:
 *   [search icon] [input field] [mode toggle icons]
 *   [progress bar when searching]
 *   [explore controls when explore mode]
 *   [result summary + clear]
 *   [result tree]
 *
 * Mode toggles work like VSCode's search options (case, word, regex) —
 * icon buttons that toggle active state.
 */

import React, { useCallback } from "react";
import type { ComparisonStrategy } from "@indexion/api-client";
import type {
  SearchToWebview,
  SearchFromWebview,
  SearchResultItem,
  ExplorePairItem,
  SearchMode,
} from "../../views/search/messages.ts";
import { usePostMessage, useWebviewReducer } from "../bridge/context.tsx";
import { StatusMsg } from "../components/status-msg.tsx";
import layout from "../components/sidebar-layout.module.css";
import styles from "./app.module.css";

const STRATEGIES: ReadonlyArray<ComparisonStrategy> = ["tfidf", "hybrid", "apted", "tsed", "ncd"];

const basename = (path: string): string => {
  const i = path.lastIndexOf("/");
  return i >= 0 ? path.slice(i + 1) : path;
};

const dirname = (path: string): string => {
  const i = path.lastIndexOf("/");
  return i >= 0 ? path.slice(0, i) : "";
};

// ─── State & reducer ────────────────────────────────────

type SearchState = {
  readonly mode: SearchMode;
  readonly query: string;
  readonly results: ReadonlyArray<SearchResultItem>;
  readonly explorePairs: ReadonlyArray<ExplorePairItem>;
  readonly exploreFileCount: number;
  readonly searched: boolean;
  readonly searching: boolean;
  readonly progressDetail: string | null;
  readonly error: string | null;
  readonly serverReady: boolean;
  readonly threshold: number;
  readonly strategy: ComparisonStrategy;
  readonly targetDir: string;
};

const initialState: SearchState = {
  mode: "search",
  query: "",
  results: [],
  explorePairs: [],
  exploreFileCount: 0,
  searched: false,
  searching: false,
  progressDetail: null,
  error: null,
  serverReady: false,
  threshold: 0.7,
  strategy: "tfidf",
  targetDir: "",
};

type SearchAction =
  | SearchToWebview
  | { readonly type: "setMode"; readonly value: SearchMode }
  | { readonly type: "setQuery"; readonly value: string }
  | { readonly type: "setThreshold"; readonly value: number }
  | { readonly type: "setStrategy"; readonly value: ComparisonStrategy }
  | { readonly type: "clearSearch" };

const searchReducer = (state: SearchState, action: SearchAction): SearchState => {
  switch (action.type) {
    case "results":
      return {
        ...state,
        results: action.items,
        explorePairs: [],
        searching: false,
        searched: true,
        progressDetail: null,
        error: null,
      };
    case "appendItems":
      return { ...state, results: [...state.results, ...action.items], searched: true };
    case "exploreResults":
      return {
        ...state,
        explorePairs: action.pairs,
        exploreFileCount: action.fileCount,
        results: [],
        searching: false,
        searched: true,
        progressDetail: null,
        error: null,
      };
    case "searching":
      return {
        ...state,
        searching: true,
        error: null,
        progressDetail: null,
        results: [],
        explorePairs: [],
        searched: false,
      };
    case "progress":
      return { ...state, progressDetail: action.detail };
    case "done":
      return { ...state, searching: false, progressDetail: null };
    case "error":
      return { ...state, error: action.message, searching: false, searched: true, progressDetail: null };
    case "serverStatus":
      return { ...state, serverReady: action.ready };
    case "directoryPicked":
      return { ...state, targetDir: action.path };
    case "config":
      return { ...state, threshold: action.threshold, strategy: action.strategy };
    case "setMode":
      return {
        ...state,
        mode: action.value,
        results: [],
        explorePairs: [],
        searched: false,
        searching: false,
        error: null,
        progressDetail: null,
      };
    case "setQuery":
      return { ...state, query: action.value };
    case "setThreshold":
      return { ...state, threshold: action.value };
    case "setStrategy":
      return { ...state, strategy: action.value };
    case "clearSearch":
      return {
        ...state,
        query: "",
        results: [],
        explorePairs: [],
        searched: false,
        error: null,
        progressDetail: null,
      };
    default:
      return state;
  }
};

// ─── Mode definitions ───────────────────────────────────

type ModeInfo = {
  readonly id: SearchMode;
  readonly icon: string;
  readonly title: string;
  readonly placeholder: string;
};

const MODES: ReadonlyArray<ModeInfo> = [
  { id: "search", icon: "search", title: "Semantic Search", placeholder: "Search code, wiki, docs..." },
  { id: "explore", icon: "files", title: "Explore Similar Code", placeholder: "" },
  { id: "grep", icon: "regex", title: "KGF Token Grep", placeholder: "Token pattern (e.g. pub fn Ident)..." },
  { id: "digest", icon: "symbol-method", title: "Search by Purpose", placeholder: "Describe function purpose..." },
];

const findMode = (id: SearchMode): ModeInfo => MODES.find((m) => m.id === id) ?? MODES[0];

const RESULT_SUMMARY: Record<SearchMode, (n: number, f: number) => string> = {
  explore: (n, f) => `${n} pairs in ${f} files`,
  search: (n, f) => `${n} results in ${f} files`,
  grep: (n, f) => `${n} results in ${f} files`,
  digest: (n, f) => `${n} results in ${f} files`,
};

// ─── Component ──────────────────────────────────────────

export const SearchApp = (): React.JSX.Element => {
  const postMessage = usePostMessage<SearchFromWebview>();
  const [state, dispatch] = useWebviewReducer(searchReducer, initialState);
  const {
    mode,
    query,
    results,
    explorePairs,
    exploreFileCount,
    searched,
    searching,
    progressDetail,
    error,
    serverReady,
    threshold,
    strategy,
    targetDir,
  } = state;

  const currentMode = findMode(mode);

  const handleSubmit = useCallback(() => {
    if (mode === "explore") {
      if (!targetDir) {
        return;
      }
      postMessage({ type: "explore", threshold, strategy, targetDir });
      return;
    }
    const trimmed = query.trim();
    if (!trimmed) {
      return;
    }
    switch (mode) {
      case "search":
        postMessage({ type: "search", query: trimmed });
        break;
      case "grep":
        postMessage({ type: "grep", pattern: trimmed });
        break;
      case "digest":
        postMessage({ type: "digest", query: trimmed });
        break;
    }
  }, [mode, query, postMessage, threshold, strategy, targetDir]);

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (e.key === "Enter") {
        handleSubmit();
      }
      if (e.key === "Escape") {
        dispatch({ type: "clearSearch" });
      }
    },
    [handleSubmit, dispatch],
  );

  const handleInput = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      dispatch({ type: "setQuery", value: e.target.value });
    },
    [dispatch],
  );

  const handleResultClick = useCallback(
    (item: SearchResultItem) => {
      if (item.filePath) {
        postMessage({ type: "openFile", filePath: item.filePath, line: item.line });
      }
    },
    [postMessage],
  );

  const handleOpenDiff = useCallback(
    (pair: ExplorePairItem) => {
      postMessage({ type: "openDiff", file1: pair.file1, file2: pair.file2 });
    },
    [postMessage],
  );

  const handlePickDir = useCallback(() => {
    postMessage({ type: "pickDirectory" });
  }, [postMessage]);

  const toggleMode = useCallback(
    (id: SearchMode) => {
      dispatch({ type: "setMode", value: id });
    },
    [dispatch],
  );

  const hasResults = results.length > 0 || explorePairs.length > 0;
  const resultCount = mode === "explore" ? explorePairs.length : results.length;

  // Group results by file for tree display
  const fileGroups = React.useMemo(() => {
    if (results.length === 0) {
      return [];
    }
    const groups: Array<{ file: string; items: ReadonlyArray<SearchResultItem> }> = [];
    const map = new Map<string, Array<SearchResultItem>>();
    const order: Array<string> = [];
    for (const item of results) {
      const key = item.filePath ?? "";
      const existing = map.get(key);
      if (existing) {
        existing.push(item);
      } else {
        const arr: Array<SearchResultItem> = [item];
        map.set(key, arr);
        order.push(key);
      }
    }
    for (const key of order) {
      groups.push({ file: key, items: map.get(key)! });
    }
    return groups;
  }, [results]);

  const fileCount = fileGroups.length;

  return (
    <div className={layout.sidebarRoot}>
      {/* ── Search input composite (icon + input + toggle buttons in one border) ── */}
      <div className={styles.searchBox}>
        <span className={styles.searchBoxIcon}>
          <vscode-icon name="search" size={16} />
        </span>
        {mode !== "explore" && (
          <input
            type="text"
            className={styles.searchInput}
            placeholder={currentMode.placeholder}
            value={query}
            disabled={!serverReady}
            onChange={handleInput}
            onKeyDown={handleKeyDown}
          />
        )}
        {mode === "explore" && (
          <input
            type="text"
            className={styles.searchInput}
            placeholder="Select directory..."
            value={targetDir}
            readOnly
          />
        )}
        <div className={styles.modeToggles}>
          {MODES.map((m) => (
            <button
              key={m.id}
              type="button"
              title={m.title}
              className={`${styles.modeToggle} ${mode === m.id ? styles.modeToggleActive : ""}`}
              onClick={() => toggleMode(m.id)}
            >
              <vscode-icon name={m.icon} size={14} />
            </button>
          ))}
        </div>
      </div>

      {/* ── Progress indicator ── */}
      {searching && <vscode-progress-bar indeterminate className={styles.progressBar} />}
      {searching && progressDetail && <div className={styles.progressDetail}>{progressDetail}</div>}

      {/* ── Explore controls (below search row) ── */}
      {mode === "explore" && (
        <div className={layout.sidebarControls}>
          <ExploreControls
            threshold={threshold}
            strategy={strategy}
            targetDir={targetDir}
            searching={searching}
            serverReady={serverReady}
            onRun={handleSubmit}
            onPickDir={handlePickDir}
            onSetThreshold={(v) => dispatch({ type: "setThreshold", value: v })}
            onSetStrategy={(v) => dispatch({ type: "setStrategy", value: v })}
          />
        </div>
      )}

      {/* ── Status messages ── */}
      {!serverReady && !searching && <StatusMsg>Waiting for indexion server...</StatusMsg>}
      {error && <StatusMsg error>{error}</StatusMsg>}
      {searched && !searching && !error && !hasResults && <StatusMsg>No results found.</StatusMsg>}

      {/* ── Result summary ── */}
      {hasResults && (
        <div className={layout.resultSummarySpaced}>
          <span>{RESULT_SUMMARY[mode](resultCount, mode === "explore" ? exploreFileCount : fileCount)}</span>
          <button type="button" className={layout.textLinkButton} onClick={() => dispatch({ type: "clearSearch" })}>
            Clear
          </button>
        </div>
      )}

      {/* ── Results: grouped by file ── */}
      {fileGroups.length > 0 && (
        <vscode-tree className={layout.scrollableTree}>
          {fileGroups.map((group) => (
            <vscode-tree-item
              key={group.file}
              open
              onClick={() => postMessage({ type: "openFile", filePath: group.file })}
            >
              <vscode-icon slot="icon-branch" name="file" />
              <vscode-icon slot="icon-leaf" name="file" />
              {basename(group.file)}
              <span slot="description">{dirname(group.file)}</span>
              <vscode-badge slot="decoration">{group.items.length}</vscode-badge>
              {group.items.map((item, j) => (
                <vscode-tree-item
                  key={j}
                  onClick={(e: React.MouseEvent) => {
                    e.stopPropagation();
                    handleResultClick(item);
                  }}
                >
                  <vscode-icon slot="icon-leaf" name="symbol-method" />
                  {item.label}
                  {item.score !== undefined && (
                    <vscode-badge slot="decoration">{Math.round(item.score * 100)}%</vscode-badge>
                  )}
                </vscode-tree-item>
              ))}
            </vscode-tree-item>
          ))}
        </vscode-tree>
      )}

      {/* ── Results: explore pairs ── */}
      {explorePairs.length > 0 && (
        <vscode-tree className={layout.scrollableTree}>
          {explorePairs.map((pair, i) => (
            <vscode-tree-item key={i} onClick={() => handleOpenDiff(pair)}>
              <vscode-icon slot="icon-leaf" name="diff" />
              {pair.label}
              <vscode-badge slot="decoration">{Math.round(pair.similarity * 100)}%</vscode-badge>
              <span slot="description">{pair.file1}</span>
            </vscode-tree-item>
          ))}
        </vscode-tree>
      )}
    </div>
  );
};

// ─── Explore Controls sub-component ─────────────────────

type ExploreControlsProps = {
  readonly threshold: number;
  readonly strategy: ComparisonStrategy;
  readonly targetDir: string;
  readonly searching: boolean;
  readonly serverReady: boolean;
  readonly onRun: () => void;
  readonly onPickDir: () => void;
  readonly onSetThreshold: (v: number) => void;
  readonly onSetStrategy: (v: ComparisonStrategy) => void;
};

const ExploreControls = ({
  threshold,
  strategy,
  targetDir,
  searching,
  serverReady,
  onRun,
  onPickDir,
  onSetThreshold,
  onSetStrategy,
}: ExploreControlsProps): React.JSX.Element => (
  <>
    <div className={layout.toolbarRow}>
      <vscode-button onClick={onPickDir}>Browse...</vscode-button>
    </div>

    <div className={layout.toolbarRowCenter}>
      <vscode-label className={styles.thresholdLabel}>Threshold: {Math.round(threshold * 100)}%</vscode-label>
      <input
        type="range"
        min={0}
        max={100}
        value={Math.round(threshold * 100)}
        onChange={(e) => onSetThreshold(Number(e.target.value) / 100)}
        className={styles.thresholdSlider}
      />
    </div>

    <vscode-single-select
      value={strategy}
      onChange={(e: React.FormEvent) => onSetStrategy((e.target as HTMLSelectElement).value as ComparisonStrategy)}
    >
      {STRATEGIES.map((s) => (
        <vscode-option key={s} value={s}>
          {s}
        </vscode-option>
      ))}
    </vscode-single-select>

    <vscode-button onClick={onRun} disabled={!serverReady || !targetDir || searching || undefined}>
      {searching ? "Analyzing..." : "Run Explore"}
    </vscode-button>
  </>
);
