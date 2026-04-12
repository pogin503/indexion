import { TreesIcon, TableIcon, GitFork, Box } from "lucide-react";
import { Link } from "react-router";
import { Input } from "../../components/ui/input.tsx";
import { Button } from "../../components/ui/button.tsx";
import {
  Tooltip,
  TooltipTrigger,
  TooltipContent,
} from "../../components/ui/tooltip.tsx";
import { useDict } from "../../i18n/index.ts";

export type ExplorerView = "tree" | "table" | "graph";

type Props = {
  readonly view: ExplorerView;
  readonly onViewChange: (v: ExplorerView) => void;
  readonly filter: string;
  readonly onFilterChange: (f: string) => void;
  readonly stats: { roots: number; files: number; symbols: number };
};

export const ExplorerToolbar = ({
  view,
  onViewChange,
  filter,
  onFilterChange,
  stats,
}: Props): React.JSX.Element => {
  const d = useDict();

  const VIEW_OPTIONS: ReadonlyArray<{
    value: ExplorerView;
    icon: typeof TreesIcon;
    label: string;
  }> = [
    { value: "tree", icon: TreesIcon, label: d.explorer_view_tree },
    { value: "table", icon: TableIcon, label: d.explorer_view_table },
    { value: "graph", icon: GitFork, label: d.explorer_view_2d },
  ];

  return (
    <div className="flex flex-wrap items-center gap-3 border-b px-4 py-2">
      <span className="text-sm text-muted-foreground">
        {stats.roots} {d.explorer_stat_roots} &middot; {stats.files}{" "}
        {d.explorer_stat_files} &middot; {stats.symbols}{" "}
        {d.explorer_stat_symbols}
      </span>

      <div className="ml-auto flex items-center gap-2">
        <Input
          className="w-full max-w-48"
          placeholder={d.explorer_filter_placeholder}
          value={filter}
          onChange={(e) => onFilterChange(e.target.value)}
        />

        <div className="flex items-center rounded-md border">
          {VIEW_OPTIONS.map(({ value, icon: Icon, label }) => (
            <Tooltip key={value}>
              <TooltipTrigger asChild>
                <button
                  type="button"
                  onClick={() => onViewChange(value)}
                  className={`px-2 py-1.5 ${view === value ? "bg-accent text-accent-foreground" : "text-muted-foreground hover:text-foreground"}`}
                >
                  <Icon className="size-3.5" />
                </button>
              </TooltipTrigger>
              <TooltipContent>{label}</TooltipContent>
            </Tooltip>
          ))}
        </div>

        <Tooltip>
          <TooltipTrigger asChild>
            <Link to="/graph">
              <Button variant="ghost" size="sm">
                <Box className="size-3.5" />
              </Button>
            </Link>
          </TooltipTrigger>
          <TooltipContent>{d.explorer_view_3d}</TooltipContent>
        </Tooltip>
      </div>
    </div>
  );
};
