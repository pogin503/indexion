import { lazy, Suspense } from "react";
import { createBrowserRouter } from "react-router";
import { AppLayout } from "./components/layout/app-layout.tsx";
import { BrowsePage } from "./pages/browse/browse-page.tsx";
import { SearchPage } from "./pages/search/search-page.tsx";
import { IndexPage } from "./pages/index/index-page.tsx";
import { LoadingSpinner } from "./components/shared/loading-spinner.tsx";

const GraphPage = lazy(() =>
  import("./pages/graph/graph-page.tsx").then((m) => ({ default: m.GraphPage })),
);

export const router = createBrowserRouter([
  {
    element: <AppLayout />,
    children: [
      { index: true, element: <BrowsePage /> },
      {
        path: "graph",
        element: (
          <Suspense fallback={<LoadingSpinner message="Loading 3D graph..." />}>
            <GraphPage />
          </Suspense>
        ),
      },
      { path: "search", element: <SearchPage /> },
      { path: "index", element: <IndexPage /> },
    ],
  },
]);
