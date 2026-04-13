/**
 * @file Wiki page panel React application entry point.
 */

import "../components/vscode-imports.ts";
import ReactDOM from "react-dom/client";
import { WebviewProvider } from "../bridge/context.tsx";
import { WikiPageApp } from "./app-component.tsx";

const root = document.getElementById("root");
if (root) {
  ReactDOM.createRoot(root).render(
    <WebviewProvider>
      <WikiPageApp />
    </WebviewProvider>,
  );
}
