import { useState, useEffect } from "react";
import { useSearchParams } from "react-router";
import { useApi, useApiMutation } from "../../lib/hooks.ts";
import type { CodeGraph, DigestMatch } from "@indexion/api-client";
import { LoadingSpinner } from "../../components/shared/loading-spinner.tsx";
import { ErrorPanel } from "../../components/shared/error-panel.tsx";
import { ScrollArea } from "../../components/ui/scroll-area.tsx";
import { SearchForm } from "./components/search-form.tsx";
import { SearchResults } from "./components/search-results.tsx";

export const SearchPage = (): React.JSX.Element => {
  const [searchParams, setSearchParams] = useSearchParams();
  const initialQuery = searchParams.get("q") ?? "";
  const [query, setQuery] = useState(initialQuery);
  const [mode, setMode] = useState<"symbol" | "semantic">("symbol");

  const graphState = useApi<CodeGraph>("/graph?format=codegraph");
  const { state: digestState, mutate: digestMutate } = useApiMutation<{ purpose: string; topK?: number }, ReadonlyArray<DigestMatch>>();

  const symbolResults = (() => {
    if (graphState.status !== "success" || !initialQuery) return [];
    const lower = initialQuery.toLowerCase();
    return Object.entries(graphState.data.symbols)
      .filter(([, sym]) => sym.name.toLowerCase().includes(lower) || sym.module.toLowerCase().includes(lower))
      .map(([id, sym]) => ({ id, ...sym }))
      .slice(0, 100);
  })();

  useEffect(() => {
    if (initialQuery && mode === "semantic") {
      digestMutate("/digest/query", { purpose: initialQuery, topK: 20 });
    }
  }, [initialQuery, mode]);

  const handleSubmit = () => {
    if (query.trim()) {
      setSearchParams({ q: query.trim() });
      if (mode === "semantic") {
        digestMutate("/digest/query", { purpose: query.trim(), topK: 20 });
      }
    }
  };

  return (
    <div className="grid h-full grid-rows-[auto_1fr]">
      <SearchForm
        query={query}
        mode={mode}
        onQueryChange={setQuery}
        onModeChange={setMode}
        onSubmit={handleSubmit}
      />

      <ScrollArea className="h-full">
        <div className="p-4">
          {mode === "symbol" && (
            <>
              {(graphState.status === "loading" || graphState.status === "idle") && <LoadingSpinner />}
              {graphState.status === "error" && <ErrorPanel message={graphState.error} />}
              {graphState.status === "success" && initialQuery && (
                <SearchResults symbolResults={symbolResults} digestResults={[]} mode="symbol" query={initialQuery} />
              )}
            </>
          )}
          {mode === "semantic" && (
            <>
              {digestState.status === "loading" && <LoadingSpinner message="Searching by purpose..." />}
              {digestState.status === "error" && <ErrorPanel message={digestState.error} />}
              {digestState.status === "success" && (
                <SearchResults symbolResults={[]} digestResults={[...digestState.data]} mode="semantic" query={initialQuery} />
              )}
            </>
          )}
        </div>
      </ScrollArea>
    </div>
  );
};
