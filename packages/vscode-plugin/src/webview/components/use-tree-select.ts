/**
 * @file Hook for subscribing to `vsc-tree-select` events on a <vscode-tree>.
 *
 * vscode-tree-item internally stops click propagation, so React onClick
 * never fires. The correct API is the custom `vsc-tree-select` event on
 * the parent <vscode-tree>, whose detail is the selected items.
 *
 * This hook returns a ref to attach to the <vscode-tree> element and
 * invokes `onSelect` with the selected element's dataset whenever a row
 * is activated.
 */

import { useEffect, useRef } from "react";

/** Minimal readonly view of HTMLElement.dataset as a plain record. */
export type SelectedDataset = Readonly<Record<string, string | undefined>>;

export const useTreeSelect = (
  onSelect: (data: SelectedDataset) => void,
  deps: ReadonlyArray<unknown> = [],
): React.RefCallback<HTMLElement> => {
  const onSelectRef = useRef(onSelect);
  onSelectRef.current = onSelect;

  const elRef = useRef<HTMLElement | null>(null);

  useEffect(() => {
    const el = elRef.current;
    if (!el) {
      return;
    }
    const handler = (e: Event): void => {
      const detail = (e as CustomEvent).detail as ReadonlyArray<HTMLElement> | undefined;
      if (!detail || detail.length === 0) {
        return;
      }
      const selected = detail[0];
      const data: Record<string, string | undefined> = {};
      for (const key of Object.keys(selected.dataset)) {
        data[key] = selected.dataset[key];
      }
      onSelectRef.current(data);
    };
    el.addEventListener("vsc-tree-select", handler);
    return () => {
      el.removeEventListener("vsc-tree-select", handler);
    };
    // deps are passed through so callers can re-subscribe when their tree re-mounts.
  }, deps);

  return (el) => {
    elRef.current = el;
  };
};
