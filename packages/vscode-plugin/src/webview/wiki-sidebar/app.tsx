/**
 * @file Wiki sidebar React application entry point.
 *
 * Renders in the sidebar (activity bar → "Wiki" container) as a filterable
 * list of pages backed by a search API when the filter is non-empty.
 */

import ReactDOM from "react-dom/client";
import "../components/vscode-imports.ts";
import { WebviewProvider } from "../bridge/context.tsx";
import { WikiSidebarApp } from "./app-component.tsx";
import "./wiki-sidebar.css";

const root = document.getElementById("root");
if (root) {
  ReactDOM.createRoot(root).render(
    <WebviewProvider>
      <WikiSidebarApp />
    </WebviewProvider>,
  );
}
