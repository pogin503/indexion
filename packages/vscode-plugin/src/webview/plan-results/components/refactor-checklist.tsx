/**
 * @file Interactive refactoring checklist component for plan results.
 */

import React, { useState } from "react";
import { FileLink } from "../../components/file-link.tsx";
import layout from "../../components/sidebar-layout.module.css";
import styles from "./refactor-checklist.module.css";

/** A single refactoring item parsed from plan output. */
type RefactorItem = {
  readonly id: string;
  readonly text: string;
  readonly files: ReadonlyArray<string>;
  readonly severity: "high" | "medium" | "low";
};

type RefactorChecklistProps = {
  readonly items: ReadonlyArray<RefactorItem>;
  readonly onFileClick?: (filePath: string) => void;
};

/** Severity badge color. */
const severityColor = (severity: RefactorItem["severity"]): string => {
  const colors: Record<string, string> = {
    high: "var(--vscode-testing-iconFailed, #f44)",
    medium: "var(--vscode-editorWarning-foreground, #fa4)",
    low: "var(--vscode-editorInfo-foreground, #4af)",
  };
  return colors[severity] ?? colors["low"];
};

export const RefactorChecklist = ({ items, onFileClick }: RefactorChecklistProps): React.JSX.Element => {
  const [checked, setChecked] = useState<ReadonlyArray<string>>([]);

  const toggleItem = (id: string): void => {
    const current = [...checked];
    const index = current.indexOf(id);
    if (index >= 0) {
      current.splice(index, 1);
    } else {
      current.push(id);
    }
    setChecked(current);
  };

  const completedCount = checked.length;
  const totalCount = items.length;

  if (items.length === 0) {
    return <div className={styles.empty}>No refactoring items found</div>;
  }

  return (
    <div className={styles.container}>
      <div className={styles.progress}>
        <vscode-progress-bar value={completedCount} max={totalCount} className={layout.flexFill} />
        <span className={styles.progressText}>
          {completedCount}/{totalCount} completed
        </span>
      </div>

      <div className={styles.list}>
        {items.map((item) => {
          const isChecked = checked.includes(item.id);
          return (
            <div key={item.id} className={`${styles.item} ${isChecked ? styles.itemChecked : ""}`}>
              <div className={styles.checkboxRow}>
                <vscode-checkbox checked={isChecked || undefined} onChange={() => toggleItem(item.id)} />
                <span className={styles.severity} style={{ color: severityColor(item.severity) }}>
                  [{item.severity}]
                </span>
                <span className={isChecked ? styles.textChecked : styles.text}>{item.text}</span>
              </div>
              {item.files.length > 0 && (
                <div className={styles.files}>
                  {item.files.map((file) => (
                    <FileLink key={file} filePath={file} onClick={(f) => onFileClick?.(f)} />
                  ))}
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
};
