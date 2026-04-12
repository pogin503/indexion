/**
 * @file Similarity matrix visualization component for explore results.
 */

import React from "react";
import styles from "./similarity-matrix.module.css";

type SimilarityPair = {
  readonly file1: string;
  readonly file2: string;
  readonly similarity: number;
};

type SimilarityMatrixProps = {
  readonly files: ReadonlyArray<string>;
  readonly pairs: ReadonlyArray<SimilarityPair>;
  readonly onFileClick?: (filePath: string) => void;
};

/** Extract short filename from full path. */
const shortName = (path: string): string => {
  const parts = path.split("/");
  return parts[parts.length - 1] ?? path;
};

/** Map similarity (0-1) to a CSS background color. */
const cellColor = (similarity: number): string => {
  if (similarity >= 0.9) {
    return "var(--vscode-testing-iconFailed, #f44)";
  }
  if (similarity >= 0.7) {
    return "var(--vscode-editorWarning-foreground, #fa4)";
  }
  if (similarity >= 0.5) {
    return "var(--vscode-editorInfo-foreground, #4af)";
  }
  return "transparent";
};

export const SimilarityMatrix = ({ files, pairs, onFileClick }: SimilarityMatrixProps): React.JSX.Element => {
  const pairMap = new Map<string, number>();
  for (const pair of pairs) {
    pairMap.set(`${pair.file1}|${pair.file2}`, pair.similarity);
    pairMap.set(`${pair.file2}|${pair.file1}`, pair.similarity);
  }

  if (files.length === 0) {
    return <div className={styles.empty}>No files to display</div>;
  }

  if (files.length > 20) {
    return (
      <div className={styles.fallback}>
        <p>{files.length} files — matrix too large, showing top pairs:</p>
        <div className={styles.pairList}>
          {pairs.slice(0, 50).map((pair, i) => (
            <div key={i} className={styles.pairItem}>
              <span className={styles.score}>{Math.round(pair.similarity * 100)}%</span>
              <button className={styles.fileLink} onClick={() => onFileClick?.(pair.file1)} type="button">
                {shortName(pair.file1)}
              </button>
              <span className={styles.arrow}>↔</span>
              <button className={styles.fileLink} onClick={() => onFileClick?.(pair.file2)} type="button">
                {shortName(pair.file2)}
              </button>
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className={styles.container}>
      <table className={styles.table}>
        <thead>
          <tr>
            <th className={styles.cornerCell} />
            {files.map((file) => (
              <th key={file} className={styles.headerCell} title={file}>
                {shortName(file)}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {files.map((rowFile) => (
            <tr key={rowFile}>
              <td className={styles.rowHeader} title={rowFile}>
                {shortName(rowFile)}
              </td>
              {files.map((colFile) => {
                const similarity = rowFile === colFile ? 1.0 : (pairMap.get(`${rowFile}|${colFile}`) ?? 0);
                const percent = Math.round(similarity * 100);
                return (
                  <td
                    key={colFile}
                    className={styles.cell}
                    style={{
                      backgroundColor: similarity > 0 ? cellColor(similarity) : undefined,
                      opacity: similarity > 0 ? 0.3 + similarity * 0.7 : 0.1,
                    }}
                    title={`${shortName(rowFile)} ↔ ${shortName(colFile)}: ${percent}%`}
                  >
                    {similarity > 0 ? `${percent}` : ""}
                  </td>
                );
              })}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};
