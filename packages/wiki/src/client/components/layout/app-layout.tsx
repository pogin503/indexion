import { useState, useEffect, useCallback, useMemo } from "react";
import { fetchConfig } from "@indexion/api-client";
import type { Branding } from "@indexion/api-client";
import { Header } from "./header.tsx";
import { TooltipProvider } from "../ui/tooltip.tsx";
import { ConnectionGuard } from "../shared/connection-guard.tsx";
import { CommandPalette } from "../command-palette/command-palette.tsx";
import { client, isStaticMode } from "../../lib/client.ts";
import { BrandingProvider } from "../../lib/branding-context.tsx";
import { DictContext, resolveDict } from "../../i18n/index.ts";

export const AppLayout = (): React.JSX.Element => {
  const [paletteOpen, setPaletteOpen] = useState(false);
  const [branding, setBranding] = useState<Branding | null>(null);

  // Fetch branding from /api/config (fire-and-forget; UI works without it)
  useEffect(() => {
    fetchConfig(client).then((res) => {
      if (res.ok) {
        setBranding(res.data.branding);
      }
    });
  }, []);

  const dict = useMemo(
    () => resolveDict(branding?.locale),
    [branding?.locale],
  );

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
    <DictContext value={dict}>
      <BrandingProvider branding={isStaticMode ? branding : branding}>
        <TooltipProvider>
          <Header onSearchClick={() => setPaletteOpen(true)} />
          <ConnectionGuard />
          <CommandPalette open={paletteOpen} onOpenChange={setPaletteOpen} />
        </TooltipProvider>
      </BrandingProvider>
    </DictContext>
  );
};
