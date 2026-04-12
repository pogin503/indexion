/**
 * @file Wiki page viewer React application entry point.
 *
 * Renders in the editor area as a read-only page viewer.
 */

import ReactDOM from "react-dom/client";
import { WebviewProvider } from "../bridge/context.tsx";
import { WikiViewerApp } from "./app-component.tsx";
import "./markdown.css";

const root = document.getElementById("root");
if (root) {
  ReactDOM.createRoot(root).render(
    <WebviewProvider>
      <WikiViewerApp />
    </WebviewProvider>,
  );
}
