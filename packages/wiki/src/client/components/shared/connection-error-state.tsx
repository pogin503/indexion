import { WifiOff, RefreshCw } from "lucide-react";
import { Button } from "../ui/button.tsx";
import { useDict } from "../../i18n/index.ts";

type Props = {
  readonly onRetry: () => void;
  readonly retrying: boolean;
};

export const ConnectionErrorState = ({
  onRetry,
  retrying,
}: Props): React.JSX.Element => {
  const d = useDict();
  return (
    <div className="flex h-full flex-col items-center justify-center gap-6 p-8">
      <div className="rounded-full bg-destructive/10 p-4">
        <WifiOff className="size-8 text-destructive" />
      </div>
      <div className="flex flex-col items-center gap-2 text-center">
        <h2 className="text-lg font-semibold">{d.error_connect_heading}</h2>
        <p className="max-w-sm text-sm text-muted-foreground">
          {d.error_connect_message}
          <code className="rounded bg-muted px-1 py-0.5 text-xs">
            {d.error_connect_hint}
          </code>
        </p>
      </div>
      <Button variant="outline" onClick={onRetry} disabled={retrying}>
        <RefreshCw className={`size-3.5 ${retrying ? "animate-spin" : ""}`} />
        {d.error_retry}
      </Button>
    </div>
  );
};
