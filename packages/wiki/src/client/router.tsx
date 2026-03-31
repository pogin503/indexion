import { lazy, Suspense } from "react";
import { createBrowserRouter } from "react-router";
import { AppLayout } from "./components/layout/app-layout.tsx";
import { ExplorerPage } from "./pages/explorer/explorer-page.tsx";
import { LoadingSpinner } from "./components/shared/loading-spinner.tsx";

const GraphPage = lazy(() =>
  import("./pages/graph/graph-page.tsx").then((m) => ({ default: m.GraphPage })),
);

const WikiPage = lazy(() =>
  import("./pages/wiki/wiki-page.tsx").then((m) => ({ default: m.WikiPage })),
);

const SettingsPage = lazy(() =>
  import("./pages/settings/settings-page.tsx").then((m) => ({ default: m.SettingsPage })),
);

export const router = createBrowserRouter([
  {
    element: <AppLayout />,
    children: [
      { index: true, element: <ExplorerPage /> },
      {
        path: "graph",
        element: (
          <Suspense fallback={<LoadingSpinner message="Loading 3D graph..." />}>
            <GraphPage />
          </Suspense>
        ),
      },
      {
        path: "wiki/*",
        element: (
          <Suspense fallback={<LoadingSpinner message="Loading wiki..." />}>
            <WikiPage />
          </Suspense>
        ),
      },
      {
        path: "settings",
        element: (
          <Suspense fallback={<LoadingSpinner />}>
            <SettingsPage />
          </Suspense>
        ),
      },
    ],
  },
]);
