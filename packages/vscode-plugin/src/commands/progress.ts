/**
 * @file VSCode progress notification helper.
 */

import * as vscode from "vscode";

/** Run a task with VSCode progress notification. */
export const runWithProgress = <T>(title: string, task: (token: vscode.CancellationToken) => Promise<T>): Thenable<T> =>
  vscode.window.withProgress(
    { location: vscode.ProgressLocation.Notification, title, cancellable: true },
    (_progress, token) => task(token),
  );
