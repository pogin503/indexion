/**
 * @file Summary row shown above a list of results.
 *
 * Renders "<summary text> [Clear]" in a space-between layout.
 * Shared between the Search panel and the Wiki filter.
 */

import React from "react";
import layout from "./sidebar-layout.module.css";

type ResultSummaryProps = {
  readonly children: React.ReactNode;
  readonly onClear?: () => void;
  readonly clearLabel?: string;
};

export const ResultSummary = ({ children, onClear, clearLabel = "Clear" }: ResultSummaryProps): React.JSX.Element => (
  <div className={layout.resultSummarySpaced}>
    <span>{children}</span>
    {onClear && (
      <button type="button" className={layout.textLinkButton} onClick={onClear}>
        {clearLabel}
      </button>
    )}
  </div>
);
