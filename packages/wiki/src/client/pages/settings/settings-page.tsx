import { useCallback } from "react";
import {
  RefreshCw,
  CheckCircle2,
  Server,
  Database,
  Settings2,
} from "lucide-react";
import { useApiCall, useApiMutationCall } from "../../lib/hooks.ts";
import { client, isStaticMode } from "../../lib/client.ts";
import { invalidateScope } from "../../lib/api-cache.ts";
import {
  fetchConfig,
  fetchDigestStats,
  rebuildDigest,
} from "@indexion/api-client";
import { LoadingSpinner } from "../../components/shared/loading-spinner.tsx";
import { ErrorPanel } from "../../components/shared/error-panel.tsx";
import {
  Card,
  CardHeader,
  CardTitle,
  CardDescription,
  CardContent,
} from "../../components/ui/card.tsx";
import { Button } from "../../components/ui/button.tsx";
import { Badge } from "../../components/ui/badge.tsx";
import { ScrollArea } from "../../components/ui/scroll-area.tsx";
import { cn } from "../../lib/utils.ts";
import { useDict } from "../../i18n/index.ts";

type DigestStats = {
  readonly indexDirectory: string;
  readonly provider: string;
  readonly embeddingDim: number;
  readonly totalSymbols: number;
  readonly totalModules: number;
  readonly totalEdges: number;
};

export const SettingsPage = (): React.JSX.Element => {
  const d = useDict();
  const configState = useApiCall((signal) => fetchConfig(client, signal));
  const statsState = useApiCall((signal) =>
    fetchDigestStats<DigestStats>(client, signal),
  );
  const { state: rebuildState, mutate: rebuildMutate } = useApiMutationCall<{
    rebuilt: boolean;
    functions: number;
  }>();

  const handleRebuild = useCallback(() => {
    rebuildMutate(async () => {
      const result = await rebuildDigest(client);
      if (result.ok) {
        invalidateScope("digest");
      }
      return result;
    });
  }, [rebuildMutate]);

  return (
    <ScrollArea className="h-full">
      <div className="mx-auto max-w-2xl space-y-6 p-6">
        <div className="flex items-center gap-2">
          <Settings2 className="size-5 text-muted-foreground" />
          <h1 className="text-lg font-semibold">{d.settings_heading}</h1>
        </div>

        {/* Server Config */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-sm">
              <Server className="size-4" />
              {d.settings_server_config}
            </CardTitle>
          </CardHeader>
          <CardContent>
            {configState.status === "loading" && <LoadingSpinner />}
            {configState.status === "error" && (
              <ErrorPanel message={configState.error} />
            )}
            {configState.status === "success" && (
              <dl className="space-y-2 text-sm">
                {Object.entries(configState.data)
                  .filter(([key]) => key !== "branding")
                  .map(([key, value]) => (
                    <div key={key} className="flex items-baseline gap-2">
                      <dt className="min-w-32 text-muted-foreground">{key}</dt>
                      <dd className="break-all font-mono text-xs">
                        {String(value ?? "\u2014")}
                      </dd>
                    </div>
                  ))}
              </dl>
            )}
          </CardContent>
        </Card>

        {/* Digest Stats */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-sm">
              <Database className="size-4" />
              {d.settings_index_stats}
            </CardTitle>
          </CardHeader>
          <CardContent>
            {statsState.status === "loading" && <LoadingSpinner />}
            {statsState.status === "error" && (
              <ErrorPanel message={statsState.error} />
            )}
            {statsState.status === "success" && (
              <div className="space-y-3">
                <div className="flex flex-wrap gap-2">
                  <Badge variant="outline">
                    {d.settings_symbols(statsState.data.totalSymbols)}
                  </Badge>
                  <Badge variant="outline">
                    {d.settings_modules(statsState.data.totalModules)}
                  </Badge>
                  <Badge variant="outline">
                    {d.settings_edges(statsState.data.totalEdges)}
                  </Badge>
                </div>
                <dl className="space-y-2 text-sm">
                  <div className="flex items-baseline gap-2">
                    <dt className="min-w-32 text-muted-foreground">
                      {d.settings_provider}
                    </dt>
                    <dd className="font-mono text-xs">
                      {statsState.data.provider}
                    </dd>
                  </div>
                  <div className="flex items-baseline gap-2">
                    <dt className="min-w-32 text-muted-foreground">
                      {d.settings_dim}
                    </dt>
                    <dd className="font-mono text-xs">
                      {statsState.data.embeddingDim}
                    </dd>
                  </div>
                  <div className="flex items-baseline gap-2">
                    <dt className="min-w-32 text-muted-foreground">
                      {d.settings_index_dir}
                    </dt>
                    <dd className="break-all font-mono text-xs">
                      {statsState.data.indexDirectory}
                    </dd>
                  </div>
                </dl>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Rebuild — hidden in static mode */}
        {!isStaticMode && (
          <Card>
            <CardHeader>
              <CardTitle className="text-sm">
                {d.settings_rebuild_title}
              </CardTitle>
              <CardDescription>{d.settings_rebuild_desc}</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="flex items-center gap-3">
                <Button
                  onClick={handleRebuild}
                  disabled={rebuildState.status === "loading"}
                >
                  <RefreshCw
                    className={cn(
                      "size-3.5",
                      rebuildState.status === "loading" && "animate-spin",
                    )}
                  />
                  {rebuildState.status === "loading"
                    ? d.settings_rebuilding
                    : d.settings_rebuild_button}
                </Button>
                {rebuildState.status === "success" && (
                  <span className="flex items-center gap-1 text-sm text-green-400">
                    <CheckCircle2 className="size-3.5" />
                    {d.settings_rebuild_done(rebuildState.data.functions)}
                  </span>
                )}
                {rebuildState.status === "error" && (
                  <span className="text-sm text-destructive">
                    {rebuildState.error}
                  </span>
                )}
              </div>
            </CardContent>
          </Card>
        )}
      </div>
    </ScrollArea>
  );
};
