import { Database, RefreshCw, CheckCircle2 } from "lucide-react";
import { Button } from "../ui/button.tsx";
import { useDict } from "../../i18n/index.ts";

type Props = {
  readonly onBuild: () => void;
  readonly building: boolean;
  readonly built: boolean;
  readonly functionCount: number;
};

export const OnboardingState = ({
  onBuild,
  building,
  built,
  functionCount,
}: Props): React.JSX.Element => {
  const d = useDict();
  return (
    <div className="flex h-full flex-col items-center justify-center gap-6 p-8">
      <div className="rounded-full bg-accent p-4">
        {built ? (
          <CheckCircle2 className="size-8 text-green-400" />
        ) : (
          <Database className="size-8 text-muted-foreground" />
        )}
      </div>
      <div className="flex flex-col items-center gap-2 text-center">
        <h2 className="text-lg font-semibold">
          {built ? d.onboarding_success : d.onboarding_welcome}
        </h2>
        <p className="max-w-md text-sm text-muted-foreground">
          {built
            ? d.onboarding_success_message(functionCount)
            : d.onboarding_no_index}
        </p>
      </div>
      {!built && (
        <Button onClick={onBuild} disabled={building}>
          <RefreshCw
            className={`size-3.5 ${building ? "animate-spin" : ""}`}
          />
          {building ? d.onboarding_building : d.onboarding_build_button}
        </Button>
      )}
    </div>
  );
};
