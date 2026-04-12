/**
 * @file Plan execution history backed by globalState.
 *
 * Stores up to MAX_ENTRIES_PER_TYPE history entries per plan type.
 * Each entry records the plan type, timestamp, and a title snippet.
 */

import type * as vscode from "vscode";

const STORAGE_KEY = "indexion.planHistory";
const MAX_ENTRIES_PER_TYPE = 20;

/** A single plan execution record. */
export type PlanHistoryEntry = {
  readonly planType: string;
  readonly timestamp: number;
  readonly title: string;
};

/** Read all history entries from globalState. */
export const getHistory = (state: vscode.Memento): ReadonlyArray<PlanHistoryEntry> =>
  state.get<ReadonlyArray<PlanHistoryEntry>>(STORAGE_KEY, []);

/** Get history entries for a specific plan type. */
export const getHistoryForType = (state: vscode.Memento, planType: string): ReadonlyArray<PlanHistoryEntry> =>
  getHistory(state).filter((e) => e.planType === planType);

/** Add a history entry, enforcing the per-type cap. */
export const addHistoryEntry = async (state: vscode.Memento, entry: PlanHistoryEntry): Promise<void> => {
  const all = [...getHistory(state)];
  all.unshift(entry);

  // Enforce per-type cap
  const counts = new Map<string, number>();
  const filtered = all.filter((e) => {
    const count = counts.get(e.planType) ?? 0;
    if (count >= MAX_ENTRIES_PER_TYPE) {
      return false;
    }
    counts.set(e.planType, count + 1);
    return true;
  });

  await state.update(STORAGE_KEY, filtered);
};

/** Clear all history. */
export const clearHistory = async (state: vscode.Memento): Promise<void> => {
  await state.update(STORAGE_KEY, []);
};

/** Clear history for a specific plan type. */
export const clearHistoryForType = async (state: vscode.Memento, planType: string): Promise<void> => {
  const filtered = getHistory(state).filter((e) => e.planType !== planType);
  await state.update(STORAGE_KEY, filtered);
};
