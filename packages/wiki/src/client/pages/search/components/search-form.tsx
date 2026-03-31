import { type FormEvent } from "react";
import { Search as SearchIcon } from "lucide-react";
import { Input } from "../../../components/ui/input.tsx";
import { Button } from "../../../components/ui/button.tsx";

type Props = {
  readonly query: string;
  readonly mode: "symbol" | "semantic";
  readonly onQueryChange: (query: string) => void;
  readonly onModeChange: (mode: "symbol" | "semantic") => void;
  readonly onSubmit: () => void;
};

export const SearchForm = ({ query, mode, onQueryChange, onModeChange, onSubmit }: Props): React.JSX.Element => {
  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    onSubmit();
  };

  return (
    <div className="flex flex-col gap-2 border-b px-4 py-3">
      <form className="flex gap-2" onSubmit={handleSubmit}>
        <div className="relative flex-1">
          <SearchIcon className="absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            className="pl-9"
            placeholder={mode === "symbol" ? "Search symbols by name..." : "Describe what you're looking for..."}
            value={query}
            onChange={(e) => onQueryChange(e.target.value)}
          />
        </div>
        <Button type="submit">Search</Button>
      </form>
      <div className="flex gap-1">
        <Button
          type="button"
          variant={mode === "symbol" ? "secondary" : "ghost"}
          size="sm"
          onClick={() => onModeChange("symbol")}
        >
          Symbol
        </Button>
        <Button
          type="button"
          variant={mode === "semantic" ? "secondary" : "ghost"}
          size="sm"
          onClick={() => onModeChange("semantic")}
        >
          Semantic
        </Button>
      </div>
    </div>
  );
};
