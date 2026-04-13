/**
 * @file Inline status message for sidebar panels.
 *
 * Shared across explore, search, and wiki-page.
 */

import React from "react";
import styles from "./status-msg.module.css";

type StatusMsgProps = {
  readonly children: React.ReactNode;
  readonly error?: boolean;
};

export const StatusMsg = ({ children, error: isError }: StatusMsgProps): React.JSX.Element => (
  <div className={`${styles.statusMsg} ${isError ? styles.error : ""}`}>{children}</div>
);
