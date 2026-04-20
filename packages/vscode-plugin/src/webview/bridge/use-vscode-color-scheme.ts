/**
 * @file Detect VSCode webview color scheme from document.body classes.
 *
 * VSCode sets `vscode-light`, `vscode-dark`, `vscode-high-contrast`, or
 * `vscode-high-contrast-light` on <body> and updates the class when the user
 * changes theme. This hook subscribes via MutationObserver so components
 * re-render on theme change.
 */

import { useSyncExternalStore } from "react";
import type { ColorScheme } from "@indexion/syntax-highlight";

const readColorScheme = (): ColorScheme => {
  const cls = document.body.classList;
  if (cls.contains("vscode-light") || cls.contains("vscode-high-contrast-light")) {
    return "light";
  }
  return "dark";
};

const subscribe = (onChange: () => void): (() => void) => {
  const observer = new MutationObserver(onChange);
  observer.observe(document.body, { attributes: true, attributeFilter: ["class"] });
  return () => observer.disconnect();
};

const getServerSnapshot = (): ColorScheme => "dark";

export const useVscodeColorScheme = (): ColorScheme =>
  useSyncExternalStore(subscribe, readColorScheme, getServerSnapshot);
