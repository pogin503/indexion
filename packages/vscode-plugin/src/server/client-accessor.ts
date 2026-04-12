/**
 * @file Module-level accessor for the HTTP client.
 *
 * Commands registered as zero-arg handlers cannot receive the client
 * directly. This module stores a getter set during extension activation
 * so that any command can retrieve the current client instance.
 */

import type { HttpClient } from "@indexion/api-client";

/** Module-level state for the client getter. */
const state: { getter: (() => HttpClient | undefined) | undefined } = { getter: undefined };

/** Register the client getter (called once from extension.ts). */
export const setClientGetter = (fn: () => HttpClient | undefined): void => {
  state.getter = fn;
};

/** Retrieve the current HttpClient, or undefined if the server is not ready. */
export const getClient = (): HttpClient | undefined => state.getter?.();
