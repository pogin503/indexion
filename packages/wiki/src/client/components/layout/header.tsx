import { NavLink } from "react-router";
import { Search, Settings, Sun, Moon, Monitor } from "lucide-react";
import { Button } from "../ui/button.tsx";
import { Tooltip, TooltipTrigger, TooltipContent } from "../ui/tooltip.tsx";
import { Logo } from "../shared/logo.tsx";
import { isStaticMode } from "../../lib/client.ts";
import { useDict } from "../../i18n/index.ts";
import {
  useBranding,
  type ColorSchemePreference,
} from "../../lib/branding-context.tsx";

type Props = {
  readonly onSearchClick: () => void;
};

const SCHEME_CYCLE: readonly ColorSchemePreference[] = [
  "dark",
  "light",
  "system",
];

export const Header = ({ onSearchClick }: Props): React.JSX.Element => {
  const d = useDict();
  const { title, colorSchemePreference, setColorSchemePreference } =
    useBranding();

  const cycleScheme = () => {
    const idx = SCHEME_CYCLE.indexOf(colorSchemePreference);
    const next = SCHEME_CYCLE[(idx + 1) % SCHEME_CYCLE.length]!;
    setColorSchemePreference(next);
  };

  const schemeIcon =
    colorSchemePreference === "dark" ? (
      <Moon className="size-4" />
    ) : colorSchemePreference === "light" ? (
      <Sun className="size-4" />
    ) : (
      <Monitor className="size-4" />
    );

  const schemeLabel =
    colorSchemePreference === "dark"
      ? d.color_scheme_dark
      : colorSchemePreference === "light"
        ? d.color_scheme_light
        : d.color_scheme_system;

  const NAV_ITEMS = [
    ["/", d.nav_explorer, true],
    ["/wiki/overview", d.nav_wiki, false],
  ] as const;

  return (
    <header className="sticky top-0 z-40 border-b bg-background">
      <div className="flex h-12 items-center gap-2 px-3 sm:gap-4 sm:px-4">
        <NavLink to="/" className="flex shrink-0 items-center gap-2">
          <Logo className="h-5 sm:h-6" />
          {title && (
            <span className="hidden text-sm font-semibold sm:inline">
              {title}
            </span>
          )}
        </NavLink>

        {/* Nav tabs */}
        <nav className="flex items-center gap-0.5 sm:gap-1">
          {NAV_ITEMS.map(([to, label, end]) => (
            <NavLink key={to} to={to} end={end}>
              {({ isActive }) => (
                <Button variant={isActive ? "secondary" : "ghost"} size="sm">
                  {label}
                </Button>
              )}
            </NavLink>
          ))}
        </nav>

        <div className="ml-auto flex items-center gap-1 sm:gap-2">
          <Tooltip>
            <TooltipTrigger asChild>
              <Button variant="ghost" size="sm" onClick={onSearchClick}>
                <Search className="size-4" />
                <span className="hidden text-xs text-muted-foreground sm:inline ml-1">
                  {d.nav_search_shortcut}
                </span>
              </Button>
            </TooltipTrigger>
            <TooltipContent>
              {d.nav_search_tooltip} ({d.nav_search_shortcut})
            </TooltipContent>
          </Tooltip>

          <Tooltip>
            <TooltipTrigger asChild>
              <Button variant="ghost" size="sm" onClick={cycleScheme}>
                {schemeIcon}
              </Button>
            </TooltipTrigger>
            <TooltipContent>{schemeLabel}</TooltipContent>
          </Tooltip>

          {!isStaticMode && (
            <Tooltip>
              <TooltipTrigger asChild>
                <NavLink to="/settings">
                  {({ isActive }) => (
                    <Button
                      variant={isActive ? "secondary" : "ghost"}
                      size="sm"
                    >
                      <Settings className="size-4" />
                    </Button>
                  )}
                </NavLink>
              </TooltipTrigger>
              <TooltipContent>{d.nav_settings}</TooltipContent>
            </Tooltip>
          )}
        </div>
      </div>
    </header>
  );
};
