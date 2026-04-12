/**
 * @file Configuration section component for the settings panel.
 */

import React from "react";
import type { SettingsConfig } from "../../../panels/settings/messages.ts";
import styles from "./config-section.module.css";

type ConfigSectionProps = {
  readonly config: SettingsConfig;
  readonly onChange: (config: SettingsConfig) => void;
  readonly onSave: (config: SettingsConfig) => void;
};

export const ConfigSection = ({ config, onChange, onSave }: ConfigSectionProps): React.JSX.Element => {
  const handleChange = (key: keyof SettingsConfig, value: string | number): void => {
    onChange({ ...config, [key]: value });
  };

  return (
    <div className={styles.section}>
      <div className={styles.field}>
        <label className={styles.label} htmlFor="binaryPath">
          Binary Path
        </label>
        <input
          id="binaryPath"
          className={styles.input}
          type="text"
          value={config.binaryPath}
          placeholder="auto-detect"
          onChange={(e) => handleChange("binaryPath", e.target.value)}
        />
        <span className={styles.hint}>Leave empty to auto-detect from PATH</span>
      </div>

      <div className={styles.field}>
        <label className={styles.label} htmlFor="specsDir">
          KGF Specs Directory
        </label>
        <input
          id="specsDir"
          className={styles.input}
          type="text"
          value={config.specsDir}
          onChange={(e) => handleChange("specsDir", e.target.value)}
        />
      </div>

      <div className={styles.field}>
        <label className={styles.label} htmlFor="threshold">
          Default Threshold
        </label>
        <input
          id="threshold"
          className={styles.input}
          type="number"
          min="0"
          max="1"
          step="0.05"
          value={config.defaultThreshold}
          onChange={(e) => handleChange("defaultThreshold", Number(e.target.value))}
        />
      </div>

      <div className={styles.field}>
        <label className={styles.label} htmlFor="strategy">
          Default Strategy
        </label>
        <select
          id="strategy"
          className={styles.input}
          value={config.defaultStrategy}
          onChange={(e) => handleChange("defaultStrategy", e.target.value)}
        >
          <option value="tfidf">TF-IDF</option>
          <option value="ncd">NCD</option>
          <option value="hybrid">Hybrid</option>
          <option value="apted">APTED</option>
          <option value="tsed">TSED</option>
        </select>
      </div>

      <button className={styles.saveButton} onClick={() => onSave(config)} type="button">
        Save
      </button>
    </div>
  );
};
