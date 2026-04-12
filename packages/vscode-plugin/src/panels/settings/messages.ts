/**
 * @file Message types for settings webview communication.
 */

/** Messages from extension host to settings webview. */
export type SettingsToWebview =
  | { readonly type: "configLoaded"; readonly global: SettingsConfig; readonly local: SettingsConfig }
  | { readonly type: "saved"; readonly success: boolean; readonly scope: "global" | "local" };

/** Messages from settings webview to extension host. */
export type SettingsFromWebview =
  | { readonly type: "load" }
  | { readonly type: "save"; readonly scope: "global" | "local"; readonly config: SettingsConfig };

/** Settings config shape exposed to the webview. */
export type SettingsConfig = {
  readonly binaryPath: string;
  readonly specsDir: string;
  readonly defaultThreshold: number;
  readonly defaultStrategy: string;
  readonly includes: ReadonlyArray<string>;
  readonly excludes: ReadonlyArray<string>;
};
