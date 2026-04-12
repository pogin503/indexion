/**
 * @file Wiki sidebar viewer React component.
 *
 * Fits in VSCode sidebar (narrow, vertical layout).
 * Two modes toggled by tabs:
 * - "Nav" — page tree + search
 * - "Page" — selected page content (auto-switches on navigate)
 *
 * ┌─────────────────────┐
 * │ [Nav] [Page]        │  ← tab bar
 * ├─────────────────────┤
 * │ ┌─────────────────┐ │
 * │ │ Search...       │ │  ← search input (nav mode)
 * │ └─────────────────┘ │
 * │ ├─ Overview         │
 * │ ├─ Architecture     │
 * │ │  ├─ Modules       │
 * │ │  └─ Plugins       │
 * │ └─ FAQ              │
 * └─────────────────────┘
 *
 * When a page is selected, switches to Page tab:
 * ┌─────────────────────┐
 * │ [Nav] [Page]        │
 * ├─────────────────────┤
 * │ ← Back to nav       │
 * │ Page Title           │
 * │ ─────────            │
 * │ Contents             │
 * │  ├─ Section 1        │
 * │  └─ Section 2        │
 * │                      │
 * │ Body text...         │
 * │                      │
 * │ Sources              │
 * │  file.ts:10-20       │
 * └─────────────────────┘
 */

import React, { useCallback, useRef, useState } from "react";
import type { WikiPage, WikiNavItem } from "@indexion/api-client";
import type { WikiToWebview, WikiFromWebview, WikiSearchHit } from "../../views/wiki/messages.ts";
import { usePostMessage, useWebviewMessage } from "../bridge/context.tsx";
import { SearchInput } from "../components/search-input.tsx";

// ─── Nav tree item ──────────────────────────────────────

const NavItem = ({
  item,
  activePageId,
  depth,
  onNavigate,
}: {
  readonly item: WikiNavItem;
  readonly activePageId: string | null;
  readonly depth: number;
  readonly onNavigate: (pageId: string) => void;
}): React.JSX.Element => {
  const [expanded, setExpanded] = useState(depth < 1);
  const hasChildren = item.children.length > 0;
  const isActive = item.id === activePageId;

  return (
    <div>
      <button
        type="button"
        onClick={() => {
          onNavigate(item.id);
          if (hasChildren) {
            setExpanded(true);
          }
        }}
        style={{
          ...s.navItem,
          paddingLeft: `${depth * 12 + 6}px`,
          fontWeight: isActive ? 600 : 400,
          background: isActive ? "var(--vscode-list-activeSelectionBackground, #094771)" : "transparent",
          color: isActive ? "var(--vscode-list-activeSelectionForeground, #fff)" : "inherit",
        }}
      >
        {hasChildren && (
          <span
            onClick={(e) => {
              e.stopPropagation();
              setExpanded(!expanded);
            }}
            style={s.chevron}
          >
            {expanded ? "▾" : "▸"}
          </span>
        )}
        {!hasChildren && <span style={s.chevronSpacer} />}
        <span style={s.navLabel}>{item.title}</span>
      </button>
      {expanded &&
        hasChildren &&
        item.children.map((child) => (
          <NavItem key={child.id} item={child} activePageId={activePageId} depth={depth + 1} onNavigate={onNavigate} />
        ))}
    </div>
  );
};

// ─── Main component ─────────────────────────────────────

type Tab = "nav" | "page";

export const WikiPageApp = (): React.JSX.Element => {
  const postMessage = usePostMessage<WikiFromWebview>();
  const [tab, setTab] = useState<Tab>("nav");
  const [nav, setNav] = useState<ReadonlyArray<WikiNavItem>>([]);
  const [page, setPage] = useState<WikiPage | null>(null);
  const [activePageId, setActivePageId] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState("");
  const [searchResults, setSearchResults] = useState<ReadonlyArray<WikiSearchHit> | null>(null);
  const [navLoading, setNavLoading] = useState(true);
  const [pageLoading, setPageLoading] = useState(false);
  const [searchLoading, setSearchLoading] = useState(false);
  const [serverReady, setServerReady] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const contentRef = useRef<HTMLDivElement>(null);

  useWebviewMessage<WikiToWebview>((msg) => {
    if (msg.type === "navLoaded") {
      setNav(msg.nav.pages);
      setNavLoading(false);
    }
    if (msg.type === "pageLoaded") {
      setPage(msg.page);
      setActivePageId(msg.page.id);
      setPageLoading(false);
      setError(null);
      setTab("page");
      contentRef.current?.scrollTo(0, 0);
    }
    if (msg.type === "searchResults") {
      setSearchResults(msg.results);
      setSearchLoading(false);
    }
    if (msg.type === "loading") {
      if (msg.target === "nav") {
        setNavLoading(true);
      }
      if (msg.target === "page") {
        setPageLoading(true);
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
      if (msg.target === "page") {
        setPageLoading(false);
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

  const handleOpenFile = useCallback(
    (filePath: string, line?: number) => {
      postMessage({ type: "openFile", filePath, line });
    },
    [postMessage],
  );

  const clearSearch = useCallback(() => {
    setSearchResults(null);
  }, []);

  const handleClearSearch = useCallback(() => {
    setSearchQuery("");
    setSearchResults(null);
  }, []);

  // ─── Nav sub-views ────────────────────────────────

  const renderSearchResults = (): React.JSX.Element => (
    <div style={s.list}>
      <div style={s.listHeader}>
        <span>{searchResults?.length ?? 0} results</span>
        <button type="button" onClick={handleClearSearch} style={s.linkBtn}>
          Back
        </button>
      </div>
      {searchResults?.map((hit) => (
        <button key={hit.id} type="button" style={s.listItem} onClick={() => handleNavigate(hit.id)}>
          <div>{hit.title}</div>
          {hit.snippet && <div style={s.dimText}>{hit.snippet}</div>}
        </button>
      ))}
    </div>
  );

  const renderNavTree = (): React.JSX.Element => (
    <div style={s.list}>
      {navLoading && <div style={s.status}>Loading...</div>}
      {error && !navLoading && <div style={s.error}>{error}</div>}
      {!navLoading && !error && nav.length === 0 && <div style={s.status}>No wiki pages found</div>}
      {nav.map((item) => (
        <NavItem key={item.id} item={item} activePageId={activePageId} depth={0} onNavigate={handleNavigate} />
      ))}
    </div>
  );

  // ─── Nav tab ──────────────────────────────────────

  const renderNav = (): React.JSX.Element => (
    <div style={s.tabContent}>
      <SearchInput
        value={searchQuery}
        onChange={setSearchQuery}
        onSubmit={(q) => postMessage({ type: "search", query: q })}
        onClear={clearSearch}
        placeholder="Search wiki..."
        disabled={!serverReady}
        loading={searchLoading}
        resultCount={searchResults?.length ?? null}
      />
      {!serverReady && !searchLoading && <div style={s.status}>Server not ready...</div>}
      {searchResults !== null ? renderSearchResults() : renderNavTree()}
    </div>
  );

  // ─── Page tab ─────────────────────────────────────

  const renderPage = (): React.JSX.Element => {
    if (pageLoading) {
      return <div style={s.status}>Loading page...</div>;
    }
    if (error) {
      return <div style={s.error}>{error}</div>;
    }
    if (!page) {
      return <div style={s.status}>Select a page from Nav</div>;
    }

    return (
      <div ref={contentRef} style={s.tabContent}>
        <button type="button" onClick={() => setTab("nav")} style={s.backBtn}>
          &larr; Nav
        </button>

        <h2 style={s.pageTitle}>{page.title}</h2>

        {page.headings.length > 0 && (
          <nav style={s.toc}>
            {page.headings.map((h) => (
              <a
                key={h.anchor}
                href={`#${h.anchor}`}
                style={{ ...s.tocItem, paddingLeft: `${(h.level - 1) * 10 + 4}px` }}
              >
                {h.text}
              </a>
            ))}
          </nav>
        )}

        <div style={s.body}>
          {page.content.split("\n").map((line, i) => (
            <div key={i} style={s.line}>
              {line || "\u00a0"}
            </div>
          ))}
        </div>

        {page.sources.length > 0 && (
          <div style={s.section}>
            <div style={s.sectionLabel}>Sources</div>
            {page.sources.map((src, i) => (
              <button key={i} type="button" style={s.sourceLink} onClick={() => handleOpenFile(src.file, src.lines[0])}>
                {src.file}:{src.lines[0]}-{src.lines[1]}
              </button>
            ))}
          </div>
        )}

        {page.children.length > 0 && (
          <div style={s.section}>
            <div style={s.sectionLabel}>Related</div>
            {page.children.map((childId) => (
              <button key={childId} type="button" style={s.linkBtn} onClick={() => handleNavigate(childId)}>
                {childId}
              </button>
            ))}
          </div>
        )}
      </div>
    );
  };

  // ─── Layout ───────────────────────────────────────

  return (
    <div style={s.container}>
      <div style={s.tabs}>
        <button type="button" onClick={() => setTab("nav")} style={tab === "nav" ? s.tabActive : s.tab}>
          Nav
        </button>
        <button
          type="button"
          onClick={() => setTab("page")}
          style={tab === "page" ? s.tabActive : s.tab}
          disabled={!page}
        >
          Page
        </button>
      </div>
      {tab === "nav" ? renderNav() : renderPage()}
    </div>
  );
};

// ─── Styles ─────────────────────────────────────────

const s: Record<string, React.CSSProperties> = {
  container: {
    display: "flex",
    flexDirection: "column",
    height: "100%",
    fontFamily: "var(--vscode-font-family)",
    color: "var(--vscode-foreground)",
    fontSize: "13px",
    overflow: "hidden",
  },
  tabs: {
    display: "flex",
    borderBottom: "1px solid var(--vscode-panel-border, #333)",
    flexShrink: 0,
  },
  tab: {
    flex: 1,
    padding: "6px 0",
    border: "none",
    background: "transparent",
    color: "var(--vscode-descriptionForeground, #888)",
    cursor: "pointer",
    fontSize: "12px",
    fontFamily: "inherit",
    borderBottom: "2px solid transparent",
  },
  tabActive: {
    flex: 1,
    padding: "6px 0",
    border: "none",
    background: "transparent",
    color: "var(--vscode-foreground)",
    cursor: "pointer",
    fontSize: "12px",
    fontFamily: "inherit",
    fontWeight: 600,
    borderBottom: "2px solid var(--vscode-focusBorder, #007acc)",
  },
  tabContent: {
    flex: 1,
    overflow: "auto",
  },
  status: {
    padding: "12px 6px",
    textAlign: "center" as const,
    color: "var(--vscode-descriptionForeground, #888)",
    fontSize: "12px",
  },
  error: {
    padding: "12px 6px",
    color: "var(--vscode-errorForeground, #f44)",
    fontSize: "12px",
    textAlign: "center" as const,
  },
  list: {
    flex: 1,
    overflow: "auto",
  },
  listHeader: {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    padding: "4px 6px",
    fontSize: "11px",
    color: "var(--vscode-descriptionForeground, #888)",
    borderBottom: "1px solid var(--vscode-panel-border, #333)",
  },
  listItem: {
    display: "block",
    width: "100%",
    textAlign: "left" as const,
    padding: "5px 6px",
    border: "none",
    borderBottom: "1px solid var(--vscode-panel-border, #222)",
    background: "transparent",
    color: "inherit",
    cursor: "pointer",
    fontFamily: "inherit",
    fontSize: "13px",
  },
  dimText: {
    fontSize: "11px",
    color: "var(--vscode-descriptionForeground, #888)",
    overflow: "hidden",
    textOverflow: "ellipsis",
    whiteSpace: "nowrap" as const,
    marginTop: "1px",
  },
  navItem: {
    display: "flex",
    alignItems: "center",
    width: "100%",
    border: "none",
    cursor: "pointer",
    fontFamily: "inherit",
    fontSize: "13px",
    padding: "3px 6px",
    textAlign: "left" as const,
    gap: "2px",
    whiteSpace: "nowrap" as const,
    overflow: "hidden",
  },
  chevron: {
    width: "12px",
    fontSize: "9px",
    textAlign: "center" as const,
    flexShrink: 0,
    cursor: "pointer",
    userSelect: "none" as const,
  },
  chevronSpacer: {
    width: "12px",
    flexShrink: 0,
  },
  navLabel: {
    overflow: "hidden",
    textOverflow: "ellipsis",
  },
  backBtn: {
    background: "none",
    border: "none",
    color: "var(--vscode-textLink-foreground, #007acc)",
    cursor: "pointer",
    fontFamily: "inherit",
    fontSize: "12px",
    padding: "6px 6px 2px",
    textAlign: "left" as const,
  },
  pageTitle: {
    fontSize: "16px",
    fontWeight: 600,
    margin: "4px 6px 10px",
    lineHeight: 1.3,
  },
  toc: {
    padding: "6px",
    margin: "0 6px 10px",
    background: "var(--vscode-textCodeBlock-background, #1e1e1e)",
    borderRadius: "3px",
    border: "1px solid var(--vscode-panel-border, #333)",
  },
  tocItem: {
    display: "block",
    fontSize: "12px",
    padding: "1px 4px",
    color: "var(--vscode-textLink-foreground, #007acc)",
    textDecoration: "none",
  },
  body: {
    whiteSpace: "pre-wrap" as const,
    fontSize: "13px",
    lineHeight: 1.6,
    padding: "0 6px",
    marginBottom: "12px",
  },
  line: {
    minHeight: "1lh",
  },
  section: {
    padding: "8px 6px",
    borderTop: "1px solid var(--vscode-panel-border, #333)",
  },
  sectionLabel: {
    fontWeight: 600,
    fontSize: "11px",
    marginBottom: "4px",
    color: "var(--vscode-descriptionForeground)",
    textTransform: "uppercase" as const,
    letterSpacing: "0.4px",
  },
  sourceLink: {
    display: "block",
    background: "none",
    border: "none",
    padding: "1px 0",
    color: "var(--vscode-textLink-foreground, #007acc)",
    cursor: "pointer",
    fontFamily: "var(--vscode-editor-font-family)",
    fontSize: "11px",
    textAlign: "left" as const,
  },
  linkBtn: {
    background: "none",
    border: "none",
    color: "var(--vscode-textLink-foreground, #007acc)",
    cursor: "pointer",
    fontFamily: "inherit",
    fontSize: "12px",
    padding: "1px 2px",
    textDecoration: "underline",
  },
};
