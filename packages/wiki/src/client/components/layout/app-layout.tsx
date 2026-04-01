import { useState, useEffect, useCallback } from "react";
import { Header } from "./header.tsx";
import { TooltipProvider } from "../ui/tooltip.tsx";
import { ConnectionGuard } from "../shared/connection-guard.tsx";
import { CommandPalette } from "../command-palette/command-palette.tsx";

export const AppLayout = (): React.JSX.Element => {
  const [paletteOpen, setPaletteOpen] = useState(false);

  const handleKeyDown = useCallback((e: KeyboardEvent) => {
    if ((e.metaKey || e.ctrlKey) && e.key === "k") {
      e.preventDefault();
      setPaletteOpen((prev) => !prev);
    }
  }, []);

  useEffect(() => {
    document.addEventListener("keydown", handleKeyDown);
    return () => document.removeEventListener("keydown", handleKeyDown);
  }, [handleKeyDown]);

  return (
    <TooltipProvider>
      <div className="grid h-full grid-rows-[auto_1fr]">
        <Header onSearchClick={() => setPaletteOpen(true)} />
        <main className="overflow-hidden">
          <ConnectionGuard />
        </main>
      </div>
      <CommandPalette open={paletteOpen} onOpenChange={setPaletteOpen} />
    </TooltipProvider>
  );
};
