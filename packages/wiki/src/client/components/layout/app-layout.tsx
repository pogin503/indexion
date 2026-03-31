import { Outlet } from "react-router";
import { Header } from "./header.tsx";
import { TooltipProvider } from "../ui/tooltip.tsx";

export const AppLayout = (): React.JSX.Element => (
  <TooltipProvider>
    <div className="grid h-full grid-rows-[auto_1fr]">
      <Header />
      <main className="overflow-hidden">
        <Outlet />
      </main>
    </div>
  </TooltipProvider>
);
