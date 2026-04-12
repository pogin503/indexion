/**
 * @file Vitest setup for webview component testing.
 *
 * Provides a mock VSCode webview API so React components
 * that call acquireVsCodeApi() can render in happy-dom.
 */

import "@testing-library/jest-dom/vitest";

/** Captured postMessage calls for assertion. */
export const postedMessages: unknown[] = [];

/** Reset captured messages between tests. */
export const resetMessages = (): void => {
  postedMessages.length = 0;
};

const mockVsCodeApi = {
  postMessage: (message: unknown) => {
    postedMessages.push(message);
  },
  getState: () => undefined,
  setState: () => {},
};

// VSCode webview global — acquireVsCodeApi is called once per webview
(globalThis as Record<string, unknown>).acquireVsCodeApi = () => mockVsCodeApi;
