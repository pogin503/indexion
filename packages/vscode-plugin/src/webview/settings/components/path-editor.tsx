/**
 * @file Reusable path input component with browse button.
 */

import React from "react";
import styles from "./path-editor.module.css";

type PathEditorProps = {
  readonly label: string;
  readonly value: string;
  readonly placeholder?: string;
  readonly hint?: string;
  readonly onChange: (value: string) => void;
};

export const PathEditor = ({ label, value, placeholder, hint, onChange }: PathEditorProps): React.JSX.Element => (
  <div className={styles.field}>
    <label className={styles.label}>{label}</label>
    <div className={styles.row}>
      <input
        className={styles.input}
        type="text"
        value={value}
        placeholder={placeholder}
        onChange={(e) => onChange(e.target.value)}
      />
    </div>
    {hint && <span className={styles.hint}>{hint}</span>}
  </div>
);
