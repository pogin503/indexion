import { Badge } from "../../../components/ui/badge.tsx";
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "../../../components/ui/card.tsx";
import type { DigestMatch } from "../../../lib/types.ts";

type SymbolResult = {
  readonly id: string;
  readonly name: string;
  readonly kind: string;
  readonly module: string;
  readonly doc?: string;
};

type Props = {
  readonly symbolResults: ReadonlyArray<SymbolResult>;
  readonly digestResults: ReadonlyArray<DigestMatch>;
  readonly mode: "symbol" | "semantic";
  readonly query: string;
};

export const SearchResults = ({ symbolResults, digestResults, mode, query }: Props): React.JSX.Element => {
  if (mode === "symbol") {
    if (symbolResults.length === 0) {
      return <p className="py-8 text-center text-sm text-muted-foreground">No symbols matching &ldquo;{query}&rdquo;</p>;
    }
    return (
      <div className="flex flex-col gap-3">
        <p className="text-sm text-muted-foreground">{symbolResults.length} results</p>
        {symbolResults.map((sym) => (
          <Card key={sym.id}>
            <CardHeader className="p-4 pb-2">
              <div className="flex items-center gap-2">
                <CardTitle className="font-mono text-sm">{sym.name}</CardTitle>
                <Badge variant="secondary">{sym.kind}</Badge>
              </div>
              <CardDescription className="font-mono">{sym.module}</CardDescription>
            </CardHeader>
            {sym.doc && (
              <CardContent className="px-4 pb-4">
                <p className="text-sm text-muted-foreground">{sym.doc.slice(0, 200)}</p>
              </CardContent>
            )}
          </Card>
        ))}
      </div>
    );
  }

  if (digestResults.length === 0) {
    return <p className="py-8 text-center text-sm text-muted-foreground">No semantic matches for &ldquo;{query}&rdquo;</p>;
  }

  return (
    <div className="flex flex-col gap-3">
      <p className="text-sm text-muted-foreground">{digestResults.length} results</p>
      {digestResults.map((match) => (
        <Card key={match.name + match.file}>
          <CardHeader className="p-4 pb-2">
            <div className="flex items-center gap-2">
              <CardTitle className="font-mono text-sm">{match.name}</CardTitle>
              <Badge variant="outline">{Math.round(match.score * 100)}%</Badge>
            </div>
            <CardDescription className="font-mono">{match.file}</CardDescription>
          </CardHeader>
          {match.summary && (
            <CardContent className="px-4 pb-4">
              <p className="text-sm text-muted-foreground">{match.summary}</p>
            </CardContent>
          )}
        </Card>
      ))}
    </div>
  );
};
