/**
 * @file Wiki sidebar navigation — uses @vscode-elements/elements.
 *
 * <vscode-textfield> for search, <vscode-tree> for nav tree.
 * No custom styling — all appearance inherited from VSCode theme.
 */

import "@vscode-elements/elements/dist/vscode-textfield/index.js";
import "@vscode-elements/elements/dist/vscode-tree/index.js";
import "@vscode-elements/elements/dist/vscode-tree-item/index.js";
import "@vscode-elements/elements/dist/vscode-icon/index.js";
import React, { useCallback, useEffect, useRef, useState } from "react";
import type { WikiNavItem } from "@indexion/api-client";
import type { WikiToWebview, WikiFromWebview, WikiSearchHit } from "../../views/wiki/messages.ts";
import { usePostMessage, useWebviewMessage } from "../bridge/context.tsx";

// ─── Nav tree item (recursive) ──────────────────────────

const NavTreeItem = ({
  item,
  activePageId,
}: {
  readonly item: WikiNavItem;
  readonly activePageId: string | null;
}): React.JSX.Element => {
  const hasBranch = item.children.length > 0;
  return (
    <vscode-tree-item
      branch={hasBranch || undefined}
      open={hasBranch || undefined}
      active={item.id === activePageId || undefined}
      data-page-id={item.id}
    >
      <vscode-icon slot={hasBranch ? "icon-branch" : "icon-leaf"} name={hasBranch ? "folder" : "file"} />
      {item.title}
      {hasBranch &&
        item.children.map((child) => <NavTreeItem key={child.id} item={child} activePageId={activePageId} />)}
    </vscode-tree-item>
  );
};

// ─── Main component ─────────────────────────────────────

export const WikiPageApp = (): React.JSX.Element => {
  const postMessage = usePostMessage<WikiFromWebview>();
  const [nav, setNav] = useState<ReadonlyArray<WikiNavItem>>([]);
  const [activePageId, setActivePageId] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState("");
  const [searchResults, setSearchResults] = useState<ReadonlyArray<WikiSearchHit> | null>(null);
  const [navLoading, setNavLoading] = useState(true);
  const [searchLoading, setSearchLoading] = useState(false);
  const [serverReady, setServerReady] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const treeRef = useRef<HTMLElement>(null);

  useWebviewMessage<WikiToWebview>((msg) => {
    if (msg.type === "navLoaded") {
      setNav(msg.nav.pages);
      setNavLoading(false);
    }
    if (msg.type === "searchResults") {
      setSearchResults(msg.results);
      setSearchLoading(false);
    }
    if (msg.type === "loading") {
      if (msg.target === "nav") {
        setNavLoading(true);
      }
      if (msg.target === "search") {
        setSearchLoading(true);
      }
    }
    if (msg.type === "error") {
      setError(msg.message);
      if (msg.target === "nav") {
        setNavLoading(false);
      }
      if (msg.target === "search") {
        setSearchLoading(false);
      }
    }
    if (msg.type === "serverStatus") {
      setServerReady(msg.ready);
    }
  });

  const handleNavigate = useCallback(
    (pageId: string) => {
      setActivePageId(pageId);
      postMessage({ type: "navigate", pageId });
    },
    [postMessage],
  );

  // Listen for vsc-tree-select on the tree element via ref
  useEffect(() => {
    const el = treeRef.current;
    if (!el) {
      return;
    }
    const handler = (e: Event): void => {
      const detail = (e as CustomEvent).detail;
      const items = detail?.selectedItems as ReadonlyArray<HTMLElement> | undefined;
      if (!items || items.length === 0) {
        return;
      }
      const pageId = items[0]?.getAttribute("data-page-id");
      if (pageId) {
        handleNavigate(pageId);
      }
    };
    el.addEventListener("vsc-tree-select", handler);
    return () => el.removeEventListener("vsc-tree-select", handler);
  }, [handleNavigate]);

  const handleSearchKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (e.key === "Enter") {
        const trimmed = searchQuery.trim();
        if (trimmed) {
          postMessage({ type: "search", query: trimmed });
        }
      }
      if (e.key === "Escape") {
        setSearchQuery("");
        setSearchResults(null);
      }
    },
    [searchQuery, postMessage],
  );

  const handleSearchInput = useCallback((e: React.FormEvent) => {
    const val = (e.target as HTMLInputElement).value;
    setSearchQuery(val);
    if (!val) {
      setSearchResults(null);
    }
  }, []);

  const handleClearSearch = useCallback(() => {
    setSearchQuery("");
    setSearchResults(null);
  }, []);

  return (
    <div style={{ display: "flex", flexDirection: "column", height: "100%" }}>
      <vscode-textfield
        placeholder="Search"
        value={searchQuery}
        disabled={!serverReady || undefined}
        onInput={handleSearchInput}
        onKeyDown={handleSearchKeyDown}
        style={{ margin: 0 }}
      />

      {!serverReady && !searchLoading && <StatusMsg>Server not ready</StatusMsg>}
      {navLoading && serverReady && <StatusMsg>Loading...</StatusMsg>}
      {error && !navLoading && <StatusMsg error>{error}</StatusMsg>}

      {searchResults !== null && (
        <SearchResultsView
          results={searchResults}
          activePageId={activePageId}
          onNavigate={handleNavigate}
          onClear={handleClearSearch}
        />
      )}

      {searchResults === null && !navLoading && !error && nav.length === 0 && <StatusMsg>No wiki pages</StatusMsg>}

      {searchResults === null && !navLoading && !error && nav.length > 0 && (
        <vscode-tree ref={treeRef} style={{ flex: 1, overflow: "auto" }}>
          {nav.map((item) => (
            <NavTreeItem key={item.id} item={item} activePageId={activePageId} />
          ))}
        </vscode-tree>
      )}
    </div>
  );
};

// ─── Search results ─────────────────────────────────────

const SearchResultsView = ({
  results,
  activePageId,
  onNavigate,
  onClear,
}: {
  readonly results: ReadonlyArray<WikiSearchHit>;
  readonly activePageId: string | null;
  readonly onNavigate: (pageId: string) => void;
  readonly onClear: () => void;
}): React.JSX.Element => (
  <div style={{ flex: 1, overflow: "auto" }}>
    <div
      style={{
        display: "flex",
        justifyContent: "space-between",
        padding: "2px 8px",
        fontSize: "11px",
        color: "var(--vscode-descriptionForeground)",
      }}
    >
      <span>{results.length} results</span>
      <button
        type="button"
        onClick={onClear}
        style={{
          background: "none",
          border: "none",
          color: "var(--vscode-textLink-foreground)",
          cursor: "pointer",
          fontSize: "11px",
          padding: 0,
        }}
      >
        Clear
      </button>
    </div>
    <vscode-tree>
      {results.map((hit) => (
        <vscode-tree-item key={hit.id} active={hit.id === activePageId || undefined} onClick={() => onNavigate(hit.id)}>
          <vscode-icon slot="icon-leaf" name="file" />
          {hit.title}
          {hit.snippet && <span slot="description">{hit.snippet}</span>}
        </vscode-tree-item>
      ))}
    </vscode-tree>
  </div>
);

// ─── Status message ─────────────────────────────────────

const StatusMsg = ({
  children,
  error: isError,
}: {
  readonly children: React.ReactNode;
  readonly error?: boolean;
}): React.JSX.Element => (
  <div
    style={{
      padding: "8px",
      textAlign: "center",
      fontSize: "12px",
      color: isError ? "var(--vscode-errorForeground)" : "var(--vscode-descriptionForeground)",
    }}
  >
    {children}
  </div>
);
