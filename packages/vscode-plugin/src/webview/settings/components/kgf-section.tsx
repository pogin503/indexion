/**
 * @file KGF management section within the settings panel.
 */

import React, { useEffect, useState } from "react";
import { usePostMessage, useWebviewMessage } from "../../bridge/context.tsx";
import styles from "./kgf-section.module.css";

/** KGF spec entry received from the extension host. */
type KgfSpec = {
  readonly name: string;
  readonly category: string;
  readonly sources: ReadonlyArray<string>;
};

/** Messages specific to KGF management. */
type KgfFromWebview =
  | { readonly type: "kgfAdd"; readonly specName: string }
  | { readonly type: "kgfUpdate" }
  | { readonly type: "kgfLoadList" };

type KgfToWebview =
  | { readonly type: "kgfListLoaded"; readonly specs: ReadonlyArray<KgfSpec> }
  | { readonly type: "kgfActionDone"; readonly message: string };

export const KgfSection = (): React.JSX.Element => {
  const postMessage = usePostMessage<KgfFromWebview>();
  const [specs, setSpecs] = useState<ReadonlyArray<KgfSpec>>([]);
  const [addInput, setAddInput] = useState("");
  const [status, setStatus] = useState("");

  useWebviewMessage<KgfToWebview>((message) => {
    if (message.type === "kgfListLoaded") {
      setSpecs(message.specs);
    }
    if (message.type === "kgfActionDone") {
      setStatus(message.message);
      setTimeout(() => setStatus(""), 3000);
      postMessage({ type: "kgfLoadList" });
    }
  });

  useEffect(() => {
    postMessage({ type: "kgfLoadList" });
  }, [postMessage]);

  const handleAdd = (): void => {
    if (addInput.trim()) {
      postMessage({ type: "kgfAdd", specName: addInput.trim() });
      setAddInput("");
    }
  };

  const handleUpdateAll = (): void => {
    postMessage({ type: "kgfUpdate" });
    setStatus("Updating...");
  };

  const grouped = new Map<string, Array<KgfSpec>>();
  for (const spec of specs) {
    const category = spec.category || "other";
    const existing = grouped.get(category) ?? [];
    existing.push(spec);
    grouped.set(category, existing);
  }

  return (
    <div className={styles.section}>
      <h2 className={styles.heading}>KGF Specs</h2>

      {status && <div className={styles.status}>{status}</div>}

      <div className={styles.actions}>
        <div className={styles.addRow}>
          <input
            className={styles.input}
            type="text"
            value={addInput}
            placeholder="spec name (e.g., python)"
            onChange={(e) => setAddInput(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter") {
                handleAdd();
              }
            }}
          />
          <button className={styles.button} onClick={handleAdd} type="button">
            Add
          </button>
        </div>
        <button className={styles.buttonSecondary} onClick={handleUpdateAll} type="button">
          Update All
        </button>
      </div>

      <div className={styles.specList}>
        {[...grouped.entries()].map(([category, categorySpecs]) => (
          <div key={category} className={styles.category}>
            <div className={styles.categoryName}>{category}/</div>
            {categorySpecs.map((spec) => (
              <div key={spec.name} className={styles.specItem}>
                <span className={styles.specName}>{spec.name}</span>
                <span className={styles.specSources}>{spec.sources.join(", ")}</span>
              </div>
            ))}
          </div>
        ))}
        {specs.length === 0 && <div className={styles.empty}>No KGF specs installed</div>}
      </div>
    </div>
  );
};
