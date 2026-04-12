/**
 * @file WebviewPanel controller for the settings panel.
 */

import * as vscode from "vscode";
import type { SettingsFromWebview, SettingsToWebview, SettingsConfig } from "./messages.ts";
import { getExtensionSettings } from "../../config/index.ts";
import { buildWebviewHtml } from "../../extension-host/webview-html.ts";

/** Create and manage the settings webview panel. */
export const openSettingsPanel = (context: vscode.ExtensionContext): void => {
  const panel = vscode.window.createWebviewPanel("indexion.settings", "indexion Settings", vscode.ViewColumn.One, {
    enableScripts: true,
    localResourceRoots: [vscode.Uri.joinPath(context.extensionUri, "dist", "webview")],
  });

  const scriptUri = panel.webview.asWebviewUri(
    vscode.Uri.joinPath(context.extensionUri, "dist", "webview", "settings.js"),
  );
  const styleUri = panel.webview.asWebviewUri(
    vscode.Uri.joinPath(context.extensionUri, "dist", "webview", "style.css"),
  );

  panel.webview.html = buildWebviewHtml({ webview: panel.webview, scriptUri, styleUri, title: "indexion Settings" });

  panel.webview.onDidReceiveMessage(
    (message: SettingsFromWebview) => {
      if (message.type === "load") {
        const settings = getExtensionSettings();
        const config: SettingsConfig = {
          binaryPath: settings.binaryPath,
          specsDir: settings.specsDir,
          defaultThreshold: settings.defaultThreshold,
          defaultStrategy: settings.defaultStrategy,
          includes: [],
          excludes: [],
        };
        const response: SettingsToWebview = {
          type: "configLoaded",
          global: config,
          local: config,
        };
        panel.webview.postMessage(response);
      }

      if (message.type === "save") {
        const vscodeConfig = vscode.workspace.getConfiguration("indexion");
        const updatePromises = [
          vscodeConfig.update("binaryPath", message.config.binaryPath, message.scope === "global"),
          vscodeConfig.update("specsDir", message.config.specsDir, message.scope === "global"),
          vscodeConfig.update("defaultThreshold", message.config.defaultThreshold, message.scope === "global"),
          vscodeConfig.update("defaultStrategy", message.config.defaultStrategy, message.scope === "global"),
        ];
        Promise.all(updatePromises).then(
          () => {
            const response: SettingsToWebview = { type: "saved", success: true, scope: message.scope };
            panel.webview.postMessage(response);
          },
          () => {
            const response: SettingsToWebview = { type: "saved", success: false, scope: message.scope };
            panel.webview.postMessage(response);
          },
        );
      }
    },
    undefined,
    context.subscriptions,
  );
};
