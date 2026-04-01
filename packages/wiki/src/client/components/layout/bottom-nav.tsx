/**
 * @file Bottom tab navigation for mobile — always visible on small screens.
 *
 * Provides direct access to Explorer and Wiki without a hamburger menu.
 */

import { NavLink } from "react-router";
import { Code, BookOpen, Search } from "lucide-react";
import { cn } from "../../lib/utils.ts";

type Props = {
  readonly onSearchClick: () => void;
};

export const BottomNav = ({ onSearchClick }: Props): React.JSX.Element => (
  <nav className="fixed inset-x-0 bottom-0 z-30 flex border-t bg-background md:hidden">
    <NavLink to="/" end className="flex-1">
      {({ isActive }) => (
        <div
          className={cn(
            "flex flex-col items-center gap-0.5 py-2 text-xs",
            isActive ? "text-foreground" : "text-muted-foreground",
          )}
        >
          <Code className="size-5" />
          Explorer
        </div>
      )}
    </NavLink>
    <NavLink to="/wiki/overview" className="flex-1">
      {({ isActive }) => (
        <div
          className={cn(
            "flex flex-col items-center gap-0.5 py-2 text-xs",
            isActive ? "text-foreground" : "text-muted-foreground",
          )}
        >
          <BookOpen className="size-5" />
          Wiki
        </div>
      )}
    </NavLink>
    <button type="button" onClick={onSearchClick} className="flex-1">
      <div className="flex flex-col items-center gap-0.5 py-2 text-xs text-muted-foreground">
        <Search className="size-5" />
        Search
      </div>
    </button>
  </nav>
);
