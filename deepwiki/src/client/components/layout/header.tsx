import { NavLink } from "react-router";
import { RefreshCw } from "lucide-react";
import { useApiMutation } from "../../lib/hooks.ts";
import { Button } from "../ui/button.tsx";
import { Separator } from "../ui/separator.tsx";
import { cn } from "../../lib/utils.ts";

export const Header = (): React.JSX.Element => {
  const { state, mutate } = useApiMutation<Record<string, never>, { rebuilt: boolean; functions: number }>();

  return (
    <header className="flex h-12 shrink-0 items-center gap-4 border-b px-4">
      <span className="font-mono text-sm font-bold tracking-tight">ix</span>

      <Separator orientation="vertical" className="h-5" />

      <nav className="flex items-center gap-1">
        {([
          ["/", "Browse", true],
          ["/graph", "Graph", false],
          ["/search", "Search", false],
          ["/index", "Index", false],
          ["/wiki/overview", "Wiki", false],
        ] as const).map(([to, label, end]) => (
          <NavLink key={to} to={to} end={end}>
            {({ isActive }) => (
              <Button variant={isActive ? "secondary" : "ghost"} size="sm">
                {label}
              </Button>
            )}
          </NavLink>
        ))}
      </nav>

      <div className="ml-auto flex items-center gap-2">
        {state.status === "success" && (
          <span className="text-xs text-muted-foreground">{state.data.functions} functions indexed</span>
        )}
        {state.status === "error" && (
          <span className="text-xs text-destructive">Rebuild failed</span>
        )}
        <Button
          variant="outline"
          size="sm"
          onClick={() => mutate("/digest/rebuild", {})}
          disabled={state.status === "loading"}
        >
          <RefreshCw className={cn("size-3.5", state.status === "loading" && "animate-spin")} />
          Rebuild
        </Button>
      </div>
    </header>
  );
};
