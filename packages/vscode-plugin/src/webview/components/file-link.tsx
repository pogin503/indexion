/**
 * @file Clickable file path link rendered as an underlined button.
 *
 * Shared across plan-results, similarity-matrix, and refactor-checklist.
 */

import React from "react";
import styles from "./file-link.module.css";

type FileLinkProps = {
  readonly filePath: string;
  readonly label?: string;
  readonly onClick: (filePath: string) => void;
};

export const FileLink = ({ filePath, label, onClick }: FileLinkProps): React.JSX.Element => (
  <button className={styles.fileLink} onClick={() => onClick(filePath)} type="button">
    {label ?? filePath}
  </button>
);
